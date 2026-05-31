# Handy Technical Design

## Product Slogan

Handy appears exactly where your attention already is.

## Architecture Decision

The previous native floating-hand implementation is discarded.

The new architecture is prototype-first:

1. Build a GSAP motion prototype to validate the summon panel, gallery layout, and interaction grammar.
2. Translate the approved motion spec into a native macOS implementation.
3. Preserve local-first data principles, but do not implement iCloud sync in v1.

## Phase 1: GSAP Prototype

### Purpose

The prototype exists to define premium motion and interaction quality before committing to AppKit/SwiftUI details.

### Stack

- Vite
- TypeScript
- GSAP
- CSS custom properties
- Static mock data representing Handy context items

### Prototype Surfaces

- Summon panel
- Search input
- Category pills
- Horizontal context gallery
- Selected context tray
- Intent picker
- Hover toolbar

### Prototype Motion Specs

Panel enter:

- Start: opacity 0, scale 0.96, y 24
- End: opacity 1, scale 1, y 0
- Duration target: 380-460ms
- Easing: spring-like, no cartoon bounce

Panel exit:

- Start: opacity 1, scale 1, y 0
- End: opacity 0, scale 0.98, y 12
- Duration target: 160-220ms

Content reveal:

- Search appears first.
- Category pills delay by 50-70ms.
- Cards stagger by 30-45ms each.
- Selected tray and intent controls appear after cards settle.

Card hover:

- Scale 1.0 to 1.025.
- Translate y -4.
- Toolbar opacity 0 to 1 and scale 0.96 to 1.
- Duration target: 120-180ms.

### Prototype Validation

- Record screenshots or short videos.
- Verify 60fps feel manually.
- Verify no text overlap at 960x720, 1280x800, and 1512x982.
- Verify edge-aware panel flipping.

## Phase 2: Native macOS App

### Native Stack

- Swift
- AppKit for windowing and global events
- SwiftUI for panel content where it does not compromise motion
- Core Data or SQLite for local context storage
- Carbon Event HotKey or native event monitor for global shortcut
- Accessibility APIs for future focused-caret positioning

### Native Architecture

Modules:

- `Shortcut`: global summon shortcut.
- `SummonPanel`: AppKit panel lifecycle and positioning.
- `ContextRepository`: local context item persistence.
- `Capture`: clipboard, screenshot, file, URL, and quick thought capture.
- `Composer`: selected context and intent prompt generation.
- `Handoff`: Codex/copy fallback destination.
- `DesignSystem`: native tokens, spacing, materials, and motion constants.

### Window Model

There is no persistent floating mascot.

Handy uses one transient summon panel:

- Borderless `NSPanel`.
- Can join all spaces.
- Full-screen auxiliary.
- Appears near mouse position in v1.
- Flips to remain inside the visible screen frame.
- Closes on Escape, outside click, or successful action when appropriate.

Future:

- Use Accessibility to position near focused text caret or focused element bounds.
- Fall back to mouse position when Accessibility is unavailable.

### Positioning Algorithm

Inputs:

- Mouse location in global screen coordinates.
- Panel preferred size.
- Active screen visible frame.
- Safe margin.

Algorithm:

1. Prefer panel origin at mouse + `(16, -16)` in user attention direction.
2. If panel would overflow right edge, flip left.
3. If panel would overflow bottom edge, flip above.
4. Clamp to visible frame with 16px margin.
5. Store no permanent position; this is contextual, not draggable.

### Interaction State Machine

States:

- `hidden`
- `summoning`
- `open`
- `filtering`
- `composing`
- `dismissing`

Rules:

- Shortcut from `hidden` enters `summoning`.
- Escape from any visible state enters `dismissing`.
- Search input changes stay in `filtering`.
- Selecting context enters or updates `composing`.
- Successful copy/handoff may dismiss after feedback.
- No drag state in v1.

### Context Item Model

Fields:

- `id`
- `type`: text, code, url, image, screenshot, file, thought
- `title`
- `preview`
- `content`
- `sourceApp`
- `sourceURL`
- `createdAt`
- `metadata`
- `localAssetPath`
- `sensitivity`
- `syncState` reserved for future iCloud

### Local Storage

v1:

- Local-only.
- Keep most recent 100 by default.
- Configurable limit remains a future setting.
- Asset cache for screenshots/images/files.

Future iCloud readiness:

- Keep stable item IDs.
- Keep `syncState`, `cloudRecordID`, `originDeviceID`, `updatedAt`.
- Do not implement CloudKit until product interaction is validated.

### Composer

The composer turns selected items plus an intent into structured output.

Prompt shape:

```text
Intent: <intent>

Context:
1. <typed context block>
2. <typed context block>

Request:
<generated task instruction>
```

Intent templates:

- Debug
- Implement
- Review
- Explain
- Summarize
- Create goal
- Draft PRD

### Handoff

v1 destinations:

- Copy composed prompt to clipboard.
- Optional Codex app activation and paste when supported.

Fallback:

- If app activation or paste fails, keep prompt in clipboard and show clear feedback.

### Native Motion Translation

Native implementation should mimic the GSAP-approved spec:

- AppKit window frame animation for panel position/size only when necessary.
- SwiftUI/CALayer transforms for opacity, scale, y offset, and card hover.
- Avoid resizing root SwiftUI view during hover.
- Avoid window frame mutation during content animation.

Recommended native tools:

- `NSAnimationContext` for panel frame/alpha.
- `CASpringAnimation` for layer-backed transform.
- SwiftUI `.spring(response:dampingFraction:blendDuration:)` for internal content.

### Testing Strategy

Unit tests:

- Positioning flips and clamps.
- State machine transitions.
- Context filtering.
- Prompt composition.
- Sensitivity handling.

Integration tests:

- Clipboard capture into repository.
- Intent composition with mixed item types.
- Handoff fallback writes prompt to pasteboard.

Manual verification:

- Shortcut summon at mouse position.
- Edge flipping.
- Search typing.
- Card hover.
- Selection composition.
- Escape close.
- Codex fallback.

## Implementation Guardrails

- Do not rebuild the persistent floating hand.
- Do not expose row action buttons by default.
- Do not start with iCloud sync.
- Do not overfit the native app before the prototype validates motion.
- Do not accept flicker as a beta issue; motion quality is core product quality.
