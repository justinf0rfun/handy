# Handy GSAP Prototype Notes

Question: what should Handy feel like when it appears exactly where attention already is?

Scope covered:

- HDY-P001: Vite, TypeScript, GSAP scaffold with static context data.
- HDY-P002: GSAP summon enter and exit timelines.
- HDY-P003: Dark command surface with search, category pills, card gallery, selected tray, and intent picker.
- HDY-P004: Staggered card entrance, hover lift, and quiet toolbar reveal.
- HDY-P005: Mouse-position summon with edge-aware flip and safe-margin clamp.

Filtering polish:

- Category pills show live result counts for the current search term.
- Pills expose `aria-pressed` so the active filter is explicit.
- Search has a quiet clear affordance once text is entered.
- Search and filter changes clear stale drafts and close peek previews so the visible context stays authoritative.
- Filtering keeps the keyboard/peek active item aligned to the first visible card when the previous active item disappears.
- The visible keyboard/peek target carries a quiet active card state and `aria-current`.
- From search, `ArrowDown` moves directly into the active result card and `Enter` adds the active result without removing already-selected context.
- Direction-key, focus, peek, and selection paths share one active-card sync so visual focus and `aria-current` do not drift apart.
- From a result card, `ArrowUp` returns to search and `Home` / `End` jump to the first or last visible result.
- Opening peek moves focus into the preview action layer, and closing peek restores focus to the source card.
- Toggling context inside peek keeps focus on the refreshed peek action instead of dropping behind the overlay.
- Peek exposes dialog semantics and loops `Tab` / `Shift+Tab` within its close, selection, and compose actions.
- Mouse and keyboard toggles inside peek use the same focus behavior; selection updates no longer pull focus back to the underlying card.

Composition polish:

- Empty selection shows a small inline hint in the selected tray instead of leaving the disabled primary action unexplained.
- Removing a selected tray chip restores focus to the next chip, or to the related visible card when the tray becomes empty.
- The primary CTA uses `aria-disabled` while still accepting clicks so invalid compose attempts can show feedback instead of going silent.
- Compose creates a floating draft surface without resizing the panel.
- The draft includes a quiet `Copy prompt` action that changes to `Copied` for prototype-level handoff feedback.
- The primary footer CTA changes from `Compose` to `Copy prompt` once a draft exists, then to `Copied` after handoff feedback.
- `Command/Ctrl+Enter` composes from anywhere in the panel, then copies the ready draft on the next press.
- After composing, focus moves to the draft copy action; after copying, focus remains on the refreshed copied action.
- Escape clears the draft before dismissing the panel.
- Closing Handy marks the summon control collapsed and returns focus to it so keyboard flow does not remain inside hidden panel content.
- Single-key `h`/`p` shortcuts consume the key event so summon/peek actions do not leak characters into search after focus moves.

Gallery polish:

- The horizontal rail shows subtle edge fades only when more cards are available.
- Vertical wheel/trackpad movement over the rail maps to horizontal card browsing.
- Rail affordance is recalculated after gallery redraw and panel settle so GSAP entrance timing cannot hide scroll hints.
- Card hover keeps the scroll container geometry stable and animates the media/toolbar instead of scaling the whole card, so edges are not clipped and the footer remains reachable.

Motion constants:

- Panel enter: 0.42s, opacity 0 to 1, scale 0.96 to 1, y 18 to 0, `expo.out`.
- Panel exit: 0.18s, opacity 1 to 0, scale 1 to 0.985, y 0 to 12, `power2.in`.
- Content reveal: search first, pills after 0.05s, cards stagger at 0.035s.
- Hover: scale 1.025, y -4, toolbar opacity 0 to 1 in 0.16s.
- Search/filter feedback: result count y 4 to 0, opacity 0.62 to 1 in 0.18s.
- Draft copy feedback: button scale 0.92 to 1 and draft y 3 to 0 in roughly 0.2s.
- Primary CTA copy feedback: button scale 0.94 to 1 in 0.2s.
- Invalid compose feedback: selected tray or goal input nudges 4px back to 0 over 0.2s.
- Wheel-to-rail scroll: `scrollLeft` eases to the target over 0.26s with `expo.out`.
- Positioning: 18px safe margin, 18px pointer gap, flip by available viewport space, then clamp.
- Attention anchor tracks workspace pointer movement only while Handy is closed; once open, only an explicit workspace click repositions it.
- Reposition animations always settle panel transform back to x/y 0 so CSS `left/top` remains the single source of truth.

Known compromises:

- The browser click position simulates the native global shortcut and mouse position.
- Mock context is static and local-only.
- Codex handoff and clipboard behavior are visual placeholders.
