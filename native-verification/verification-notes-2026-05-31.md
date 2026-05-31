# Handy Native Verification Notes - 2026-05-31

## Commands

- `swift test`
- `./script/build_and_run.sh --verify`
- Native demo screenshots captured with `screencapture`.
- Native approved-flow recording captured with `screencapture -x -v`.
- 2026-05-31 follow-up: activated Finder/Desktop after opening Handy and confirmed the Handy window remained visible via `CGWindowList`.
- 2026-05-31 rerun: found one stale Handy process still running from `dist/Handy.app` after the `dist/` directory had been removed. Relaunched with `./script/build_and_run.sh --verify`, which now prints the running PID and bundle path.
- 2026-05-31 final rerun: relaunched latest native bundle with `Handy running pid=38101 bundle=/Users/justin/workspace/handy/dist/Handy.app`.

## Captured Native States

- `native-default-window-latest.png`
- `native-hover-window.png`
- `native-selection-tray-window.png` is represented by the default selected state.
- `native-scroll-window.png`
- `native-peek-window.png`
- `native-draft-window.png`
- `native-copied-window.png`
- `native-filter-window.png`
- `native-empty-window.png`
- `native-edge-top-left-full.png`
- `native-edge-top-right-full.png`
- `native-edge-bottom-left-full.png`
- `native-edge-bottom-right-full.png`
- `native-after-finder-activation-full.png`
- `native-polish-window.png`
- `native-polish-full.png`
- `native-960x720-window.png`
- `native-1512x982-window.png`
- `native-peek-compose-copy-focus-full.png`
- `native-approved-flow.mov`

## Geometry Check

- Native visual panel window: `760 x 775` points.
- Reference shell measurement: `760 x 775`.
- Reference panel box measurement: `760 x 764`.
- `native-960x720-window.png` and `native-1512x982-window.png` were captured from the native viewport override path and checked for footer reachability, root panel stability, and card/gallery containment.
- Footer remains visible in default, hover, peek, draft, copied, filter, empty, scroll, and edge states.
- Peek and draft are overlays inside the root panel and do not resize the panel window.
- Four edge demo states clamp the panel inside the visible display frame. The top-left full screenshot shows the attention pin and beam attached to the panel edge.

## Interaction Check

- Global shortcut: `Control + Option + Space`.
- Shortcut opens near the current mouse position.
- Shortcut while visible dismisses when the pointer is inside Handy; otherwise it repositions to the current mouse point.
- Clicking another app/window no longer dismisses Handy. Outside-click dismissal is intentionally disabled for this slice because it conflicts with the attention-at-current-workflow behavior.
- Current verified launch after rerun: `Handy running pid=38101 bundle=/Users/justin/workspace/handy/dist/Handy.app`.
- Search is focused after summon.
- Escape order: close peek, clear draft, clear search, dismiss panel.
- Command+Enter or Control+Enter runs the primary compose/copy action.
- Copy writes the deterministic draft to `NSPasteboard.general` and changes the CTA to `Copied`.
- Search ArrowDown moves into the active card. Card ArrowLeft/ArrowRight, Home/End, Enter/Space, and `p` are routed through the panel state machine.
- Vertical wheel intent over the gallery scrolls the horizontal rail while preserving footer access.
- Peek has an internal Handy focus target ring for Close, Use context, and Compose with this. The verified path opened peek with `p`, Tab-looped to `Compose with this`, composed a draft, moved the visible ring to `Copy prompt`, and copied with Space. System accessibility focus may still report the underlying search field in the current SwiftUI/AppKit bridge; the key route is handled by Handy state and the visible focus ring.

## Known Acceptable Differences

- Font rasterization uses native Avenir Next/system rendering instead of browser-resolved Geist.
- Picker and text field controls use native macOS rendering, so antialiasing and select affordance differ from the browser prototype.
- Material blur is approximated with a dark native tint plus gradient, border, and shadow. It is intentionally not a WebKit backdrop-filter clone.
- Screenshots were captured on a Retina display, so window captures are `2x` bitmap scale.
