import gsap from "gsap";
import "./styles.css";
import { categories, contextItems, intents, type ContextItem, type ContextType } from "./mockData";

type FilterId = "all" | ContextType;

const state = {
  isOpen: false,
  activeFilter: "all" as FilterId,
  search: "",
  goal: "Implement the edge-aware summon panel without bringing back the old floating hand.",
  selected: new Set<string>(["ctx-code-position", "ctx-image-surface"]),
  intent: intents[1],
  anchor: { x: window.innerWidth * 0.68, y: window.innerHeight * 0.34 },
  composeStatus: "idle" as "idle" | "ready",
  draftAction: "copy" as "copy" | "copied",
  draft: "",
  peekItemId: "",
  activeItemId: "ctx-code-position"
};

const app = document.querySelector<HTMLDivElement>("#app");

if (!app) {
  throw new Error("Missing #app");
}

app.innerHTML = `
  <main class="stage" data-stage>
    <section class="attention-field" aria-label="Attention canvas">
      <div class="workspace-shell">
        <div class="workspace-topline">
          <span>handy/native/SummonPanel.swift</span>
          <span>Context composer</span>
        </div>
        <div class="workspace-grid">
          <article class="code-pane">
            <div class="pane-label">Active focus</div>
            <pre><code>func placePanel(at point: CGPoint) {
  let margin: CGFloat = 16
  let preferred = point.offsetBy(dx: 16, dy: -16)
  let frame = visibleScreenFrame.insetBy(dx: margin, dy: margin)
}</code></pre>
          </article>
          <article class="browser-pane">
            <div class="pane-label">Reference</div>
            <div class="image-preview"></div>
            <p>Premium summon surface, quiet actions, visual cards.</p>
          </article>
        </div>
      </div>
      <button class="summon-button" type="button" aria-label="Summon Handy" aria-controls="handy-panel" aria-expanded="false" data-summon>
        <span></span>
      </button>
      <button class="edge-hotspot edge-hotspot-nw" type="button" aria-label="Summon Handy near top left" data-hotspot="nw"></button>
      <button class="edge-hotspot edge-hotspot-ne" type="button" aria-label="Summon Handy near top right" data-hotspot="ne"></button>
      <button class="edge-hotspot edge-hotspot-sw" type="button" aria-label="Summon Handy near bottom left" data-hotspot="sw"></button>
      <button class="edge-hotspot edge-hotspot-se" type="button" aria-label="Summon Handy near bottom right" data-hotspot="se"></button>
    </section>

    <div class="anchor-beam" data-anchor-beam></div>
    <div class="attention-pin" data-attention-pin></div>

    <section class="handy-panel" id="handy-panel" aria-label="Handy context composer" data-panel aria-hidden="true">
      <div class="panel-shell">
        <header class="panel-header" data-reveal>
          <div>
            <p class="eyebrow">Copy · Attach · Capture</p>
            <h1>Handy</h1>
            <p class="attention-copy">Handy appears exactly where your attention already is.</p>
          </div>
          <button class="icon-button" type="button" aria-label="Close Handy" data-close>
            <span></span>
          </button>
        </header>

        <label class="search-row" data-reveal>
          <span class="search-mark"></span>
          <input data-search type="search" placeholder="Search recent context" autocomplete="off" />
          <button class="search-clear" type="button" aria-label="Clear search" data-search-clear hidden></button>
          <span class="search-count" data-count></span>
        </label>

        <nav class="pill-row" aria-label="Context filters" data-pills data-reveal></nav>

        <div class="goal-row" data-reveal>
          <label>
            <span>Goal</span>
            <input data-goal type="text" autocomplete="off" />
          </label>
          <button class="goal-sharpen" type="button" aria-label="Sharpen goal" data-goal-sharpen>
            <span></span>
          </button>
        </div>

        <div class="gallery-wrap" data-reveal>
          <div class="context-rail" data-gallery></div>
        </div>

        <aside class="draft-preview" data-draft data-reveal aria-live="polite" hidden></aside>
        <aside class="peek-preview" data-peek role="dialog" aria-modal="false" aria-live="polite" hidden></aside>

        <footer class="compose-row" data-reveal>
          <div class="selected-tray">
            <div>
              <span data-selected-count></span>
              <small class="selected-hint" data-selected-hint></small>
            </div>
            <div class="selected-stack" data-selected-stack></div>
          </div>
          <label class="intent-picker">
            <span>Intent</span>
            <select data-intent></select>
          </label>
          <button class="compose-button" type="button" data-compose>
            <span data-compose-label>Compose</span>
          </button>
        </footer>
      </div>
    </section>
  </main>
`;

const stage = document.querySelector<HTMLElement>("[data-stage]")!;
const panel = document.querySelector<HTMLElement>("[data-panel]")!;
const panelShell = panel.querySelector<HTMLElement>(".panel-shell")!;
const anchorBeam = document.querySelector<HTMLElement>("[data-anchor-beam]")!;
const attentionPin = document.querySelector<HTMLElement>("[data-attention-pin]")!;
const summonButton = document.querySelector<HTMLButtonElement>("[data-summon]")!;
const galleryWrap = document.querySelector<HTMLElement>(".gallery-wrap")!;
const gallery = document.querySelector<HTMLElement>("[data-gallery]")!;
const pills = document.querySelector<HTMLElement>("[data-pills]")!;
const search = document.querySelector<HTMLInputElement>("[data-search]")!;
const searchClear = document.querySelector<HTMLButtonElement>("[data-search-clear]")!;
const count = document.querySelector<HTMLElement>("[data-count]")!;
const selectedCount = document.querySelector<HTMLElement>("[data-selected-count]")!;
const selectedHint = document.querySelector<HTMLElement>("[data-selected-hint]")!;
const selectedTray = document.querySelector<HTMLElement>(".selected-tray")!;
const selectedStack = document.querySelector<HTMLElement>("[data-selected-stack]")!;
const intentSelect = document.querySelector<HTMLSelectElement>("[data-intent]")!;
const goalInput = document.querySelector<HTMLInputElement>("[data-goal]")!;
const composeButton = document.querySelector<HTMLButtonElement>("[data-compose]")!;
const composeLabel = document.querySelector<HTMLElement>("[data-compose-label]")!;
const draftPreview = document.querySelector<HTMLElement>("[data-draft]")!;
const peekPreview = document.querySelector<HTMLElement>("[data-peek]")!;

gsap.defaults({ ease: "power3.out" });
gsap.set(panel, { autoAlpha: 0, scale: 0.96, y: 18 });
gsap.set([anchorBeam, attentionPin], { autoAlpha: 0 });

let activeTimeline: gsap.core.Timeline | null = null;
const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function searchTerm() {
  return state.search.trim().toLowerCase();
}

function matchesSearch(item: ContextItem, term = searchTerm()) {
  const haystack = `${item.title} ${item.preview} ${item.source} ${item.detail}`.toLowerCase();
  return !term || haystack.includes(term);
}

function filteredItems(filter = state.activeFilter) {
  return contextItems.filter((item) => {
    const matchesType = filter === "all" || item.type === filter;
    return matchesType && matchesSearch(item);
  });
}

function renderPills() {
  pills.innerHTML = categories
    .map((category) => {
      const resultCount = filteredItems(category.id).length;
      return `
        <button class="pill ${state.activeFilter === category.id ? "is-active" : ""}" type="button" aria-pressed="${state.activeFilter === category.id}" data-filter="${category.id}">
          <span>${category.label}</span>
          <span class="pill-count" aria-hidden="true">${resultCount}</span>
        </button>
      `;
    })
    .join("");
}

function renderIntent() {
  intentSelect.innerHTML = intents
    .map((intent) => `<option value="${intent}" ${intent === state.intent ? "selected" : ""}>${intent}</option>`)
    .join("");
}

function renderGallery() {
  const items = filteredItems();
  syncActiveItem(items);
  count.textContent = `${items.length} item${items.length === 1 ? "" : "s"}`;
  searchClear.hidden = !state.search;
  gallery.innerHTML = items.length
    ? items.map(renderCard).join("")
    : `<div class="empty-gallery">No matching context. Keep typing or switch filters.</div>`;
  gallery.scrollLeft = 0;
  scheduleRailAffordance();

  if (state.isOpen && !prefersReduced) {
    gsap.fromTo(
      gallery.querySelectorAll(".context-card"),
      { autoAlpha: 0, y: 18, scale: 0.985 },
      { autoAlpha: 1, y: 0, scale: 1, duration: 0.32, stagger: 0.035, ease: "power2.out" }
    );
    window.setTimeout(() => {
      if (state.isOpen) {
        gsap.set(gallery.querySelectorAll(".context-card"), { autoAlpha: 1, y: 0, scale: 1 });
      }
    }, 520);
  }
}

function syncActiveItem(items: ContextItem[]) {
  if (items.some((item) => item.id === state.activeItemId)) return;

  state.activeItemId = items[0]?.id ?? "";
}

function setActiveCard(id: string) {
  state.activeItemId = id;

  gallery.querySelectorAll<HTMLElement>("[data-card]").forEach((card) => {
    const active = card.dataset.card === id;
    card.classList.toggle("is-active", active);
    card.setAttribute("aria-current", String(active));
  });
}

function updateRailAffordance() {
  const maxScroll = gallery.scrollWidth - gallery.clientWidth;
  const canScroll = maxScroll > 2;

  galleryWrap.classList.toggle("can-scroll", canScroll);
  galleryWrap.classList.toggle("is-scrolled", canScroll && gallery.scrollLeft > 2);
  galleryWrap.classList.toggle("is-at-end", canScroll && gallery.scrollLeft >= maxScroll - 2);
}

function scheduleRailAffordance() {
  window.requestAnimationFrame(() => {
    updateRailAffordance();
    window.requestAnimationFrame(updateRailAffordance);
  });
}

function renderCard(item: ContextItem) {
  const selected = state.selected.has(item.id);
  const active = state.activeItemId === item.id;
  return `
    <article class="context-card ${selected ? "is-selected" : ""} ${active ? "is-active" : ""}" tabindex="0" role="button" aria-pressed="${selected}" aria-current="${active ? "true" : "false"}" data-card="${item.id}" style="--accent: ${item.accent}">
      <span class="selection-mark"></span>
      <div class="card-media card-media-${item.type}">
        ${renderMedia(item)}
      </div>
      <div class="card-body">
        <div class="card-meta">
          <span>${item.type}</span>
          <span>${item.age}</span>
        </div>
        <h2>${item.title}</h2>
        <p>${item.preview}</p>
      </div>
      <div class="card-footer">
        <span>${item.source}</span>
        <span>${item.detail}</span>
      </div>
      <div class="card-toolbar" aria-label="${item.title} actions">
        <button type="button" data-card-action="toggle">${selected ? "Added" : "Use"}</button>
        <button type="button" data-card-action="peek">Peek</button>
      </div>
    </article>
  `;
}

function renderMedia(item: ContextItem) {
  if (item.type === "code") {
    return `<pre><code>origin.x = flipX ? anchor.x - w - gap : anchor.x + gap
origin.y = flipY ? anchor.y - h - gap : anchor.y + gap</code></pre>`;
  }

  if (item.type === "image") {
    return `<div class="mock-shot"><span></span><span></span><span></span></div>`;
  }

  if (item.type === "url") {
    return `<div class="url-lines"><span></span><span></span><span></span></div>`;
  }

  if (item.type === "file") {
    return `<div class="file-glyph"><span>MD</span></div>`;
  }

  if (item.type === "thought") {
    return `<blockquote>Appears where attention already is.</blockquote>`;
  }

  return `<div class="text-fragment"><span></span><span></span><span></span></div>`;
}

function selectedItems() {
  return contextItems.filter((item) => state.selected.has(item.id));
}

function renderSelection() {
  const items = selectedItems();
  selectedCount.textContent = items.length ? `${items.length} selected` : "Select context";
  selectedHint.textContent = items.length ? "" : "Pick a card or peek one";
  selectedHint.hidden = items.length > 0;
  selectedStack.innerHTML = items
    .slice(0, 4)
    .map(
      (item) => `
        <button type="button" title="Remove ${item.title}" aria-label="Remove ${item.title}" data-selected-remove="${item.id}" style="--accent: ${item.accent}">
          <span>${item.type.slice(0, 1).toUpperCase()}</span>
        </button>
      `
    )
    .join("");
}

function renderDraft() {
  if (!state.draft) {
    draftPreview.hidden = true;
    draftPreview.innerHTML = "";
    return;
  }

  draftPreview.hidden = false;
  draftPreview.innerHTML = `
    <div class="draft-topline">
      <div>
        <span>Draft</span>
        <strong>${state.intent}</strong>
      </div>
      <button type="button" data-draft-copy aria-label="Copy composed prompt">${state.draftAction === "copied" ? "Copied" : "Copy prompt"}</button>
    </div>
    <p>${state.draft}</p>
  `;
}

function renderPeek() {
  const item = contextItems.find((candidate) => candidate.id === state.peekItemId);

  if (!item) {
    peekPreview.hidden = true;
    peekPreview.innerHTML = "";
    peekPreview.removeAttribute("aria-label");
    return;
  }

  const selected = state.selected.has(item.id);
  peekPreview.hidden = false;
  peekPreview.setAttribute("aria-label", `${item.title} preview`);
  peekPreview.style.setProperty("--accent", item.accent);
  peekPreview.innerHTML = `
    <div class="peek-topline">
      <span>${item.type}</span>
      <button type="button" aria-label="Close peek" data-peek-close></button>
    </div>
    <div class="peek-body">
      <div class="peek-media">${renderMedia(item)}</div>
      <div class="peek-copy">
        <h2>${item.title}</h2>
        <p>${item.preview}</p>
        <dl>
          <div><dt>Source</dt><dd>${item.source}</dd></div>
          <div><dt>Age</dt><dd>${item.age}</dd></div>
          <div><dt>Detail</dt><dd>${item.detail}</dd></div>
        </dl>
      </div>
    </div>
    <div class="peek-actions">
      <button type="button" data-peek-toggle>${selected ? "Added" : "Use context"}</button>
      <button type="button" data-peek-compose>Compose with this</button>
    </div>
  `;
}

function render() {
  goalInput.value = state.goal;
  renderPills();
  renderIntent();
  renderGallery();
  renderSelection();
  renderComposeState();
  renderDraft();
  renderPeek();
}

function renderComposeState() {
  const canCompose = state.selected.size > 0 && state.goal.trim().length > 0;
  composeButton.disabled = false;
  composeButton.setAttribute("aria-disabled", String(!canCompose));
  composeButton.title = canCompose ? "" : state.selected.size === 0 ? "Select context first" : "Add a goal first";
  composeLabel.textContent = state.draft ? (state.draftAction === "copied" ? "Copied" : "Copy prompt") : "Compose";
}

function settleOpenElements() {
  if (!state.isOpen) return;

  gsap.set(panel, { autoAlpha: 1, x: 0, y: 0, scale: 1 });
  gsap.set(panel.querySelectorAll("[data-reveal]"), { autoAlpha: 1, y: 0 });
  gsap.set(gallery.querySelectorAll(".context-card"), { autoAlpha: 1, y: 0, scale: 1 });
  updateRailAffordance();
}

function animateSelectionFeedback(card: HTMLElement, item: ContextItem, selected: boolean) {
  if (prefersReduced) return;

  const mark = card.querySelector<HTMLElement>(".selection-mark");
  if (mark) {
    gsap.fromTo(
      mark,
      { scale: selected ? 0.72 : 1.12 },
      { scale: selected ? 1 : 0.86, duration: 0.2, ease: "expo.out", overwrite: "auto" }
    );
  }

  gsap.fromTo(selectedCount, { y: selected ? 5 : -3, autoAlpha: 0.62 }, { y: 0, autoAlpha: 1, duration: 0.18, ease: "expo.out" });

  if (!selected) {
    gsap.fromTo(selectedStack, { scale: 0.97 }, { scale: 1, duration: 0.18, ease: "expo.out", overwrite: "auto" });
    return;
  }

  const start = (mark ?? card).getBoundingClientRect();
  const endTarget = selectedStack.querySelector<HTMLElement>(`[data-selected-remove="${item.id}"]`) ?? selectedStack;
  const end = endTarget.getBoundingClientRect();
  const pulse = document.createElement("span");
  pulse.className = "selection-pulse";
  pulse.style.setProperty("--accent", item.accent);
  pulse.setAttribute("aria-hidden", "true");
  document.body.append(pulse);
  window.setTimeout(() => pulse.remove(), 700);

  gsap.set(pulse, {
    x: start.left + start.width / 2 - 7,
    y: start.top + start.height / 2 - 7,
    scale: 0.86,
    autoAlpha: 0
  });

  gsap
    .timeline({
      defaults: { ease: "expo.out" },
      onComplete: () => pulse.remove()
    })
    .to(pulse, { autoAlpha: 1, scale: 1, duration: 0.08 }, 0)
    .to(pulse, { x: end.left + end.width / 2 - 7, y: end.top + end.height / 2 - 7, duration: 0.42 }, 0.02)
    .to(pulse, { scale: 0.46, autoAlpha: 0, duration: 0.16 }, 0.34)
    .fromTo(endTarget, { scale: 0.82 }, { scale: 1, duration: 0.24, ease: "expo.out" }, 0.28);
}

function resetDraft() {
  state.composeStatus = "idle";
  state.draftAction = "copy";
  state.draft = "";
  renderComposeState();
  renderDraft();
}

function clearSearch(shouldFocus = false) {
  state.search = "";
  search.value = "";
  resetDraft();
  closePeek();
  renderPills();
  renderGallery();

  if (shouldFocus) {
    search.focus();
  }
}

async function copyDraft() {
  if (!state.draft) return;

  state.draftAction = "copied";
  renderComposeState();
  renderDraft();
  focusDraftAction();

  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(state.draft);
    } catch {
      // Prototype fallback: native Handy owns the real paste/copy integration.
    }
  }

  if (!prefersReduced) {
    const action = draftPreview.querySelector<HTMLElement>("[data-draft-copy]");
    if (!action) return;

    gsap
      .timeline({ defaults: { ease: "expo.out" } })
      .fromTo(action, { scale: 0.92 }, { scale: 1, duration: 0.2 }, 0)
      .fromTo(composeButton, { scale: 0.94 }, { scale: 1, duration: 0.2 }, 0)
      .fromTo(draftPreview, { y: 3 }, { y: 0, duration: 0.18 }, 0);
  }
}

function closePeek(shouldRestoreFocus = false) {
  if (!state.peekItemId) return false;

  const closingItemId = state.peekItemId;
  state.peekItemId = "";
  renderPeek();

  if (shouldRestoreFocus) {
    restorePeekFocus(closingItemId);
  }

  return true;
}

function focusPeekPrimaryAction() {
  if (!state.isOpen || !state.peekItemId) return;

  peekPreview.querySelector<HTMLButtonElement>("[data-peek-toggle]")?.focus({ preventScroll: true });
}

function peekFocusTargets() {
  return Array.from(peekPreview.querySelectorAll<HTMLButtonElement>("button")).filter((button) => !button.disabled);
}

function cyclePeekFocus(event: KeyboardEvent) {
  if (!state.peekItemId || event.key !== "Tab") return;

  const targets = peekFocusTargets();
  if (!targets.length) return;

  const first = targets[0];
  const last = targets[targets.length - 1];
  const active = document.activeElement;

  if (event.shiftKey && active === first) {
    event.preventDefault();
    last.focus({ preventScroll: true });
    return;
  }

  if (!event.shiftKey && active === last) {
    event.preventDefault();
    first.focus({ preventScroll: true });
    return;
  }

  if (!peekPreview.contains(active)) {
    event.preventDefault();
    focusPeekPrimaryAction();
  }
}

function restorePeekFocus(itemId: string) {
  const card = gallery.querySelector<HTMLElement>(`[data-card="${itemId}"]`) ?? currentGalleryCard();

  if (!card) {
    focusSearch();
    return;
  }

  focusCard(card);
}

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

function positionPanel(anchor: { x: number; y: number }) {
  const margin = 18;
  const gap = 18;
  const width = panel.offsetWidth || Math.min(760, window.innerWidth - margin * 2);
  const height = panel.offsetHeight || Math.min(560, window.innerHeight - margin * 2);
  const fitsRight = anchor.x + gap + width <= window.innerWidth - margin;
  const fitsBelow = anchor.y + gap + height <= window.innerHeight - margin;
  let x = fitsRight ? anchor.x + gap : anchor.x - width - gap;
  let y = fitsBelow ? anchor.y + gap : anchor.y - height - gap;

  x = clamp(x, margin, window.innerWidth - width - margin);
  y = clamp(y, margin, window.innerHeight - height - margin);

  panel.style.setProperty("--panel-x", `${x}px`);
  panel.style.setProperty("--panel-y", `${y}px`);
  panel.style.setProperty("--origin-x", fitsRight ? "0%" : "100%");
  panel.style.setProperty("--origin-y", fitsBelow ? "0%" : "100%");

  const attachX = clamp(anchor.x, x + 26, x + width - 26);
  const attachY = clamp(anchor.y, y + 26, y + height - 26);
  const dx = attachX - anchor.x;
  const dy = attachY - anchor.y;
  const length = Math.hypot(dx, dy);
  const angle = Math.atan2(dy, dx) * (180 / Math.PI);

  gsap.set(attentionPin, { x: anchor.x - 5, y: anchor.y - 5 });
  gsap.set(anchorBeam, {
    x: anchor.x,
    y: anchor.y,
    scaleX: Math.max(length, 1),
    rotation: angle,
    transformOrigin: "0% 50%"
  });
}

function repositionPanel(anchor: { x: number; y: number }) {
  state.anchor = anchor;
  activeTimeline?.kill();

  const before = panel.getBoundingClientRect();
  gsap.set(panel, { x: 0, y: 0, scale: 1 });
  positionPanel(anchor);
  const after = panel.getBoundingClientRect();

  if (prefersReduced) {
    return;
  }

  activeTimeline = gsap
    .timeline({
      defaults: { ease: "expo.out", overwrite: "auto" },
      onComplete: () => gsap.set(panel, { x: 0, y: 0, scale: 1 })
    })
    .fromTo(panel, { x: before.left - after.left, y: before.top - after.top, scale: 0.992 }, { x: 0, y: 0, scale: 1, duration: 0.3 }, 0)
    .fromTo(attentionPin, { autoAlpha: 0.55, scale: 0.72 }, { autoAlpha: 1, scale: 1, duration: 0.18 }, 0)
    .fromTo(anchorBeam, { autoAlpha: 0.35 }, { autoAlpha: 1, duration: 0.2 }, 0.04);
}

function openPanel(anchor = state.anchor) {
  if (state.isOpen) {
    if (getComputedStyle(panel).visibility === "hidden") {
      settleOpenElements();
      panel.setAttribute("aria-hidden", "false");
    }
    summonButton.setAttribute("aria-expanded", "true");
    repositionPanel(anchor);
    focusSearch();
    return;
  }

  state.anchor = anchor;
  state.isOpen = true;
  panel.setAttribute("aria-hidden", "false");
  summonButton.setAttribute("aria-expanded", "true");
  positionPanel(anchor);
  render();
  activeTimeline?.kill();

  if (prefersReduced) {
    gsap.set([panel, anchorBeam, attentionPin], { autoAlpha: 1, scale: 1, y: 0 });
    updateRailAffordance();
    focusSearch();
    return;
  }

  const revealTargets = panel.querySelectorAll("[data-reveal]");
  const cards = panel.querySelectorAll(".context-card");
  const beamScale = Number(gsap.getProperty(anchorBeam, "scaleX")) || 1;

  activeTimeline = gsap
    .timeline({
      defaults: { ease: "expo.out" },
      onComplete: () => {
        settleOpenElements();
        focusSearch();
      }
    })
    .set(revealTargets, { autoAlpha: 0, y: 12 })
    .set(cards, { autoAlpha: 0, y: 18, scale: 0.985 })
    .to(attentionPin, { autoAlpha: 1, scale: 1, duration: 0.12 }, 0)
    .fromTo(
      panel,
      { autoAlpha: 0, scale: 0.96, y: 18 },
      { autoAlpha: 1, scale: 1, y: 0, duration: 0.42 },
      0
    )
    .fromTo(anchorBeam, { autoAlpha: 0, scaleX: 0.001 }, { autoAlpha: 1, scaleX: beamScale, duration: 0.22 }, 0.06)
    .to(revealTargets, { autoAlpha: 1, y: 0, duration: 0.32, stagger: 0.045 }, 0.1)
    .to(cards, { autoAlpha: 1, y: 0, scale: 1, duration: 0.34, stagger: 0.035, ease: "power2.out" }, 0.18);

  window.setTimeout(settleOpenElements, 720);
  window.setTimeout(focusSearch, 120);
  window.setTimeout(focusSearch, 520);
}

function hotspotAnchor(hotspot: string) {
  const margin = 34;
  const map: Record<string, { x: number; y: number }> = {
    nw: { x: margin, y: margin },
    ne: { x: window.innerWidth - margin, y: margin },
    sw: { x: margin, y: window.innerHeight - margin },
    se: { x: window.innerWidth - margin, y: window.innerHeight - margin }
  };
  return map[hotspot] ?? state.anchor;
}

function closePanel() {
  if (!state.isOpen) return;
  state.isOpen = false;
  summonButton.setAttribute("aria-expanded", "false");
  activeTimeline?.kill();

  if (prefersReduced) {
    gsap.set([panel, anchorBeam, attentionPin], { autoAlpha: 0 });
    panel.setAttribute("aria-hidden", "true");
    restoreClosedFocus();
    return;
  }

  activeTimeline = gsap
    .timeline({
      defaults: { ease: "power2.in" },
      onComplete: finishClosedPanel
    })
    .to(anchorBeam, { autoAlpha: 0, duration: 0.12 }, 0)
    .to(attentionPin, { autoAlpha: 0, scale: 0.6, duration: 0.12 }, 0)
    .to(panel, { autoAlpha: 0, x: 0, scale: 0.985, y: 12, duration: 0.18 }, 0);

  window.setTimeout(finishClosedPanel, 260);
}

function finishClosedPanel() {
  if (state.isOpen) return;

  panel.setAttribute("aria-hidden", "true");
  restoreClosedFocus();
}

function restoreClosedFocus() {
  summonButton.focus({ preventScroll: true });
}

function focusSearch() {
  if (state.isOpen) {
    search.focus({ preventScroll: true });
  }
}

function focusDraftAction() {
  if (!state.isOpen || !state.draft) return;

  draftPreview.querySelector<HTMLButtonElement>("[data-draft-copy]")?.focus({ preventScroll: true });
}

function toggleSelected(id: string, options: { focusCard?: boolean } = {}) {
  const willSelect = !state.selected.has(id);
  const item = contextItems.find((candidate) => candidate.id === id);
  const shouldFocusCard = options.focusCard ?? true;
  setActiveCard(id);

  if (state.selected.has(id)) {
    state.selected.delete(id);
  } else {
    state.selected.add(id);
  }

  resetDraft();
  const card = gallery.querySelector<HTMLElement>(`[data-card="${id}"]`);
  if (card) {
    if (shouldFocusCard) {
      card.focus();
    }
    card.classList.toggle("is-selected", willSelect);
    card.setAttribute("aria-pressed", String(willSelect));
    const toggle = card.querySelector<HTMLElement>("[data-card-action='toggle']");
    if (toggle) {
      toggle.textContent = willSelect ? "Added" : "Use";
    }
  }

  renderSelection();
  renderPeek();

  if (card && !prefersReduced) {
    gsap.fromTo(
      card,
      { scale: willSelect ? 0.985 : 1.018 },
      { scale: 1, duration: 0.22, ease: "expo.out", overwrite: "auto" }
    );
  }

  if (card && item) {
    animateSelectionFeedback(card, item, willSelect);
  }
}

function removeSelected(id: string) {
  if (!state.selected.has(id)) return;

  const previousSelection = selectedItems();
  const removedIndex = previousSelection.findIndex((item) => item.id === id);
  state.selected.delete(id);
  resetDraft();

  const card = gallery.querySelector<HTMLElement>(`[data-card="${id}"]`);
  if (card) {
    card.classList.remove("is-selected");
    card.setAttribute("aria-pressed", "false");
    const toggle = card.querySelector<HTMLElement>("[data-card-action='toggle']");
    if (toggle) {
      toggle.textContent = "Use";
    }
  }

  renderSelection();
  renderPeek();
  restoreSelectionFocus(id, removedIndex);

  if (!prefersReduced) {
    gsap
      .timeline({ defaults: { ease: "expo.out" } })
      .fromTo(selectedCount, { y: -3, autoAlpha: 0.62 }, { y: 0, autoAlpha: 1, duration: 0.18 }, 0)
      .fromTo(selectedStack, { scale: 0.97 }, { scale: 1, duration: 0.18, overwrite: "auto" }, 0.02);
  }
}

function restoreSelectionFocus(removedId: string, removedIndex: number) {
  const remainingItems = selectedItems();

  if (remainingItems.length) {
    const nextItem = remainingItems[clamp(removedIndex, 0, remainingItems.length - 1)];
    const nextChip = selectedStack.querySelector<HTMLElement>(`[data-selected-remove="${nextItem.id}"]`);
    nextChip?.focus({ preventScroll: true });
    return;
  }

  const visibleCard = gallery.querySelector<HTMLElement>(`[data-card="${removedId}"]`) ?? currentGalleryCard();

  if (visibleCard) {
    setActiveCard(visibleCard.dataset.card!);
    visibleCard.focus({ preventScroll: true });
    visibleCard.scrollIntoView({ behavior: prefersReduced ? "auto" : "smooth", block: "nearest", inline: "nearest" });
    return;
  }

  search.focus({ preventScroll: true });
}

function openPeek(id: string) {
  setActiveCard(id);
  state.peekItemId = id;
  renderPeek();

  if (!prefersReduced) {
    gsap.fromTo(peekPreview, { autoAlpha: 0, y: 12, scale: 0.985 }, {
      autoAlpha: 1,
      y: 0,
      scale: 1,
      duration: 0.24,
      ease: "expo.out",
      overwrite: "auto",
      onComplete: focusPeekPrimaryAction
    });
    window.setTimeout(focusPeekPrimaryAction, 320);
    return;
  }

  focusPeekPrimaryAction();
}

function animateCard(card: HTMLElement, active: boolean) {
  const media = card.querySelector(".card-media");

  gsap.to(card, {
    y: 0,
    scale: 1,
    duration: 0.16,
    ease: "power2.out",
    overwrite: "auto"
  });
  gsap.to(media, {
    y: active ? -2 : 0,
    scale: active ? 1.012 : 1,
    duration: 0.16,
    ease: "power2.out",
    overwrite: "auto"
  });
  gsap.to(card.querySelector(".card-toolbar"), {
    autoAlpha: active || card.classList.contains("is-selected") ? 1 : 0,
    scale: active || card.classList.contains("is-selected") ? 1 : 0.96,
    duration: 0.14,
    ease: "power2.out",
    overwrite: "auto"
  });
}

function composeDraft() {
  if (state.selected.size === 0 || !state.goal.trim()) {
    nudgeComposeRequirement();
    return;
  }

  const selectedItems = contextItems.filter((item) => state.selected.has(item.id));
  const titles = selectedItems.map((item) => item.title).join(", ");
  state.composeStatus = "ready";
  state.draftAction = "copy";
  state.draft = `${state.goal.trim()} Use ${selectedItems.length} selected context item${selectedItems.length === 1 ? "" : "s"}: ${titles}.`;
  renderComposeState();
  renderDraft();

  if (!prefersReduced) {
    gsap
      .timeline({ defaults: { ease: "expo.out" }, onComplete: focusDraftAction })
      .fromTo(composeButton, { scale: 0.96 }, { scale: 1, duration: 0.22 }, 0)
      .fromTo(draftPreview, { autoAlpha: 0, y: 10, scale: 0.99 }, { autoAlpha: 1, y: 0, scale: 1, duration: 0.26 }, 0.02)
      .fromTo(selectedStack.querySelectorAll("button"), { y: 8, autoAlpha: 0.5 }, { y: 0, autoAlpha: 1, duration: 0.24, stagger: 0.035 }, 0.03);
    window.setTimeout(focusDraftAction, 360);
    return;
  }

  focusDraftAction();
}

function runPrimaryAction() {
  if (state.draft) {
    closePeek();
    void copyDraft();
    return;
  }

  closePeek();
  composeDraft();
}

function nudgeComposeRequirement() {
  if (prefersReduced) return;

  const target = state.selected.size === 0 ? selectedTray : goalInput;
  gsap
    .timeline({ defaults: { ease: "expo.out", overwrite: "auto" } })
    .fromTo(target, { x: -4 }, { x: 0, duration: 0.2 }, 0)
    .fromTo(composeButton, { scale: 0.985, autoAlpha: 0.7 }, { scale: 1, autoAlpha: 1, duration: 0.2 }, 0);
}

function sharpenGoal() {
  const options = [
    "Turn the selected context into a concrete implementation plan for the native summon panel.",
    "Find the highest-risk interaction gaps before rebuilding Handy in AppKit.",
    "Write the Codex prompt needed to implement this without reviving the old floating hand."
  ];
  const next = options.find((option) => option !== state.goal) ?? options[0];
  state.goal = next;
  resetDraft();
  goalInput.value = next;

  if (!prefersReduced) {
    gsap.fromTo(goalInput, { x: -4 }, { x: 0, duration: 0.22, ease: "expo.out", overwrite: "auto" });
  }
}

stage.addEventListener("pointermove", (event) => {
  if (state.isOpen) return;
  if (!(event.target as HTMLElement).closest(".attention-field")) return;

  state.anchor = { x: event.clientX, y: event.clientY };
});

stage.addEventListener("click", (event) => {
  const target = event.target as HTMLElement;
  const summon = target.closest("[data-summon]");
  const close = target.closest("[data-close]");
  const filter = target.closest<HTMLElement>("[data-filter]");
  const card = target.closest<HTMLElement>("[data-card]");
  const hotspot = target.closest<HTMLElement>("[data-hotspot]");
  const cardAction = target.closest<HTMLElement>("[data-card-action]");
  const sharpen = target.closest("[data-goal-sharpen]");
  const compose = target.closest("[data-compose]");
  const peekClose = target.closest("[data-peek-close]");
  const peekToggle = target.closest("[data-peek-toggle]");
  const peekCompose = target.closest("[data-peek-compose]");
  const draftCopy = target.closest("[data-draft-copy]");
  const selectedRemove = target.closest<HTMLElement>("[data-selected-remove]");

  if (draftCopy) {
    void copyDraft();
    return;
  }

  if (selectedRemove) {
    removeSelected(selectedRemove.dataset.selectedRemove!);
    return;
  }

  if (peekClose) {
    closePeek(true);
    return;
  }

  if (peekToggle && state.peekItemId) {
    toggleSelected(state.peekItemId, { focusCard: false });
    focusPeekPrimaryAction();
    window.requestAnimationFrame(focusPeekPrimaryAction);
    window.setTimeout(focusPeekPrimaryAction, 80);

    if (!prefersReduced) {
      const action = peekPreview.querySelector<HTMLElement>("[data-peek-toggle]");
      if (action) {
        gsap.fromTo(action, { scale: 0.92 }, { scale: 1, duration: 0.18, ease: "expo.out", overwrite: "auto" });
      }
    }

    return;
  }

  if (peekCompose && state.peekItemId) {
    if (!state.selected.has(state.peekItemId)) {
      toggleSelected(state.peekItemId, { focusCard: false });
    }
    closePeek();
    composeDraft();
    return;
  }

  if (close) {
    closePanel();
    return;
  }

  if (filter) {
    state.activeFilter = filter.dataset.filter as FilterId;
    resetDraft();
    closePeek();
    render();
    if (!prefersReduced) {
      const activePill = pills.querySelector<HTMLElement>(".pill.is-active");
      if (activePill) {
        gsap.fromTo(activePill, { scale: 0.94 }, { scale: 1, duration: 0.2, ease: "expo.out", overwrite: "auto" });
      }
      gsap.fromTo(count, { y: 4, autoAlpha: 0.62 }, { y: 0, autoAlpha: 1, duration: 0.18, ease: "expo.out", overwrite: "auto" });
    }
    return;
  }

  if (cardAction) {
    const actionCard = cardAction.closest<HTMLElement>("[data-card]");
    if (actionCard && cardAction.dataset.cardAction === "toggle") {
      toggleSelected(actionCard.dataset.card!);
    }
    if (actionCard && cardAction.dataset.cardAction === "peek") {
      openPeek(actionCard.dataset.card!);
    }
    return;
  }

  if (card && !target.closest(".card-toolbar")) {
    card.focus({ preventScroll: true });
    toggleSelected(card.dataset.card!);
    return;
  }

  if (sharpen) {
    sharpenGoal();
    return;
  }

  if (compose) {
    runPrimaryAction();
    return;
  }

  if (hotspot) {
    openPanel(hotspotAnchor(hotspot.dataset.hotspot!));
    return;
  }

  if (summon || target.closest(".attention-field")) {
    openPanel({ x: event.clientX, y: event.clientY });
  }
});

gallery.addEventListener("click", (event) => {
  const target = event.target as HTMLElement;
  const cardAction = target.closest<HTMLElement>("[data-card-action]");
  const card = target.closest<HTMLElement>("[data-card]");

  if (!card) return;
  event.stopPropagation();

  if (cardAction && cardAction.dataset.cardAction === "peek") {
    openPeek(card.dataset.card!);
    return;
  }

  if (cardAction && cardAction.dataset.cardAction !== "toggle") {
    return;
  }

  card.focus({ preventScroll: true });
  toggleSelected(card.dataset.card!);
});

gallery.addEventListener("scroll", updateRailAffordance, { passive: true });

gallery.addEventListener(
  "wheel",
  (event) => {
    if (Math.abs(event.deltaY) <= Math.abs(event.deltaX) || gallery.scrollWidth <= gallery.clientWidth) return;

    event.preventDefault();
    const target = clamp(gallery.scrollLeft + event.deltaY, 0, gallery.scrollWidth - gallery.clientWidth);

    if (prefersReduced) {
      gallery.scrollLeft = target;
      updateRailAffordance();
      return;
    }

    gsap.to(gallery, {
      scrollLeft: target,
      duration: 0.26,
      ease: "expo.out",
      overwrite: "auto",
      onUpdate: updateRailAffordance,
      onComplete: updateRailAffordance
    });
  },
  { passive: false }
);

gallery.addEventListener("pointerenter", (event) => {
  const card = (event.target as HTMLElement).closest<HTMLElement>("[data-card]");
  if (card) animateCard(card, true);
}, true);

gallery.addEventListener("pointerleave", (event) => {
  const card = (event.target as HTMLElement).closest<HTMLElement>("[data-card]");
  if (card) animateCard(card, false);
}, true);

gallery.addEventListener("focusin", (event) => {
  const card = (event.target as HTMLElement).closest<HTMLElement>("[data-card]");
  if (card) {
    setActiveCard(card.dataset.card!);
    animateCard(card, true);
  }
});

gallery.addEventListener("focusout", (event) => {
  const card = (event.target as HTMLElement).closest<HTMLElement>("[data-card]");
  if (card) animateCard(card, false);
});

search.addEventListener("input", () => {
  state.search = search.value;
  resetDraft();
  closePeek();
  renderPills();
  renderGallery();

  if (!prefersReduced) {
    gsap.fromTo(count, { y: 4, autoAlpha: 0.62 }, { y: 0, autoAlpha: 1, duration: 0.18, ease: "expo.out", overwrite: "auto" });
  }
});

search.addEventListener("keydown", (event) => {
  if (event.key === "ArrowDown") {
    event.preventDefault();
    focusActiveCard();
    return;
  }

  if (event.key !== "Enter") return;

  const card = currentGalleryCard();
  if (!card) return;

  event.preventDefault();
  const id = card.dataset.card!;

  if (!state.selected.has(id)) {
    toggleSelected(id);
    return;
  }

  focusActiveCard();
});

searchClear.addEventListener("click", () => {
  if (!state.search) return;

  clearSearch(true);

  if (!prefersReduced) {
    gsap.fromTo(searchClear, { scale: 0.82 }, { scale: 1, duration: 0.16, ease: "expo.out", overwrite: "auto" });
    gsap.fromTo(count, { y: -4, autoAlpha: 0.62 }, { y: 0, autoAlpha: 1, duration: 0.18, ease: "expo.out", overwrite: "auto" });
  }
});

intentSelect.addEventListener("change", () => {
  state.intent = intentSelect.value;
  resetDraft();
});

goalInput.addEventListener("input", () => {
  state.goal = goalInput.value;
  resetDraft();
});

goalInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter") {
    event.preventDefault();
    composeDraft();
  }
});

gallery.addEventListener("keydown", (event) => {
  const card = (event.target as HTMLElement).closest<HTMLElement>("[data-card]");
  if (!card) return;

  if (event.key.toLowerCase() === "p") {
    event.preventDefault();
    openPeek(card.dataset.card!);
    return;
  }

  if (event.key === "ArrowUp") {
    event.preventDefault();
    search.focus({ preventScroll: true });
    return;
  }

  if (event.key === "Home" || event.key === "End") {
    event.preventDefault();
    focusRailEdge(event.key === "Home" ? "start" : "end");
    return;
  }

  if (event.key === "ArrowRight" || event.key === "ArrowLeft") {
    event.preventDefault();
    focusAdjacentCard(card, event.key === "ArrowRight" ? 1 : -1);
    return;
  }

  if (event.key !== "Enter" && event.key !== " ") return;

  event.preventDefault();
  toggleSelected(card.dataset.card!);
});

function visibleCards() {
  return Array.from(gallery.querySelectorAll<HTMLElement>("[data-card]"));
}

function focusAdjacentCard(current: HTMLElement, direction: 1 | -1) {
  const cards = visibleCards();
  const index = cards.indexOf(current);
  const next = cards[clamp(index + direction, 0, cards.length - 1)];

  if (!next || next === current) return;

  focusCard(next);
}

function focusRailEdge(edge: "start" | "end") {
  const cards = visibleCards();
  const card = edge === "start" ? cards[0] : cards[cards.length - 1];

  if (card) {
    focusCard(card);
  }
}

function focusCard(card: HTMLElement) {
  setActiveCard(card.dataset.card!);
  card.focus({ preventScroll: true });
  card.scrollIntoView({ behavior: prefersReduced ? "auto" : "smooth", block: "nearest", inline: "nearest" });
}

function currentGalleryCard() {
  if (state.activeItemId) {
    const active = gallery.querySelector<HTMLElement>(`[data-card="${state.activeItemId}"]`);
    if (active) return active;
  }

  return gallery.querySelector<HTMLElement>("[data-card]");
}

function focusActiveCard() {
  const card = currentGalleryCard();
  if (!card) return false;

  focusCard(card);
  return true;
}

panel.addEventListener("pointermove", (event) => {
  const rect = panel.getBoundingClientRect();
  panelShell.style.setProperty("--spot-x", `${event.clientX - rect.left}px`);
  panelShell.style.setProperty("--spot-y", `${event.clientY - rect.top}px`);
});

peekPreview.addEventListener("keydown", cyclePeekFocus);

window.addEventListener("keydown", (event) => {
  const target = event.target as HTMLElement | null;
  const isTyping = target?.matches("input, textarea, select, [contenteditable='true']");
  const isCommandEnter = event.key === "Enter" && (event.metaKey || event.ctrlKey);

  if (isCommandEnter) {
    event.preventDefault();
    runPrimaryAction();
    return;
  }

  if (event.key === "Escape") {
    if (closePeek(true)) {
      return;
    }

    if (state.draft) {
      resetDraft();
      focusSearch();
      return;
    }

    if (state.search) {
      clearSearch(true);
      return;
    }

    closePanel();
  }
  if (!isTyping && event.key.toLowerCase() === "h" && !event.metaKey && !event.ctrlKey && !event.altKey) {
    event.preventDefault();
    openPanel(state.anchor);
    return;
  }
  if (!isTyping && event.key.toLowerCase() === "p" && !event.metaKey && !event.ctrlKey && !event.altKey && state.activeItemId) {
    event.preventDefault();
    openPeek(state.activeItemId);
    return;
  }
});

window.addEventListener("resize", () => {
  if (state.isOpen) {
    positionPanel(state.anchor);
    updateRailAffordance();
  }
});

render();
openPanel(state.anchor);
