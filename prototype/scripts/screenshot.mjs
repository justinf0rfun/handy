import { mkdir } from "node:fs/promises";
import { spawn } from "node:child_process";
import { chromium } from "playwright";

const port = process.env.PORT || "4175";
const url = `http://127.0.0.1:${port}`;
const out = "screenshots/handy-prototype.png";

const server = spawn("npm", ["run", "dev", "--", "--port", port], {
  stdio: "inherit",
  shell: true
});

async function waitForServer() {
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok) return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
  }
  throw new Error(`Timed out waiting for ${url}`);
}

try {
  await waitForServer();
  await mkdir("screenshots", { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto(url);
  await page.mouse.click(860, 248);
  await page.waitForTimeout(900);
  await page.screenshot({ path: out });
  await browser.close();
  console.log(`Saved ${out}`);
} finally {
  server.kill("SIGTERM");
}
