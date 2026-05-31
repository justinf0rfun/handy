# Handy Implementation Tasks

## Product Slogan

Handy appears exactly where your attention already is.

## Current Status

The old native floating-hand implementation has been removed. The approved direction is a transient macOS summon panel that appears near the current attention point.

Prototype readiness:

- GSAP prototype: complete enough for native handoff.
- Native executable spec: `/Users/justin/workspace/handy/docs/prototype-to-native-spec.md`
- Reference pack: `/Users/justin/workspace/handy/prototype/reference-pack/2026-05-31/`
- Reference zip: `/Users/justin/workspace/handy/prototype/reference-pack/handy-prototype-reference-pack-2026-05-31.zip`

Native implementation rule:

- Build the native vertical slice first with mock data only.
- Do not implement persistence, real capture, iCloud, settings, or Codex handoff automation until the slice matches the approved prototype.
- Do not restore the old native floating-hand behavior.
- Do not embed GSAP, JavaScript animation runtime, or a `WKWebView` panel.

## Milestone 0: Reset and Prototype

### HDY-R000 — Repository Reset

- Status: Done
- Type: Local

Acceptance:

- [x] Old implementation is removed.
- [x] Product direction is reset to summon-panel Handy.
- [x] Core docs include the attention promise.

### HDY-P001 — Prototype Scaffold

- Status: Done
- Type: Prototype

Acceptance:

- [x] Vite + TypeScript prototype exists under `prototype/`.
- [x] GSAP is installed.
- [x] Mock data covers text, code, URL, image, file, and thought.

### HDY-P002 — Summon Panel Motion

- Status: Done
- Type: Prototype

Acceptance:

- [x] Panel enter/exit animation exists.
- [x] Motion uses opacity, scale, and y offset.
- [x] Settled panel has no hidden transform drift.

### HDY-P003 — Premium Panel Visual System

- Status: Done
- Type: Prototype

Acceptance:

- [x] Panel reads as a premium command surface.
- [x] Search, pills, gallery, selected tray, intent, and compose controls exist.
- [x] Card actions are hidden until hover, focus, or selection.

### HDY-P004 — Card Gallery Motion

- Status: Done
- Type: Prototype

Acceptance:

- [x] Cards enter with stagger.
- [x] Hover reveals toolbar.
- [x] Current hover treatment does not clip card edges or hide footer actions.

### HDY-P005 — Edge-Aware Positioning Prototype

- Status: Done
- Type: Prototype

Acceptance:

- [x] Mouse-position summon is simulated.
- [x] Panel flips and clamps near viewport edges.
- [x] Attention pin and beam connect summon point to panel.

### HDY-P006 — Prototype Review Pack

- Status: Done
- Type: Documentation/Assets

Acceptance:

- [x] Native spec is complete.
- [x] Reference screenshots are generated.
- [x] Approved-flow recording is generated.
- [x] Computed measurement and font JSON files are generated.

## Milestone 1: Native Vertical Slice

Goal: reproduce the approved prototype as a native macOS demo with mock data and pixel-level reference matching.

### HDY-N001 — Native Project Scaffold

- Status: Done
- Type: Implementation

Build:

- Create the macOS app project.
- Choose AppKit-first structure for the panel and focus-critical controls.
- Add a test target or minimal verification target.
- Ensure there is no persistent floating hand, mascot, or desktop widget surface.

Acceptance:

- [x] App builds and launches locally.
- [x] Tests or verification target run.
- [x] No old floating-hand implementation exists.
- [x] The app can run without prototype/web dependencies.

### HDY-N002 — Reference Data and Design Constants

- Status: Done
- Type: Implementation

Build:

- Port prototype mock data into native fixtures.
- Port visual tokens, dimensions, typography, accents, and motion constants from `prototype-to-native-spec.md`.
- Load or reference `/prototype/reference-pack/2026-05-31/computed-measurements-1280x800.json`.
- Define the exact visible eyebrow as `Copy · Attach · Capture`.

Acceptance:

- [x] Mock data ids match the prototype ids.
- [x] Default selected ids are `ctx-code-position` and `ctx-image-surface`.
- [x] Default intent is `Implement this`.
- [x] Default goal matches the prototype.
- [x] Constants can be compared against the reference pack.

### HDY-N003 — Global Shortcut and Panel Lifecycle

- Status: Done
- Type: Implementation

Build:

- Register a global shortcut.
- Create a borderless transient `NSPanel`.
- Show Handy without stealing more app focus than needed.
- Restore activation/focus to the previously active app on dismiss where possible.
- Add Escape dismissal.

Acceptance:

- [x] Shortcut opens Handy while another app is focused.
- [x] Search becomes first responder after open.
- [x] Escape dismisses the panel when no higher-priority layer is open.
- [x] No hidden-but-focusable panel remains after close.
- [x] Shortcut while visible follows the spec: reposition from outside Handy, dismiss when pointer is inside Handy.

### HDY-N004 — Edge-Aware Positioning

- Status: Done
- Type: Implementation

Build:

- Use current mouse position as the summon point.
- Find the screen containing that point.
- Use that screen's visible frame.
- Flip and clamp panel inside the visible frame.
- Draw attention pin and subtle beam.
- Support top-left, top-right, bottom-left, and bottom-right edge cases.

Acceptance:

- [x] Panel appears near the mouse attention point.
- [x] Panel never overflows the visible frame.
- [x] Transform origin follows the chosen flip side.
- [x] Attention pin/beam attach to the nearest panel edge.
- [x] Four edge screenshots match the reference pack within tolerance.

### HDY-N005 — Panel Shell and Pixel Layout

- Status: Done
- Type: Implementation

Build:

- Implement the panel shell, header, close button, search row, pills, goal row, gallery area, selected tray, intent picker, and compose button.
- Match `1280x800 @1x` measurements first.
- Support `960x720` and `1512x982` after the primary layout is stable.
- Keep footer reachable in all states.

Acceptance:

- [x] Header copy exactly matches `Copy · Attach · Capture`, `Handy`, and the attention promise.
- [x] 1280x800 panel geometry matches the reference within pixel tolerance.
- [x] Footer compose controls remain visible and usable.
- [x] The shell has rounded corners without square artifacts.
- [x] No root panel resize occurs during hover, filtering, selection, peek, or draft.

### HDY-N006 — Native Motion Translation

- Status: Done
- Type: Implementation

Build:

- Translate GSAP enter/exit, content reveal, card entrance, filter redraw, hover, selection, peek, draft, copy, and invalid-compose feedback into AppKit/Core Animation or SwiftUI primitives.
- Animate transforms and opacity rather than layout.
- Add reduced-motion behavior.

Acceptance:

- [x] Enter timing, y offset, scale, and stagger match the reference closely.
- [x] Exit has no flicker.
- [x] Hover animates card media and toolbar, not the whole card frame.
- [x] Selection and compose feedback do not shift layout.
- [x] Reduced motion remains usable.

### HDY-N007 — Search, Pills, and Horizontal Gallery

- Status: Done
- Type: Implementation

Build:

- Implement search filtering over mock context.
- Implement category pills with live counts.
- Render horizontal card gallery.
- Implement hidden scrollbar and edge fades.
- Map vertical wheel/trackpad intent to horizontal rail scroll where appropriate.
- Add no-results state.

Acceptance:

- [x] Search focuses after summon.
- [x] Search text filters cards and updates pill counts.
- [x] Pill changes clear stale draft and close peek.
- [x] Horizontal rail scrolls smoothly.
- [x] Empty state matches reference screenshot.
- [x] Filtering does not resize the panel.

### HDY-N008 — Card States, Hover Toolbar, and Selection Tray

- Status: Done
- Type: Implementation

Build:

- Implement card visual variants for text, code, URL, image, file, and thought.
- Implement active, hover, focus, selected, and default states.
- Reveal toolbar only on hover, focus, or selected state.
- Implement select/deselect and selected tray chips.
- Implement chip removal focus restoration.

Acceptance:

- [x] Card size, media area, metadata, title, preview, and footer match reference.
- [x] Toolbar is hidden at rest and visible on hover/focus/selection.
- [x] Hover does not clip the card or toolbar.
- [x] Selection mark and selected border match reference.
- [x] Selected tray updates without layout jump.

### HDY-N009 — Peek Preview Focus Scope

- Status: Done
- Type: Implementation

Build:

- Implement peek as an overlay inside the panel, not a separate window.
- Focus primary peek action on open.
- Trap/loop Tab inside peek controls while peek is open.
- Restore focus to the source card on close.
- Compose from peek should close peek first, then show visible draft.

Acceptance:

- [x] Peek frame matches `prototype-peek-preview.png`.
- [x] Peek does not resize the root panel.
- [x] Escape closes peek before clearing draft/search or dismissing panel.
- [x] Toggle inside peek keeps focus in peek.
- [x] Compose from peek creates visible draft and moves focus to copy action.

Note:

- Handy routes peek keyboard actions through an internal focus scope and visible focus ring. The native verification path opened peek, Tab-looped to `Compose with this`, created the draft, moved the visible focus ring to `Copy prompt`, and copied via keyboard activation. System accessibility can still report the underlying SwiftUI search field while Handy's internal focus scope owns the action route.

### HDY-N010 — Compose, Copy, and Layered Escape Flow

- Status: Done
- Type: Implementation

Build:

- Implement intent picker.
- Implement deterministic draft text from selected mock items and goal.
- Implement draft preview overlay.
- Implement `Copy prompt` and `Copied` feedback.
- Implement primary action from anywhere with Command+Enter / Control+Enter.
- Implement layered Escape: close peek, clear draft, clear search, dismiss panel.

Acceptance:

- [x] Compose requires selected context and a non-empty goal.
- [x] Draft preview matches reference position and size.
- [x] Focus moves to draft copy action after compose.
- [x] Copy feedback updates draft button and primary CTA.
- [x] Escape order matches the spec exactly.

### HDY-N011 — Pixel Verification Pack

- Status: Done
- Type: QA/Documentation

Build:

- Capture native screenshots for the same states as the reference pack.
- Capture a native approved-flow recording.
- Compare native screenshots against prototype screenshots side by side.
- Document known acceptable differences such as material blur and font antialiasing.

Acceptance:

- [x] Native `1280x800` screenshot matches key geometry within tolerance.
- [x] Native `960x720` and `1512x982` screenshots are checked.
- [x] Four edge summon screenshots are checked.
- [x] Hover, peek, draft, copied, filtering, empty, and scroll states are checked.
- [x] Remaining pixel mismatches are documented or fixed.

Note:

- Native screenshots and notes live in `/Users/justin/workspace/handy/native-verification/`.
- The native approved-flow recording is `/Users/justin/workspace/handy/native-verification/native-approved-flow.mov`.

## Milestone 2: Deferred Product Work

These tasks are intentionally blocked until the native vertical slice passes.

### HDY-D001 — Local Context Repository

- Status: Deferred
- Type: Implementation

Scope:

- Persist context items locally.
- Add retention policy.
- Reserve iCloud sync fields.

### HDY-D002 — Capture Sources

- Status: Deferred
- Type: Implementation

Scope:

- Clipboard text/code/URL capture.
- Image/screenshot capture.
- File path capture.
- Quick thought capture.
- Sensitive content handling.

### HDY-D003 — Codex / Clipboard Handoff Automation

- Status: Deferred
- Type: Implementation

Scope:

- Copy composed prompt reliably.
- Optional Codex activation and paste.
- Never auto-submit.
- Clear fallback when automation is unavailable.

### HDY-D004 — Settings, Sync, and Beta Hardening

- Status: Deferred
- Type: Product/QA

Scope:

- User settings.
- Shortcut configurability.
- iCloud or sync readiness.
- Beta packaging and release hardening.

## Recommended Execution Order

1. HDY-N001 — Native Project Scaffold
2. HDY-N002 — Reference Data and Design Constants
3. HDY-N003 — Global Shortcut and Panel Lifecycle
4. HDY-N004 — Edge-Aware Positioning
5. HDY-N005 — Panel Shell and Pixel Layout
6. HDY-N006 — Native Motion Translation
7. HDY-N007 — Search, Pills, and Horizontal Gallery
8. HDY-N008 — Card States, Hover Toolbar, and Selection Tray
9. HDY-N009 — Peek Preview Focus Scope
10. HDY-N010 — Compose, Copy, and Layered Escape Flow
11. HDY-N011 — Pixel Verification Pack

Only after HDY-N011 passes should deferred product work begin.
