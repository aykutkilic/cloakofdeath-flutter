# Visual interface decisions — 2026-09-07

The interface now uses dark green surfaces, warm brass accents, and paper-colored
text. The original Atari scene pixels remain the visual foundation, paired with
purpose-built vector inventory icons. The Atari font is reserved for the title; ordinary interface
text uses a readable system font and honors text scaling.

## Layout and interaction

- Desktop: exploration and inventory on the left, a journal and command input on
  the right. Artwork is framed and respects the selected aspect ratio; its height
  is bounded so it does not displace all the controls. Enlarge opens the scene.
- Phone: exploration and its navigation rail scroll together; the latest journal
  output and input stay outside that scroll area. The keyboard resizes the playable
  area without overflow.
- Look around and movement occupy a vertical rail to the right of the artwork,
  inspired by classic adventure side controls. The frame itself has the selected
  aspect ratio, eliminating the extra black gutters of a wider enclosing frame.
  Small screens retain 48-pixel direction targets and use a compact darkness
  symbol with the explanation below the image.
  Object and inventory actions use wrapping buttons instead of text squeezed into
  tiny fixed grids. Buttons retain at least 48 logical pixels of height. Inventory
  indicates carrying units and labels the iron's four-unit weight explicitly.
- Fuel and carrying state come from `GameState`; visual widgets do not advance
  timers or create independent game state. Direction buttons use the engine's
  available exits in light. In darkness all direction attempts stay clickable,
  using exactly the same command path and turn costs as typed movement. Darkness
  guidance explains the cellar's broken latch when the chest was not left to prop
  the door; it does not unlock the original puzzle or invent an escape exit.
- Input has an explicit send button and does not automatically open the keyboard.
  Commands are distinguished from responses in the journal. Auto-scroll runs only
  when transcript content changes, not when an object selection rebuilds the UI.
- Dead/won games show a terminal message and Play again. Starting over during a
  live game asks before replacing progress. Dismissing an action dialog also
  clears the transient selection.

## Inventory icon system

`InventoryIconPainter` draws all 28 portable-object names on a 32-unit grid,
using rounded 1.7-unit strokes and parchment, brass, silver, leather, and muted
green materials. Code-native vectors avoid raster tinting and scale cleanly for
36-pixel inventory cards, 20-pixel object chips, and 28-pixel action dialogs.
`ObjectIcon` is the shared selection point; scenery keeps its existing fallback.
Old raster assets remain available for historical/reference use.

Different silhouettes, not just color, identify Bible/book, key/gate key,
bar/pieces, coal/iron, and candle states. Goblets show their contents; holy water
adds a cross. Item names stay visible, and decorative artwork does not duplicate
their accessibility labels. Inventory behavior and game state are unchanged.

`inventory_icons_test.dart` checks coverage against the engine's portable set,
pixel differences for related states at 20 pixels, and real inventory-to-action
interaction. With the same preview defines below it writes `inventory-icons.png`,
a contact sheet at both display sizes plus a 320-pixel-wide inventory control.

## Rendering fix

Previously `autoStart: false` initialized a blank renderer and never painted the
room. The controller now renders the full scene immediately when animation is
disabled, on a room change, or when animation is turned off during playback.
Reduced-motion preferences select that path too. Debug-overlay changes no longer
restart room drawing. Deferred animation startup checks that the widget is mounted.
The unused hover-position field was removed while retaining pixel inspection.

## Evidence and maintenance

`ui_layout_test.dart` checks 1280×900, 390×844, 320×568, 844×390, a simulated
320-pixel keyboard inset, and 1.6× text. Each layout submits a real LOOK command
and checks for exceptions and a visible command field. Another test checks actual
rendered pixel buffers when animation is disabled and after room changes.

To generate PNG previews with readable fonts, run the layout test with:

```sh
flutter test test/ui_layout_test.dart \
  --dart-define=PREVIEW_DIR=/private/tmp/cloak-previews \
  --dart-define=PREVIEW_FONT=/path/to/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf
```

The optional font path is only for screenshot capture, not an app dependency.
The test also loads MaterialIcons from that directory; without it, widget-test
captures show placeholder icon squares. PNG captures are Flutter widget renders,
not photographs of devices. Keyboard captures simulate the inset, not the OS
keyboard itself. Screenshots exposed crowded phone navigation, leading to the
fixed navigation strip and more compact layouts.

The in-app browser bootstrap failed with `Cannot redefine property: process`.
Native Flutter driver screenshots were unavailable because that app lacks the
driver extension. Verification therefore used rendered widget screenshots and
the connected macOS app. Initial hot reload could not apply the structural
changes; hot restart succeeded, followed by successful hot reloads and no reported
runtime errors. No new driver dependency was added solely for screenshot capture.

Keep shared colors and spacing in `AppTheme`, object glyph selection in
`ObjectIcon`, and display settings in `GameSettingsDialog`. Do not duplicate
game-rule state in the widgets.
