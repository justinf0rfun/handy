# Handy Prototype to Native Executable Spec

## Purpose

This document translates the approved GSAP prototype direction into a native macOS implementation contract.

The prototype is not production code. Its output is the interaction language, motion timing, visual density, focus behavior, and native fidelity target for the first AppKit/Swift vertical slice.

## Product Principle

Handy appears exactly where your attention already is.

Native implementation must preserve this before adding real storage, real capture sources, sync readiness, Codex handoff automation, or settings.

## Product Copy

Primary product language:

- Brand: `Handy`
- Action grammar: `Copy / Attach / Capture`
- Exact display eyebrow: `Copy · Attach · Capture`
- Promise: `Handy appears exactly where your attention already is.`
- Current surface role: contextual command panel for composing AI-ready context.
- Native v1 tone: premium, quiet, fast, local-first, not a clipboard history list.

Do not reintroduce the old persistent floating hand or mascot behavior. Handy is summonable, contextual, and transient.

## Current Prototype Verdict

Prototype state: approved candidate for native specification based on the current local prototype.

- Prototype source root: `/Users/justin/workspace/handy/prototype`
- Run command: `npm run dev -- --host 127.0.0.1`
- Current local URL: `http://127.0.0.1:5173/`
- Main layout and interaction file: `/Users/justin/workspace/handy/prototype/src/main.ts`
- Design and visual token file: `/Users/justin/workspace/handy/prototype/src/styles.css`
- Mock data file: `/Users/justin/workspace/handy/prototype/src/mockData.ts`
- Prototype notes: `/Users/justin/workspace/handy/prototype/NOTES.md`
- Screenshot directory: `/Users/justin/workspace/handy/prototype/screenshots`

Known media evidence already captured during polish:

- `browser-polish-peek-toggle-focus.png`
- `browser-polish-peek-tab-loop.png`
- `browser-polish-draft-reload.png`
- `browser-polish-close-focus-return.png`
- `playwright-polish-draft-copied-focus.png`
- `playwright-polish-hover-restored-scroll.png`

Still required before a final native handoff:

- One short approved-flow recording.
- Final screenshots at `960x720`, `1280x800`, and `1512x982`.
- Edge screenshots for top-left, top-right, bottom-left, and bottom-right summon.
- A computed-measurements JSON for the approved `1280x800` reference state.
- Resolved font names on the reference machine.
- A state-by-state screenshot pack covering default, hover, selected, peek, draft, copied, filter, empty, and every edge summon.

Accepted v1 prototype compromises:

- Browser click position simulates the native global shortcut and mouse position.
- Context items are static mock data.
- Clipboard write and Codex handoff are visual placeholders.
- Real capture sources and persistence are deferred until the native vertical slice feels right.

## Native Fidelity Targets

Target fidelity:

- Pixel-level layout replication for the approved demo states.
- Interaction behavior and focus flow: 95% or higher.
- Motion timing and staging: 90% or higher.
- Material/shadow rendering: perceptually equivalent, because AppKit material and browser backdrop filters are not identical.

The native version is off-track if it keeps the feature list but loses:

- attention-point summon feeling,
- edge-aware stability,
- calm premium command-surface quality,
- fast search/filter/select flow,
- clear selected context and compose affordance,
- keyboard focus continuity.

## Pixel Match Contract

Pixel-level replication means the native demo should match the approved prototype screenshots when overlaid at the same viewport size and scale factor.

Source of truth order:

1. Approved screenshot or recording for the state.
2. Computed measurement table in this document.
3. Prototype CSS and TypeScript in `/Users/justin/workspace/handy/prototype/src`.
4. Product intent in this document.

If these disagree, the approved screenshot wins. If no screenshot exists for the state, capture one before native implementation.

Pixel-critical areas:

- Panel frame, corner radius, padding, internal section positions, and footer reachability.
- Search row, category pills, goal row, gallery rail, card dimensions, card gap, selected tray, intent picker, and compose button.
- Overlay placement for peek and draft preview.
- Attention pin/beam position relative to the anchor and panel edge.
- Hidden vs visible card actions.
- Text line count, truncation, and no-overlap behavior.

Perceptual-match areas:

- Native blur/material, backdrop saturation, and soft shadow falloff.
- Font rasterization and subpixel antialiasing.
- `color-mix()` output where AppKit cannot reproduce browser blending exactly.
- Easing curves when mapped from GSAP to Core Animation.

Pixel demo constraints:

- Use the same reference viewport sizes and a `1x` screenshot scale for pixel comparison.
- Lock the same resolved fonts or record native font substitutions before comparison.
- Disable unrelated OS effects that can change captures, such as transparency reduction, high contrast, or non-default display scaling.
- Capture prototype and native on the same display color profile where possible.
- Do not judge motion by final stills only; compare recordings for enter, exit, hover, selection, peek, and compose/copy.

Required screenshot states:

| State | Trigger | Must Show |
| --- | --- | --- |
| Default open | Open at default anchor | Search focused, two selected cards, footer visible |
| Hover card | Pointer over first visible card | Toolbar visible, media lifted, no rail clipping |
| Active selected | Focus/selection on positioning card | Selected border and mark |
| Horizontal scroll | Scroll rail right | Left fade visible, footer still reachable |
| Search filter | Type a matching query | Counts update, rail redraws |
| Empty filter | Type no-match query | Dashed empty state |
| Peek | Open peek on selected code card | Overlay at fixed top, focus in peek |
| Draft | Compose selected context | Draft preview above footer |
| Copied | Copy draft | Draft and primary CTA show copied feedback |
| Edge top-left | Summon near top-left | Panel flips/clamps and beam attaches |
| Edge top-right | Summon near top-right | Panel flips left and clamps |
| Edge bottom-left | Summon near bottom-left | Panel flips above and clamps |
| Edge bottom-right | Summon near bottom-right | Panel flips above/left and clamps |

## Native Vertical Slice Scope

Build this slice first, with mock data only:

1. Global shortcut opens a transient panel near the current mouse position.
2. Panel flips and clamps inside the visible screen frame.
3. Panel enter/exit motion matches the approved prototype.
4. Header shows `Copy · Attach · Capture`, `Handy`, and the attention promise.
5. Search, category pills, horizontal gallery, selected tray, intent picker, peek preview, and draft preview render with approved density.
6. Search filters cards, pills show live counts, no-results state is visible.
7. Cards can be hovered, focused, peeked, selected, and deselected.
8. Selected tray updates without layout jump.
9. Compose produces a draft preview and copy feedback.
10. Escape closes previews, clears transient draft/search state, then dismisses Handy.

Do not implement persistence, real capture, iCloud, user settings, or real Codex paste until this slice feels correct.

## Approved Flow

Native v1 must reproduce this flow:

1. User invokes Handy with a global shortcut.
2. Handy appears near the current attention point, using mouse position in v1.
3. The attention pin and panel placement visually connect the panel to the summon point.
4. Search is focused automatically.
5. Header, search, pills, goal, gallery, and footer reveal in staged order.
6. User types search text or picks a category pill.
7. Card rail updates without resizing the panel.
8. User hovers or focuses a card; toolbar appears quietly.
9. User selects cards; selected tray count and chips update.
10. User optionally opens peek; focus moves into the preview action layer.
11. User chooses an intent and composes.
12. Draft preview appears above the footer, focus moves to `Copy prompt`.
13. Copy feedback changes both the draft action and primary CTA to `Copied`.
14. User dismisses with Escape or completes handoff.

## Layout Spec

### Viewports

Current verified target viewports:

- Minimum desktop prototype viewport: `960x720`
- Primary desktop viewport: `1280x800`
- Wide desktop viewport: `1512x982`
- Small responsive breakpoint: `max-width: 720px`
- Short viewport breakpoint: `max-height: 760px`

Panel sizing:

- Width: `min(760px, viewportWidth - 36px)`
- Max height: `viewportHeight - 36px`
- Outer safe margin: `18px`
- Pointer gap from anchor: `18px`
- Corner radius: `32px`
- Content padding: `clamp(18px, 2.7vw, 28px)`
- Internal vertical gap: `16px`, reduced to `12px` on short screens.

Card rail:

- Horizontal rail, not vertical clipboard list.
- Card width: `min(270px, 72vw)`
- Card minimum height: `318px`, reduced to `278px` on short screens.
- Gap: `14px`
- Horizontal scroll starts when total card width exceeds the rail.
- Scrollbar hidden.
- Edge fades show only when additional cards are available.

Text truncation:

- Goal input uses single-line ellipsis.
- Card body preview clamps to 3 lines.
- Draft preview clamps to 2 lines.
- Peek preview clamps detail copy to 3 lines.

### Reference Measurements

These measurements were captured from the running prototype at `1280x800`, `deviceScaleFactor=1`, after the default open animation settled.

Use them as the first native pixel-clone target. Re-capture them if the prototype changes.

| Element | x | y | w | h | Notes |
| --- | ---: | ---: | ---: | ---: | --- |
| `.handy-panel` | 92 | 18 | 760 | 764 | CSS panel box, `z-index: 5` |
| `.panel-shell` | 92 | 18 | 760 | 775 | Visual shell; 28px padding, 16px grid gap, 32px radius |
| `.panel-header` | 121 | 47 | 702 | 89 | Header row |
| `.eyebrow` | 121 | 47 | 347 | 16 | 12px, weight 760, uppercase |
| `h1` | 121 | 68 | 347 | 43 | 42px, line-height 42.84px, weight 720 |
| `.attention-copy` | 121 | 117 | 347 | 19 | 14px, line-height 18.9px |
| close button | 783 | 71 | 40 | 40 | Radius 14px |
| `.search-row` | 121 | 152 | 702 | 54 | Focused by default |
| `.pill-row` | 121 | 222 | 702 | 34 | 8px gap |
| active `All` pill | 121 | 222 | 75 | 34 | 13px horizontal padding |
| `.goal-row` | 121 | 272 | 702 | 67 | 10px grid gap |
| `.gallery-wrap` | 121 | 355 | 702 | 330 | Clips edge fades only |
| `.context-rail` | 121 | 355 | 702 | 330 | `scrollWidth: 1690`, padding `2px 0 10px` |
| first card | 121 | 357 | 270 | 318 | 12px padding, 12px grid gap, 24px radius |
| active selected card | 405 | 357 | 270 | 318 | Second visible card in default state |
| card media | 134 | 370 | 244 | 131 | 18px radius |
| card toolbar | 267 | 374 | 108 | 27 | Hidden opacity at rest |
| footer `.compose-row` | 121 | 701 | 702 | 63 | Must remain reachable |
| selected tray | 121 | 703 | 162 | 61 | 10px gap |
| selected chip | 188 | 718 | 30 | 30 | Overlap via `margin-left: -7px` after first chip |
| intent picker | 402 | 703 | 178 | 61 | Select height 40px |
| compose button | 699 | 703 | 124 | 61 | Radius 16px |
| attention pin | 865 | 267 | 10 | 10 | Default anchor visual |
| anchor beam | 826 | 272 | 44 | 1 | Scaled/rotated from anchor |

Overlay measurements at `1280x800`:

| State | Element | x | y | w | h | Notes |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Peek selected code card | `.peek-preview` | 121 | 173 | 702 | 264 | Top overlay, 14px padding, 13px gap, radius 22px |
| Draft ready | `.draft-preview` | 121 | 584 | 702 | 104 | Bottom overlay above footer |
| Draft copied | `.draft-preview` | 121 | 584 | 702 | 104 | Same frame; copy label changes |

Resolved computed values at the same reference state:

- Panel left/top CSS vars: `92.4px`, `18px`.
- Panel transform origin: `760px 764px` for the default bottom-right anchor placement.
- Shell padding: `28px`.
- Shell background base: `rgba(20, 22, 22, 0.96)`.
- Shell border: `1px solid rgba(255,255,255,0.11)`.
- Shell shadow: inset top highlight plus `0 42px 110px rgba(0,0,0,0.54)`.
- Search focused border: `1px solid rgba(214,184,121,0.42)`.
- Card rail visible width: `702px`.
- Card rail full scroll width: `1690px`.
- Default selected item ids: `ctx-code-position`, `ctx-image-surface`.

Prototype accent colors:

| Type/Item | Accent |
| --- | --- |
| text / renderer crash note | `#8bc7b2` |
| code / positioning branch | `#d6b879` |
| url / GSAP docs | `#87a9d9` |
| image / dark surface reference | `#c99595` |
| file / Handy PRD | `#a6b889` |
| thought / attention promise | `#b8a2d1` |

### Panel Visual Treatment

Native panel should reproduce these visual values, with native material/shadow allowed to be perceptually equivalent where AppKit cannot exactly match browser backdrop filters:

- Dark tinted background: `rgba(20, 22, 22, 0.96)`.
- Outer border: `rgba(255,255,255,0.11)`.
- Inner highlight: white alpha around `0.16` at top edge.
- Backdrop/material: blur and saturation similar to `blur(28px) saturate(125%)`.
- Shadow: large soft panel shadow, visually close to `0 42px 110px rgba(0,0,0,0.54)`.
- Background interaction light: radial highlight following pointer inside the panel shell.

The native panel must never show square background artifacts around rounded corners.

### Header

Header content:

- Eyebrow: `Copy · Attach · Capture`
- Title: `Handy`
- Supporting copy: `Handy appears exactly where your attention already is.`
- Close button: icon-only, 40x40, rounded 14px.

Header behavior:

- Does not scroll independently.
- Does not absorb search focus.
- Close button dismisses Handy and returns focus to summon affordance only in prototype/browser. Native should return focus to the previously active app.

### Search Row

- Height: `54px`
- Layout: search icon, input, clear button, result count.
- Placeholder: `Search recent context`
- Result count: `N items`, updates with search/filter.
- Clear button appears only when search text exists.
- Focus ring: warm gold, subtle outer glow.
- Typing clears stale draft and closes peek.

Native search must remain the first responder after summon.

### Category Pills

Prototype categories:

- `All`
- `Code`
- `Visuals`
- `Links`
- `Files`
- `Thoughts`
- `Text`

Rules:

- Pills show live counts for the current search term.
- Active pill has filled gold background.
- Inactive pills are translucent dark chips.
- Pills use `aria-pressed` in prototype; native should expose selected state.
- Pill change clears stale draft and closes peek.

### Goal Row

Current prototype includes a goal input and a sharpen action:

- Label: `Goal`
- Default goal: `Implement the edge-aware summon panel without bringing back the old floating hand.`
- Sharpen action cycles through stronger goal statements in prototype.

Native v1 can keep goal as editable text, but real AI generation for sharpen is deferred.

### Context Cards

Card fields:

- `id`
- `type`
- `title`
- `preview`
- `source`
- `detail`
- `age`
- `accent`

Card visual:

- Width: `270px`
- Minimum height: `318px`
- Radius: `24px`
- Padding: `12px`
- Preview/media area min height: `124px`, radius `18px`
- Toolbar top/right: `16px`
- Selection mark top/left: `18px`

Default behavior:

- Actions are hidden by default.
- Toolbar appears on hover, focus-within, focus-visible, or selected state.
- Toolbar actions: `Use`/`Added`, `Peek`.
- Hover must not resize the card or rail.
- Current approved hover treatment keeps scroll geometry stable and animates media/toolbar, not the whole card.

Selected behavior:

- Border becomes accent-heavy.
- Selection mark appears as filled accent circle with check.
- Toolbar remains visible.
- Tray updates with count and type chips.

Native must not show every card action all the time.

### Context Type Variants

Text:

- Preview uses abstract line glyphs in prototype.
- Native should render text preview with 2-3 visible lines and source metadata.

Code:

- Monospace preview.
- Preserve line breaks where possible.
- Clamp content inside preview area; do not expand card height.

URL:

- Abstract URL line preview in prototype.
- Native should show title, domain/source app, and URL metadata.
- Favicon can be added later if it does not disrupt card density.

Image:

- Mock screenshot block in prototype.
- Native should use real thumbnail with stable aspect ratio and rounded crop.
- Large image preview belongs in peek, not the default card.

File:

- Extension badge in preview area.
- Show filename/title and path/source metadata.

Thought:

- Quote-like preview.
- Used for quick capture mental notes.

### Peek Preview

Peek is a temporary preview layer above the card rail.

Behavior:

- Opens from active/hovered/focused card.
- Uses dialog semantics in prototype with dynamic `aria-label`.
- Focus moves to primary peek action (`Added` or `Use context`).
- `Tab` and `Shift+Tab` loop inside Close, Use/Add, and Compose actions.
- Escape closes peek and returns focus to source card.
- Selection toggle inside peek must not pull focus back to the underlying card.
- Compose from peek closes peek first, then shows visible draft.

Native mapping:

- Use an overlay view inside the panel content, not a new macOS window.
- Do not resize the panel when peek appears.
- Treat peek as a focus scope.

### Selected Context Tray

Behavior:

- Shows `N selected`.
- Empty state: `Select context` with hint `Pick a card or peek one`.
- Shows up to 4 selected chips.
- Each chip can remove its item.
- Removing a chip restores focus to the next chip, or to the related visible card if the tray becomes empty.

Native v1 should implement chip overflow later; first slice may cap visible chips at 4.

### Intent Controls

Prototype intents:

- `Debug this`
- `Implement this`
- `Review this`
- `Explain this`
- `Turn into task`
- `Create goal`

Default intent:

- `Implement this`

Primary CTA behavior:

- Label `Compose` when no draft exists.
- Label `Copy prompt` after draft creation.
- Label `Copied` after copy feedback.
- Soft-disabled with `aria-disabled` in prototype; click still nudges missing requirements.

Native should visually explain missing requirements rather than silently disabling the button.

### Draft Preview

Draft preview:

- Floating surface above footer.
- Does not resize panel.
- Contains intent label, draft text, and `Copy prompt`/`Copied` button.
- Focus moves to draft copy action after compose.
- Copy keeps focus on refreshed copied action.
- Escape clears draft before dismissing Handy.

Native v1 can generate a deterministic prompt from selected mock data. Real prompt quality improvements can come later.

## Visual Tokens

Use these as native design token starting points:

```text
color.background.app = #111314
color.background.panel = rgba(20, 22, 22, 0.96)
color.background.card = rgba(13, 15, 15, 0.92)
color.background.cardHover = rgba(13, 15, 15, 0.96)
color.background.control = rgba(255, 255, 255, 0.055)
color.text.primary = #f4f1ea
color.text.secondary = rgba(244, 241, 234, 0.62)
color.text.muted = rgba(244, 241, 234, 0.38)
color.accent.primary = #d6b879
color.border.subtle = rgba(255, 255, 255, 0.11)
color.shadow.panel = rgba(0, 0, 0, 0.54)

radius.panel = 32
radius.card = 24
radius.media = 18
radius.search = 18
radius.control = 14-16
radius.pill = 999

space.xs = 6
space.sm = 8
space.md = 10-12
space.lg = 14-16
space.xl = 18
space.panel = 18-28

font.family.display = Geist, Avenir Next, SF Pro Display, system
font.family.mono = JetBrains Mono, SFMono-Regular, Menlo, monospace
font.size.caption = 11-12
font.size.body = 13-16
font.size.title = 30-42
font.weight.medium = 650
font.weight.semibold = 720
font.weight.bold = 760

ease.out = cubic-bezier(0.16, 1, 0.3, 1)
```

Pixel demo typography rules:

- Use the same resolved display font as the prototype machine. CSS family is `Geist, Avenir Next, SF Pro Display, system-ui, sans-serif`; record the actual resolved font before native pixel comparison.
- Use the same resolved mono font for code previews. CSS family is `JetBrains Mono, SFMono-Regular, Consolas, monospace`.
- Eyebrow: `12px`, weight `760`, letter spacing `0.96px`, uppercase.
- Title: `42px` at `1280x800`, line height `42.84px`, weight `720`.
- Attention copy: `14px`, line height `18.9px`, weight `400`.
- Card title: `17px`, line height `19.04px`, weight around `700`.
- Card body: `13px`, line height `18.85px`, weight `400`.
- Card code preview: `11px`, line height `18.7px`, mono weight `400`.
- Compose button: `16px`, weight `720`.
- Letter spacing is `0`/normal except the eyebrow.

## Motion Spec

All native animation should use transform and opacity where possible. Avoid animating layout, width, height, constraints, or window frame during content reveal.

Animation implementation policy:

- Treat GSAP as the prototype authoring tool and motion reference only.
- Do not embed GSAP, JavaScript animation runtime, or a `WKWebView` panel to reproduce these animations in the native app.
- Translate prototype timings, easings, staggers, and transform values into AppKit/Core Animation or SwiftUI primitives.
- Use AppKit/Core Animation for panel placement, summon/exit, hover, focus, peek, selected tray, and compose/copy feedback.
- Lottie or Rive may be used later for isolated decorative/vector states such as empty states or success marks, but not for panel positioning, keyboard focus flow, hover behavior, or core command interaction.

Reduced motion:

- Panel appears immediately at final opacity/scale.
- Content is visible without stagger.
- Selection, copy, invalid-state feedback should use direct state changes or very short fades.

### Summon Enter

Trigger:

- Global shortcut or prototype summon click/hotspot.

Values:

- Initial opacity: `0`
- Final opacity: `1`
- Initial scale: `0.96`
- Final scale: `1`
- Initial y offset: `18`
- Final y offset: `0`
- Duration: `0.42s`
- Ease: `expo.out` equivalent
- Transform origin: based on edge flip (`0%` or `100%` horizontally, `0%` or `100%` vertically)

Content reveal:

- Header/search/pills/goal/gallery/footer are `data-reveal` targets.
- Initial content opacity: `0`
- Initial content y: `12`
- Duration: `0.32s`
- Stagger: `0.045s`
- Cards enter with y `18`, scale `0.985` to `1`, duration `0.34s`, stagger `0.035s`.

Native mapping:

- Create/show panel at final computed frame first.
- Animate content/layer opacity and transform.
- Do not resize during reveal.
- Ensure interrupted enter settles all transforms to final values.

### Summon Exit

Values:

- Opacity: `1 -> 0`
- Scale: `1 -> 0.985`
- y offset: `0 -> 12`
- Duration: `0.18s`
- Ease: `power2.in` equivalent
- Anchor beam and attention pin fade over `0.12s`.

Close timing:

- Mark hidden after animation completes.
- Include a fallback completion guard so the panel cannot remain invisible but focusable.

### Reposition While Open

Prototype behavior:

- Attention anchor tracks pointer only while panel is closed.
- Once open, only explicit workspace click/hotspot repositions.
- Reposition uses FLIP-like animation from old frame to new frame:
  - duration `0.30s`
  - ease `expo.out`
  - panel scale `0.992 -> 1`
  - final transform is always reset to x/y `0`.

Native mapping:

- Do not continuously follow the mouse while open.
- Reposition only on explicit shortcut/click decision.

### Search and Filter Motion

- Result count animates y `4 -> 0`, opacity `0.62 -> 1`, duration `0.18s`.
- Active pill scale feedback: `0.94 -> 1`, duration `0.20s`.
- Gallery cards re-enter after filter redraw with y `18`, scale `0.985`, duration `0.32s`, stagger `0.035s`.
- Empty gallery uses a dashed framed state and no card animations.

Native mapping:

- Filtering must not resize the panel.
- Keep active item synced to the first visible result when prior active item disappears.

### Gallery Scroll Motion

- Trackpad vertical wheel over rail maps to horizontal scroll.
- Scroll duration: `0.26s`
- Ease: `expo.out`
- Rail uses hidden scrollbar and subtle edge fades.
- Edge fades recalculate after gallery redraw and panel settle.

Native mapping:

- Use horizontal collection/scroll view.
- Hide default scroller unless user settings require it.
- Preserve trackpad feel before adding real large data volumes.

### Card Hover and Focus

Current approved behavior:

- Card border/background/shadow change on hover/focus/selection.
- Card media animates y `0 -> -2`, scale `1 -> 1.012`, duration `0.16s`.
- Toolbar opacity `0 -> 1`, scale `0.96 -> 1`, duration `0.14s`.
- Whole-card hover no longer scales because scroll-container clipping and footer reachability are more important.

Native mapping:

- Use layer-backed card media and toolbar.
- Do not change card frame or collection item size on hover.
- Do not let hover clip card edges or hide footer actions.

### Selection Feedback

On select:

- Selection mark scale `0.72 -> 1`, duration `0.20s`.
- Selected count y/opacity feedback duration `0.18s`.
- Pulse travels from card to selected tray:
  - duration about `0.42s`
  - fades out by `0.16s`
  - tray chip scale `0.82 -> 1`, duration `0.24s`.

On deselect:

- Selection mark scale `1.12 -> 0.86`, duration `0.20s`.
- Selected stack scale `0.97 -> 1`, duration `0.18s`.

Native mapping:

- Selection must not shift card layout.
- Pulse is optional in the first native slice, but selected state and tray feedback are required.

### Compose and Copy Feedback

Compose:

- Primary CTA scale `0.96 -> 1`, duration `0.22s`.
- Draft preview opacity `0 -> 1`, y `10 -> 0`, scale `0.99 -> 1`, duration `0.26s`.
- Selected chips y `8 -> 0`, opacity `0.5 -> 1`, duration `0.24s`, stagger `0.035s`.
- Focus moves to draft copy action.

Copy:

- Draft action scale `0.92 -> 1`, duration `0.20s`.
- Primary CTA scale `0.94 -> 1`, duration `0.20s`.
- Draft y `3 -> 0`, duration `0.18s`.
- Copy label changes to `Copied`.

Invalid compose:

- Missing selection nudges selected tray x `-4 -> 0`, duration `0.20s`.
- Missing goal nudges goal input x `-4 -> 0`, duration `0.20s`.
- Primary CTA briefly scales/opacity feedback.

## Positioning Spec

Native v1 uses mouse position as the summon point.

Inputs:

- Current mouse location in global screen coordinates.
- Preferred panel size.
- Screen visible frame.
- Safe margin: `18px`.
- Gap from pointer: `18px`.

Algorithm:

1. Find the screen containing the mouse.
2. Use that screen's visible frame.
3. Prefer x = anchor.x + gap.
4. Prefer y = anchor.y + gap.
5. If right side would overflow, place left: anchor.x - panelWidth - gap.
6. If bottom would overflow, place above: anchor.y - panelHeight - gap.
7. Clamp x/y to visible frame inset by safe margin.
8. Set transform origin based on chosen side.
9. Draw the attention pin and a subtle beam from anchor to nearest panel edge.

Prototype constants:

- Safe margin: `18px`
- Pointer gap: `18px`
- Attachment clamp inside panel: `26px` from panel edges.
- Attention pin size: `10px`

Rules:

- Panel may cover nearby content, but must not cover in a way that feels detached from attention.
- Panel must never require dragging.
- Panel must not store a permanent user position.
- Multi-screen native behavior must use the screen containing the current mouse point.
- Full-screen behavior should use an auxiliary panel that can join full-screen spaces.

## Interaction State Machine

Native should implement these states:

```text
hidden
summoning
open
filtering
peeking
composing
copied
dismissing
```

Required transitions:

- Shortcut from `hidden` -> `summoning`.
- Summon animation complete -> `open`.
- Typing search -> `filtering`.
- Empty search with no preview/draft -> `open`.
- Opening peek -> `peeking`.
- Selecting/deselecting cards -> `composing` when selection non-empty.
- Compose with valid selection and goal -> `composing` with visible draft.
- Copy draft -> `copied`.
- Escape while peek open -> close peek and restore source card focus.
- Escape while draft exists -> clear draft and focus search.
- Escape while search exists -> clear search and focus search.
- Escape otherwise -> `dismissing`.
- Exit animation complete -> `hidden`.

Shortcut while visible:

- Prototype `h` shortcut reopens/repositions to current anchor.
- Native global shortcut while visible repositions Handy to the current mouse point and refocuses search.
- If the shortcut is pressed while the pointer remains inside Handy, dismiss instead of jittering in place.
- Do not add drag.

Outside click behavior:

- Native should dismiss on outside click after the first vertical slice is stable.
- Prototype does not fully model outside-click dismissal.

## Keyboard and Focus Contract

Initial focus:

- Search input after panel opens.
- Focus is guarded with multiple settle/fallback calls in prototype because animation timing can steal focus.

Search:

- `ArrowDown`: moves to active/current visible card.
- `Enter`: adds active result if not already selected; otherwise moves focus to active card.

Cards:

- `ArrowLeft` / `ArrowRight`: move between visible cards.
- `ArrowUp`: return to search.
- `Home` / `End`: jump to first/last visible card.
- `p`: open peek.
- `Enter` / `Space`: toggle selection.

Peek:

- Opens focus on primary action (`Added` or `Use context`).
- `Tab` / `Shift+Tab`: loop within close, selection, compose actions.
- `Escape`: close peek and restore source card focus.
- Toggle inside peek keeps focus on refreshed peek action.

Composition:

- `Enter` in goal input composes.
- `Command+Enter` / `Control+Enter`: run primary action from anywhere in the panel.
- If peek is open, primary action closes peek first, then composes/copies visibly.
- After compose, focus moves to draft copy action.
- After copy, focus remains on copied action.

Close:

- Closing panel sets summon affordance collapsed in prototype.
- Native should restore focus/activation to the previously active app rather than trapping focus in a hidden panel.

Accessibility expectations:

- Search has clear placeholder and native accessibility label.
- Pills expose selected state.
- Cards expose selected/pressed state and current active item.
- Peek exposes dialog semantics and dynamic label.
- Draft preview uses live-region-like feedback semantics.
- Reduced motion must be supported.
- Primary hit targets should be at least 40x40; edge/hotspot test affordances are 44x44 in prototype.

## Data and State Spec

Mock item fields currently used:

```text
id
type
title
preview
source
detail
age
accent
```

Native context item model should include:

```text
id
type: text | code | url | image | screenshot | file | thought
title
preview
content
sourceApp
sourceURL
createdAt
metadata
localAssetPath
sensitivity
syncState (reserved)
```

Sort order:

- Most recent first in native, with current active item preserved across filtering where possible.

Default prototype state:

- Active filter: `All`
- Active item: `ctx-code-position`
- Default selected items: positioning code and dark surface visual reference.
- Default intent: `Implement this`
- Default goal: edge-aware summon panel implementation goal.

No-results state:

- `No matching context. Keep typing or switch filters.`

Selected tray:

- Show up to 4 selected chips in native v1.
- Keep full selected set internally.

## Component Inventory

Native components:

- `SummonPanelController`
- `PanelPositioner`
- `HandyPanelView`
- `PanelHeaderView`
- `SearchHeaderView`
- `CategoryPillBarView`
- `GoalRowView`
- `ContextGalleryView`
- `ContextCardView`
- `HoverToolbarView`
- `PeekPreviewView`
- `SelectedContextTrayView`
- `IntentPickerView`
- `ComposerPreviewView`
- `PromptComposer`
- `CopyHandoffController`

Use AppKit for:

- Global shortcut.
- `NSPanel` lifecycle.
- multi-screen positioning.
- outside click and Escape dismissal.
- precise layer-backed animation where SwiftUI is too coarse.

SwiftUI may be used inside the panel only if it does not compromise focus, hover, animation timing, or window stability.

## Native Implementation Notes

Recommended primitives:

- Window: borderless `NSPanel`.
- App activation: do not steal more focus than needed.
- Placement: AppKit visible frame plus global mouse coordinates.
- Motion: layer-backed `NSView`, `CABasicAnimation`, `CASpringAnimation`, `CAAnimationGroup`, scoped `NSAnimationContext`, or SwiftUI `withAnimation` only where focus timing remains reliable.
- Content: AppKit views first for reliable focus and hover; SwiftUI acceptable for static subviews.
- Storage: defer until vertical slice passes.
- Capture: defer until vertical slice passes.
- iCloud: do not implement; reserve fields later.

Do not:

- reintroduce native floating hand.
- make a persistent desktop widget.
- use a vertical clipboard-history list as the main UI.
- show all actions on every card by default.
- add drag-to-position in v1.
- embed the GSAP prototype as a `WKWebView`.
- add Lottie/Rive to drive core panel interaction.
- animate window frame during content reveal.
- resize the root panel during hover, selection, filtering, peek, or draft.

## Native Vertical Slice Acceptance

Before real persistence/capture/handoff, native must pass:

- [ ] Global shortcut opens the panel.
- [ ] Panel appears near mouse position.
- [ ] Panel flips and clamps near screen edges.
- [ ] Header includes `Copy · Attach · Capture`, `Handy`, and the attention promise.
- [ ] Mock context cards render with approved density.
- [ ] Search focuses after open.
- [ ] Search filters cards and updates pill counts.
- [ ] Horizontal rail scrolls and edge fades work.
- [ ] Footer compose controls remain reachable after hover and scroll.
- [ ] Enter animation matches approved timing closely.
- [ ] Exit animation has no flicker and leaves no focusable hidden panel.
- [ ] Card hover reveals actions quietly and does not clip or resize layout.
- [ ] Selection updates tray without layout jump.
- [ ] Peek opens as a focus scope and closes back to source card.
- [ ] Compose shows visible draft and focuses copy action.
- [ ] Copy shows copied feedback.
- [ ] Escape follows the layered dismissal order.

If this slice fails the approved feel, stop and tune motion/focus before adding more product surface.

## Verification Checklist

Compare prototype and native side by side:

- [ ] `960x720` screenshot matches layout density.
- [ ] `1280x800` screenshot matches layout density.
- [ ] `1512x982` screenshot matches layout density.
- [ ] Summon recording shows equivalent panel timing.
- [ ] Exit recording shows no flicker.
- [ ] Edge summon recording shows stable flip/clamp.
- [ ] Hover recording shows no layout shift and no clipped toolbar/card edge.
- [ ] Selection recording shows no layout shift.
- [ ] Peek recording shows focus stays inside peek and returns to source card.
- [ ] Draft recording shows compose/copy focus flow.
- [ ] Actions remain hidden until hover/focus/selection.
- [ ] Text does not overlap or clip.
- [ ] Panel does not show square background artifacts.
- [ ] Panel does not resize during hover, filtering, selection, peek, or draft.
- [ ] Shortcut interruption during enter/exit does not produce stuck state.
- [ ] Trackpad scrolling feels close to prototype.
- [ ] Empty and no-results states match prototype.
- [ ] Reduced motion path is usable.

Fidelity tolerances:

- Pixel-critical geometry: within `2px` for panel frame, shell padding, section y positions, card size, rail gap, overlay frame, and footer position.
- Major spacing: within `2px`.
- Text baseline and title block height: within `3px`, after resolved fonts are locked.
- Panel size: within `4px` width/height for the approved demo viewports.
- Corner radius: within `2px`.
- Animation duration: within `25ms`.
- Stagger timing: within `10ms`.
- Card count visible per viewport: same whole-card count and same partial-card direction.
- Color: within perceptual match; resolve CSS `color-mix()` values into sRGB swatches for native constants before implementation.
- Shadow/material: visually close; exact blur is platform-dependent, but perceived panel separation must match the approved screenshots.

## Final Prototype Review Pack

Before opening the native implementation thread, capture these stable files:

- `prototype-approved-flow.mp4`
- `prototype-960x720.png`
- `prototype-1280x800.png`
- `prototype-1512x982.png`
- `prototype-edge-left.png`
- `prototype-edge-right.png`
- `prototype-edge-bottom.png`
- `prototype-hover-card.png`
- `prototype-selection-tray.png`
- `prototype-peek-preview.png`
- `prototype-draft-copy.png`
- `prototype-empty-state.png`
- `prototype-filtering-state.png`

If a state is intentionally deferred, mark it as deferred in this document before native work starts.

## Native Handoff Prompt Template

Use this prompt to start the native implementation thread:

```text
Read /Users/justin/workspace/handy/docs/prd.md,
/Users/justin/workspace/handy/docs/technical-design.md,
/Users/justin/workspace/handy/docs/implementation-tasks.md,
and /Users/justin/workspace/handy/docs/prototype-to-native-spec.md.

The GSAP prototype direction is approved. Preserve:
"Handy appears exactly where your attention already is."
Use "Copy · Attach · Capture" as the exact visible eyebrow and
"Copy / Attach / Capture" as the product action grammar.
Use GSAP only as the prototype motion reference. Implement native motion with
AppKit/Core Animation/SwiftUI primitives; do not embed GSAP, JavaScript
animation runtime, or a WKWebView panel.

Build only the native vertical slice first:
global shortcut, mouse-position summon, edge-aware AppKit NSPanel,
mock context cards, staged enter/exit animation, search/pills/gallery,
hover toolbar, peek preview, selection tray, compose draft, copy feedback,
and Escape dismissal.

Do not implement persistence, real capture, iCloud readiness, settings,
or Codex handoff automation until the native slice matches the approved
prototype feel.

Do not restore the old native floating-hand implementation.
```
