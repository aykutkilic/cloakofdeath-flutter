# Development history

## 2026-09-07 — Original game rules and solvability audit

Purpose: make the mobile adaptation solvable under the original constraints,
using the supplied walkthrough and original Atari BASIC/cassette as evidence.

- Extracted cassette DATA and exit bytes; resolved the transcription error that
  placed the dog in the corridor and hid the cellar door.
- Separated deterministic adventure rules from Flutter presentation/persistence.
  Restored six-unit inventory, four-unit iron, cumulative 199-turn candle life,
  cloak deaths, cellar-door trapping, chair reach, passage/table gating, crafting,
  holy-water consumption, safe deaths, and courtyard-only victory.
- Added schema-2 saves with ordered snapshot writes and legacy migration.
  Made the carrying badge and contextual puzzle menus reflect the rules.
- Replaced the permissive solution test with the constrained complete route;
  added boundary, negative-path, save/restore, and tap interaction regressions.
- Validation: `flutter test` passed all 45 tests, including the full walkthrough
  and restoration after every command. Static analysis found one existing unused
  `_hoverLocalPos` field in `lib/rendering/atari_render_controller.dart`; new rule
  code has no remaining diagnostics. No emulator or physical-device acceptance
  was claimed.

The [audit](game-logic-audit.md) records source line references, intentional
compatibility decisions, limitations, and tool failures for future work.

## 2026-09-07 — Visual refresh and live application update

Purpose: make the source-corrected game easier to read and play on phones and
desktop while preserving its original Atari artwork.

- Added a dark green/brass theme, framed room art, readable journal, explicit
  command submission, fuel/load indicators, responsive object and inventory
  controls, and fixed phone/short-landscape navigation.
- Added scrollable display settings, reduced-motion behavior, clearer terminal
  states, and confirmation before replacing an active game.
- Fixed blank scenes with animation disabled and removed the existing unused
  renderer field. Corrected duplicate room-description punctuation and journal
  command-prefix formatting.
- Validation: all 52 tests passed, including the full constrained walkthrough,
  saved-game continuity, interaction tests, six viewport/text-size scenarios, and
  instant rendering checks. `flutter analyze` reported no issues. Rendered PNGs
  were inspected and small-screen layout refinements rechecked.
- Applied the changes to the connected macOS app with a successful hot restart
  and subsequent hot reloads; no runtime errors were reported.

[Visual design notes](visual-design.md) record the layout decisions, screenshot
workflow, browser/driver limitations, and rendering fix.
