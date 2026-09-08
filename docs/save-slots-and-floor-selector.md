# Save slots, house section and hallway fills — 2026-09-08

## Checkpoint contract

The Game menu opens **Save / load game**, with eight numbered local slots.
Each populated slot shows its room, turn count and local date/time. Saving to an
occupied slot requires confirmation; loading confirms replacement of the active
journey. Empty and unreadable slots cannot be loaded. The list scrolls on small
screens; failed operations show feedback and permit retry.

The existing `cloak_save_state` remains the rolling autosave. Manual slots use
`cloak_save_slot_1` through `cloak_save_slot_8`, so starting a new game or continuing
to play never erases a checkpoint. Slot envelope version 1 contains a UTC save
time and the complete engine schema-2 state, transcript and exploration knowledge.
Display settings, selected objects and hint offsets remain presentation state.
Loading clears object selection and hint offsets, and preserves display settings.

`GameState` owns snapshot capture/restore and serializes autosaves, checkpoint
writes and loads through the same queue. A snapshot is captured when Save is
requested. Load waits for older writes, updates autosave, then replaces the
in-memory journey. Reopening the app therefore resumes the loaded checkpoint.
Storage errors are checked before updating the slot list or live journey.
`SaveSlot` validates each stored envelope separately; an unreadable or unsupported
slot does not prevent other slots or the autosave from loading. Existing legacy
autosave migration remains in `AdventureEngine.fromJson`.

These saves live in the application's preferences on the current device/browser;
this feature does not provide cross-device synchronization or file export.

## Visual floor selection

The house section has a roof and four vertically stacked floor targets. Attic is
at the top, cellar/courtyard at the bottom. Floor names describe geography; room
knowledge and travel capabilities still come from the exploration model. A
selected border and a separate current-location symbol distinguish browsing a
floor from actually moving there. Undiscovered levels are disabled and disclose
no rooms, contents or routes. See [exploration-map.md](exploration-map.md).

## Hallway drawing corrections

Room 9's cassette drawing was recovered previously using
`scripts/inspect_original.py`. Its ceiling uses `C9 40`, which seeds at `(4, 0)`
on the closing horizontal outline. The inner right door uses `CC 01 70 1D`,
which seeds at `(112, 29)` on its rasterized sloping outline. The current boundary
fill stops immediately when the seed is on its border color.

Inset those two seeds by one row: `C9 41` and `CC 01 70 1E`. The ceiling now fills
with its outline's teal color and the inner right door with the same gray as the
other doors. Geometry, palette, command count and drawing length are unchanged.
These are explicitly documented artwork corrections, not a claim of newly proven
Atari rasterizer parity. Keep the cassette extractor unchanged as original-byte
evidence. Avoid changing the shared fill algorithm based on two authored seed
positions; its other room/pattern behavior has separate regressions.

## Verification and experience

- `save_slots_test.dart` exercises all eight slots across reset/reinitialization,
  complete state restoration at the pending safe combination, queued write/load
  ordering, damaged/versioned saves, overwrite cancellation, and scrolling to and
  saving slot eight through the dialog.
- `exploration_map_test.dart` checks disabled unexplored floors, elevation order,
  floor switching, discovery and travel behavior. Its old “Attic text absent”
  assertion now checks that the attic room card is absent and its floor disabled.
- `rendering_fill_test.dart` checks filled interior pixels and surviving wall/
  runner pixels. The initial wall sample `(100, 35)` was actually on a black
  picture-frame outline; the corrected wall sample is `(100, 25)`.
- The slot-eight gesture test must pump after lazy-list scrolling, then ensure
  visibility with the settled item extents. Tapping immediately after the first
  scroll can hit below the clipped list viewport.
- Rendered widget PNGs cover the hallway, map at desktop/phone/landscape sizes,
  and save dialog at desktop, 320-pixel phone, landscape and enlarged text sizes.
  Use the documented `PREVIEW_DIR`/`PREVIEW_FONT` workflow in
  [visual-design.md](visual-design.md); actual Material icon fonts are required.
- Flutter initially could not write its SDK cache in the workspace sandbox.
  Retrying the Flutter commands with SDK-cache access allowed validation.
  Direct Dart formatting completed but its analytics timestamp write was denied;
  suppress analytics for subsequent formatting runs.
- The full suite's default test font made the two action buttons wider than a
  320-pixel phone dialog, despite the Roboto screenshot passing. Save/Load actions
  now wrap onto separate lines when needed, accommodating different font metrics
  and accessibility sizing instead of relying on fixed button widths.
