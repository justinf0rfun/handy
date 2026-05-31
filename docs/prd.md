# Handy PRD

## Product Slogan

Handy appears exactly where your attention already is.

## Decision

Handy is no longer a persistent floating hand or a general clipboard manager.

The new product direction is a summonable AI context composer for builders. It appears at the user's current point of attention, helps them capture scattered context, compose it into useful intent, and send it to AI tools such as Codex.

## Positioning

Handy is a contextual command panel for turning copied text, screenshots, files, links, thoughts, and code into useful AI instructions.

It should feel closer to a premium command surface than a clipboard history list.

## Target Users

- AI-native builders using Codex, Claude Code, Cursor, ChatGPT, or similar tools.
- Indie developers moving context between browser, terminal, IDE, screenshots, and AI chat.
- Product builders who frequently capture ideas, references, bugs, code snippets, and design inspiration.

## Core User Promise

When a user needs context, Handy appears where their attention already is, with the right recent material and the right AI intent ready to compose.

## Non-Goals

- Do not compete as a generic beautiful clipboard manager.
- Do not keep a persistent desktop mascot or floating hand as the primary interaction.
- Do not make the first version an iCloud sync product.
- Do not expose every action on every item by default.
- Do not build a full note-taking system.

## Primary Interaction

1. User presses a global shortcut.
2. Handy appears near the current mouse position in v1.
3. Later versions may prefer the focused text caret or focused UI element when Accessibility permission is available.
4. User searches, filters, selects recent context, captures a thought, or chooses an AI intent.
5. Handy composes a prompt or context bundle.
6. User sends to Codex or copies the composed context.
7. Handy disappears.

## Killer Workflows

### 1. Summon at Attention

User presses the shortcut while looking at code, browser content, a screenshot, or an error message.

Acceptance:

- Panel appears near the mouse position.
- Panel flips away from screen edges.
- Panel can be dismissed with Escape.
- Panel does not require dragging.
- Panel feels stable and intentional.

### 2. Capture Anything

User can quickly capture:

- Current clipboard text
- URL
- Code snippet
- Screenshot/image
- File path
- Quick thought

Acceptance:

- Captured items become context cards.
- Sensitive content is ignored or warned about by default.
- Items remain local-first in v1.

### 3. Compose Context

User can search and select several context cards, then assemble them into a structured AI request.

Acceptance:

- Recent context is shown as a premium visual gallery.
- Search and category pills are first-class.
- Selection state is clear.
- The panel shows selected context count.
- Actions remain quiet until needed.

### 4. Send With Intent

User chooses an intent such as:

- Debug this
- Implement this
- Review this code
- Explain this
- Turn this into a task
- Create `/goal`

Acceptance:

- Handy generates a high-quality prompt from selected context.
- Codex handoff is available but not the whole product.
- If automatic paste is unavailable, the composed prompt is copied and the fallback is clear.

## Visual Direction

Handy should feel premium, smooth, and quiet.

Reference qualities:

- Dark high-contrast main panel.
- Large rounded surface.
- Search and category pills near the top.
- Horizontal or grid-like media cards, not a plain vertical log.
- Motion-first reveal with staged content.
- Actions hidden until hover, focus, or selection.
- Strong visual previews for screenshots, URLs, code, and files.

## Motion Direction

Motion is a product feature, not polish.

Principles:

- The panel appears with a spring-like summon animation.
- The panel has one stable visual anchor.
- Container and content animate separately.
- Items enter with staggered fade/slide.
- Hover states lift softly.
- No flicker, sudden resize, or drag-triggered expansion.

## Prototype First

Before native implementation, build a GSAP web prototype to lock the interaction language.

Prototype must prove:

- Summon animation.
- Edge-aware positioning.
- Search and pills layout.
- Horizontal card gallery.
- Card hover and toolbar reveal.
- Selection and intent composition.
- Close/dismiss animation.

## Native App Scope

After the prototype is approved, implement the native macOS app.

Native v1 includes:

- Global shortcut.
- Mouse-position summon.
- Local clipboard/context repository.
- Quick capture.
- Context selection.
- Intent prompt generation.
- Codex handoff/copy fallback.

## Success Criteria

Handy is successful if a builder can:

- Summon it without changing focus.
- Find or capture context in under 3 seconds.
- Compose useful AI context without manual copy-paste assembly.
- Send or copy a prompt that is meaningfully better than raw clipboard text.

## Risks

- Generic clipboard products can copy simple AI handoff features.
- Native motion quality may lag behind the GSAP prototype.
- Accessibility-based caret positioning may be unreliable across apps.
- Overbuilding visual history can distract from AI context composition.

## Product Bet

The bet is not that Handy stores clipboard history better.

The bet is that AI builders need a fast, summonable context composer that appears exactly where their attention already is.
