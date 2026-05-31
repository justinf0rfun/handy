import { mkdir, writeFile, rm } from "node:fs/promises";
import { spawn } from "node:child_process";
import { chromium } from "playwright";

const url = process.env.HANDY_URL || "http://127.0.0.1:5173/";
const outDir = process.env.OUT_DIR || "reference-pack/2026-05-31";
const chromePath =
  process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

let server;

async function waitForServer(targetUrl) {
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(targetUrl);
      if (response.ok) return true;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
  }
  return false;
}

async function ensureServer() {
  if (await waitForServer(url)) return;

  const parsed = new URL(url);
  server = spawn("npm", ["run", "dev", "--", "--port", parsed.port || "5173"], {
    stdio: "inherit",
    shell: true
  });

  if (!(await waitForServer(url))) {
    throw new Error(`Timed out waiting for ${url}`);
  }
}

async function settled(page, ms = 900) {
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(ms);
}

async function createPage(browser, viewport, options = {}) {
  const context = await browser.newContext({
    viewport,
    deviceScaleFactor: 1,
    recordVideo: options.recordVideo ? { dir: `${outDir}/.video`, size: viewport } : undefined
  });
  const page = await context.newPage();
  await page.goto(url);
  await settled(page);
  return { context, page };
}

async function screenshot(page, name) {
  await page.screenshot({ path: `${outDir}/${name}`, fullPage: false });
}

async function count(locator, label) {
  const total = await locator.count();
  if (total !== 1) throw new Error(`${label} expected 1 match, got ${total}`);
}

async function captureDefaultViewports(browser) {
  for (const [width, height] of [
    [960, 720],
    [1280, 800],
    [1512, 982]
  ]) {
    const { context, page } = await createPage(browser, { width, height });
    await screenshot(page, `prototype-${width}x${height}.png`);
    await context.close();
  }
}

async function captureInteractionStates(browser) {
  const { context, page } = await createPage(browser, { width: 1280, height: 800 });

  await page.mouse.move(250, 500);
  await page.waitForTimeout(220);
  await screenshot(page, "prototype-hover-card.png");

  const firstCard = page.locator('[data-card="ctx-clip-error"]');
  await count(firstCard, "first card");
  await firstCard.click();
  await page.waitForTimeout(520);
  await screenshot(page, "prototype-selection-tray.png");

  await page.evaluate(() => {
    const rail = document.querySelector("[data-gallery]");
    if (rail) rail.scrollLeft = 430;
    rail?.dispatchEvent(new Event("scroll", { bubbles: true }));
  });
  await page.waitForTimeout(260);
  await screenshot(page, "prototype-horizontal-scroll.png");

  await context.close();
}

async function capturePeekAndDraft(browser) {
  const { context, page } = await createPage(browser, { width: 1280, height: 800 });

  const peek = page.locator('[data-card="ctx-code-position"] [data-card-action="peek"]');
  await count(peek, "positioning card peek action");
  await peek.click({ force: true });
  await page.waitForTimeout(380);
  await screenshot(page, "prototype-peek-preview.png");

  await page.keyboard.press("Escape");
  await page.waitForTimeout(120);

  const compose = page.locator("[data-compose]");
  await count(compose, "compose button");
  await compose.click();
  await page.waitForTimeout(420);
  await screenshot(page, "prototype-draft-ready.png");

  const copy = page.locator("[data-draft-copy]");
  await count(copy, "draft copy button");
  await copy.click();
  await page.waitForTimeout(280);
  await screenshot(page, "prototype-draft-copy.png");

  await context.close();
}

async function captureSearchStates(browser) {
  const { context, page } = await createPage(browser, { width: 1280, height: 800 });

  const search = page.locator("[data-search]");
  await count(search, "search input");
  await search.fill("gsap");
  await page.waitForTimeout(420);
  await screenshot(page, "prototype-filtering-state.png");

  await search.fill("zzzz-no-match");
  await page.waitForTimeout(420);
  await screenshot(page, "prototype-empty-state.png");

  await context.close();
}

async function captureEdgeStates(browser) {
  const states = [
    ["top-left", "nw"],
    ["top-right", "ne"],
    ["bottom-left", "sw"],
    ["bottom-right", "se"]
  ];

  for (const [name, hotspot] of states) {
    const { context, page } = await createPage(browser, { width: 1280, height: 800 });
    const target = page.locator(`[data-hotspot="${hotspot}"]`);
    await count(target, `edge hotspot ${hotspot}`);
    await target.click({ force: true });
    await page.waitForTimeout(520);
    await screenshot(page, `prototype-edge-${name}.png`);
    await context.close();
  }
}

async function captureMeasurements(browser) {
  const { context, page } = await createPage(browser, { width: 1280, height: 800 });

  const measurements = await page.evaluate(() => {
    function elementSnapshot(selector) {
      const el = document.querySelector(selector);
      if (!el) return null;
      const rect = el.getBoundingClientRect();
      const computed = getComputedStyle(el);
      return {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
        display: computed.display,
        gap: computed.gap,
        padding: computed.padding,
        borderRadius: computed.borderRadius,
        fontFamily: computed.fontFamily,
        fontSize: computed.fontSize,
        lineHeight: computed.lineHeight,
        fontWeight: computed.fontWeight,
        letterSpacing: computed.letterSpacing,
        color: computed.color,
        backgroundColor: computed.backgroundColor,
        border: computed.border,
        opacity: computed.opacity,
        zIndex: computed.zIndex
      };
    }

    const selectors = {
      panel: ".handy-panel",
      shell: ".panel-shell",
      header: ".panel-header",
      eyebrow: ".eyebrow",
      title: ".panel-header h1",
      attentionCopy: ".attention-copy",
      close: ".icon-button",
      search: ".search-row",
      pills: ".pill-row",
      activePill: ".pill.is-active",
      goal: ".goal-row",
      galleryWrap: ".gallery-wrap",
      rail: ".context-rail",
      firstCard: ".context-card",
      activeCard: ".context-card.is-active",
      selectedCard: ".context-card.is-selected",
      cardMedia: ".context-card .card-media",
      cardToolbar: ".context-card .card-toolbar",
      footer: ".compose-row",
      selectedTray: ".selected-tray",
      selectedChip: ".selected-stack button",
      intentPicker: ".intent-picker",
      intentSelect: ".intent-picker select",
      composeButton: ".compose-button",
      attentionPin: ".attention-pin",
      anchorBeam: ".anchor-beam"
    };
    const elements = {};
    for (const [key, selector] of Object.entries(selectors)) {
      elements[key] = elementSnapshot(selector);
    }

    const panel = document.querySelector(".handy-panel");
    const shell = document.querySelector(".panel-shell");
    const rail = document.querySelector(".context-rail");

    return {
      viewport: { width: window.innerWidth, height: window.innerHeight, deviceScaleFactor: window.devicePixelRatio },
      capturedAt: new Date().toISOString(),
      url: window.location.href,
      cssVars: panel
        ? {
            left: getComputedStyle(panel).left,
            top: getComputedStyle(panel).top,
            transformOrigin: getComputedStyle(panel).transformOrigin
          }
        : null,
      shellVars: shell
        ? {
            spotX: getComputedStyle(shell).getPropertyValue("--spot-x").trim(),
            spotY: getComputedStyle(shell).getPropertyValue("--spot-y").trim()
          }
        : null,
      rail: rail
        ? {
            scrollWidth: rail.scrollWidth,
            clientWidth: rail.clientWidth,
            scrollLeft: rail.scrollLeft
          }
        : null,
      elements
    };
  });

  await writeFile(`${outDir}/computed-measurements-1280x800.json`, JSON.stringify(measurements, null, 2));

  const fonts = await page.evaluate(() => {
    function elementSnapshot(selector) {
      const el = document.querySelector(selector);
      if (!el) return null;
      const rect = el.getBoundingClientRect();
      const computed = getComputedStyle(el);
      return {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
        fontFamily: computed.fontFamily,
        fontSize: computed.fontSize,
        lineHeight: computed.lineHeight,
        fontWeight: computed.fontWeight,
        letterSpacing: computed.letterSpacing
      };
    }

    return [
      "body",
      ".eyebrow",
      ".panel-header h1",
      ".attention-copy",
      ".search-row input",
      ".card-body h2",
      ".card-body p",
      ".card-media pre",
      ".compose-button"
    ].map((selector) => ({
      selector,
      snapshot: elementSnapshot(selector)
    }));
  });

  await writeFile(`${outDir}/resolved-fonts-1280x800.json`, JSON.stringify(fonts, null, 2));
  await context.close();
}

async function captureVideo(browser) {
  await rm(`${outDir}/.video`, { recursive: true, force: true });
  const { context, page } = await createPage(browser, { width: 1280, height: 800 }, { recordVideo: true });

  await page.mouse.move(250, 500);
  await page.waitForTimeout(260);
  await page.locator('[data-card="ctx-code-position"] [data-card-action="peek"]').click({ force: true });
  await page.waitForTimeout(520);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(180);
  await page.locator("[data-compose]").click();
  await page.waitForTimeout(480);
  await page.locator("[data-draft-copy]").click();
  await page.waitForTimeout(420);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(220);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(260);

  const video = page.video();
  await context.close();
  if (video) {
    await video.saveAs(`${outDir}/prototype-approved-flow.webm`);
  }
  await rm(`${outDir}/.video`, { recursive: true, force: true });
}

async function writeManifest() {
  const manifest = `# Handy Prototype Reference Pack

Generated from the local GSAP prototype at ${url}.

Reference viewport screenshots:

- prototype-960x720.png
- prototype-1280x800.png
- prototype-1512x982.png

Interaction state screenshots:

- prototype-hover-card.png
- prototype-selection-tray.png
- prototype-horizontal-scroll.png
- prototype-peek-preview.png
- prototype-draft-ready.png
- prototype-draft-copy.png
- prototype-filtering-state.png
- prototype-empty-state.png

Edge summon screenshots:

- prototype-edge-top-left.png
- prototype-edge-top-right.png
- prototype-edge-bottom-left.png
- prototype-edge-bottom-right.png

Measurement data:

- computed-measurements-1280x800.json
- resolved-fonts-1280x800.json

Recording:

- prototype-approved-flow.webm
`;

  await writeFile(`${outDir}/MANIFEST.md`, manifest);
}

await mkdir(outDir, { recursive: true });
await ensureServer();

const browser = await chromium.launch({ headless: true, executablePath: chromePath });

try {
  await captureDefaultViewports(browser);
  await captureInteractionStates(browser);
  await capturePeekAndDraft(browser);
  await captureSearchStates(browser);
  await captureEdgeStates(browser);
  await captureMeasurements(browser);
  await captureVideo(browser);
  await writeManifest();
  console.log(`Saved reference pack to ${outDir}`);
} finally {
  await browser.close();
  if (server) server.kill("SIGTERM");
}
