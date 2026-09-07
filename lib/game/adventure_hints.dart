import 'adventure_engine.dart';

/// Read-only guidance derived from puzzle state, never a walkthrough cursor.
/// Item locations also allow recovery after dropping equipment or restoring.
class AdventureHint {
  final String id;
  final String text;
  const AdventureHint(this.id, this.text);
}

class AdventureHints {
  static AdventureHint next(
    AdventureEngine game,
    String Function(int) roomName,
  ) {
    AdventureHint hint(String id, String text) => AdventureHint(id, text);
    bool exists(String item) => game.locations[item] != 0;
    AdventureHint seek(String item, String clue) {
      final location = game.locations[item] ?? 0;
      if (location > 0 && location != game.room) {
        return hint(
          item,
          '$clue Something useful is in the ${roomName(location)}.',
        );
      }
      if (!game.held(item) &&
          game.inventoryLoad + AdventureEngine.weight(item) >
              AdventureEngine.capacity) {
        return hint(
          'carrying-space',
          'Your hands are full. A familiar, well-lit room could keep something '
              'safe until you need it again. The iron alone needs four carrying units.',
        );
      }
      return hint(item, clue);
    }

    if (!game.isPlaying) {
      return hint(
        'ending',
        game.outcome == 'won'
            ? 'Fresh air at last. The house has no more hold over you.'
            : 'This journey has ended. A fresh start is a chance to remember '
                  'what the house taught you.',
      );
    }
    if (game.awaitingCombination) {
      return hint(
        'safe-code',
        'The letter sounds different when heard as digits. '
            'Let 1327 linger in your mind as you study the four spaces.',
      );
    }
    if (game.room == 15 && !game.flag('cloak_exorcised')) {
      return hint(
        'cloak-danger',
        game.held('BIBLE') && game.held('CRUCIFIX') && game.held('HOLY WATER')
            ? 'This is a possession, not a fight. Your sacred objects belong '
                  'together in a rite, and the approaching cloth leaves little time.'
            : 'The cloth is closing in. Curiosity can wait; safety lies back '
                  'through the doorway until faith, silver, and blessed water are ready.',
      );
    }
    if (game.isDark) {
      if (game.candleLife == 0 ||
          (!exists('CANDLE') && !exists('LIT CANDLE'))) {
        return hint(
          'spent-candle',
          'The last of your light is gone. If unexplored darkness still '
              'stands between you and freedom, an earlier save or a fresh '
              'journey may be needed.',
        );
      }
      if (game.held('CANDLE') && game.held('MATCHES')) {
        return hint(
          'darkness',
          'Wax and a spark could give this darkness a shape.',
        );
      }
      return hint(
        'darkness-equipment',
        'Darkness conceals both objects and dangers. Remember where you '
            'left your candle and its source of fire; direction buttons still '
            'let you feel your way.',
      );
    }
    if (game.held('LIT CANDLE') && game.room < 15) {
      return hint(
        'save-fuel',
        'There is already enough light here. Every unnecessary flame '
            'leaves a little less wax for the darkness ahead.',
      );
    }
    if ((game.room == 20 ||
            game.room == 21 ||
            game.room == 17 ||
            game.room == 18) &&
        game.flag('hatch_open') &&
        exists('WIRE') &&
        !game.held('WIRE')) {
      return seek(
        'WIRE',
        'Something thin and silver beyond the hatch could '
            'bind larger pieces together.',
      );
    }
    if ((game.room == 17 || game.room == 18 || game.room == 21) &&
        !game.flag('table_pushed') &&
        game.held('WIRE')) {
      return hint(
        'passage-return',
        'The route back is linked to the pool room. Its largest furnishing '
            'may be less fixed than it looks.',
      );
    }
    if (game.flag('cloak_exorcised')) {
      if (game.flag('gates_unlocked')) {
        return hint('escape', 'Beyond the iron gates, open air is waiting.');
      }
      if (game.flag('gate_key_found')) {
        if (!game.held('GATE KEY')) {
          return seek(
            'GATE KEY',
            'The key from the wall safe belongs to '
                'something more substantial than a bedroom door.',
          );
        }
        if (!game.flag('dog_terrified')) return _dog(game, seek);
        return hint(
          'gate',
          'The tunnel ends at iron bars. The safe kept '
              'the means of passing them.',
        );
      }
      if (game.flag('safe_open')) {
        return hint(
          'safe-contents',
          'An open safe deserves a closer look; '
              'its value may be a way out rather than treasure.',
        );
      }
      if (exists('SAFE')) {
        return hint(
          'safe-code',
          'The wall lock wants four digits. '
              'The letter in the study has a curious sound to it: 1327.',
        );
      }
      return hint(
        'painting',
        'Now the room is quiet, consider what '
            'the picture might be covering.',
      );
    }
    if (!game.flag('matches_reached')) {
      if (game.locations['CHAIR'] != 3 && !game.held('CHAIR')) {
        return seek(
          'CHAIR',
          'A kitchen cupboard may be beyond your reach. '
              'Furniture need not stay in the room where you found it.',
        );
      }
      return hint(
        'high-cupboard',
        'The kitchen rewards a closer look. '
            'Its tall cupboard and a steadier, higher viewpoint belong together.',
      );
    }
    if (!game.held('KNIFE') && !game.flag('door_unlocked')) {
      return seek(
        'KNIFE',
        'The rat need not be harmed. A kitchen utensil '
            'might make it think twice about blocking your path.',
      );
    }
    if (!game.held('BIBLE') && !game.flag('door_unlocked')) {
      return seek(
        'BIBLE',
        exists('BIBLE')
            ? 'You may want the comfort of scripture before facing the upstairs rooms.'
            : 'The study desk may hold something more reassuring than furniture.',
      );
    }
    if (!game.flag('door_unlocked')) {
      if (game.held('KEY')) {
        return hint(
          'cellar-lock',
          'A small key and the corridor door look '
              'like parts of the same mystery.',
        );
      }
      if (game.flag('chest_broken')) {
        return seek(
          'KEY',
          'The damaged chest may have more to show you inside.',
        );
      }
      return seek(
        'CHEST',
        'An old wooden lid might respond to a less polite '
            'approach. That heavy box could also be useful beside a troublesome door.',
      );
    }
    if (game.room == 5 && !game.flag('door_propped')) {
      return seek(
        'CHEST',
        'Before trusting the cellar stairs, consider what '
            'would keep the door from slamming behind you. A heavy box might help.',
      );
    }
    final movingIron = exists('CRUCIFIX') && !game.flag('cord_held');
    if (!movingIron && !game.held('CANDLE') && !game.held('LIT CANDLE')) {
      return seek(
        exists('LIT CANDLE') ? 'LIT CANDLE' : 'CANDLE',
        'The pantry once offered a little light for the darker parts of the house.',
      );
    }
    if (!movingIron && !game.held('MATCHES') && !game.held('LIT CANDLE')) {
      if (!exists('MATCHES')) {
        return hint(
          'lost-matches',
          'The source of fire has been used up. '
              'An unlit candle cannot help on its own; an earlier save or a '
              'fresh journey may be needed.',
        );
      }
      return seek(
        'MATCHES',
        'Wax alone cannot drive away the dark. '
            'Remember where you left the little source of fire.',
      );
    }
    if (!game.flag('dog_terrified')) return _dog(game, seek);
    if (!exists('CRUCIFIX')) {
      if (!game.flag('hatch_open')) {
        if (!game.held('HAMMER')) {
          return seek(
            'HAMMER',
            'Some fastenings need a claw rather than a key.',
          );
        }
        if (game.room == 21) {
          return hint(
            'hatch',
            'The hatch is held by small metal fastenings. '
                'The claw in your toolkit was made to loosen them.',
          );
        }
        if (game.room == 17 || game.room == 18) {
          return hint(
            'attic-route',
            'Above the hidden passage lies an attic; '
                'the pool room beyond it has a fastening worth investigating.',
          );
        }
        if (game.held('BOOK')) {
          return hint(
            'book-shelf',
            'A secret mechanism needs its lever '
                'in place. A book in your hands cannot move its shelf.',
          );
        }
        return hint(
          'library',
          'A particular volume on the library shelves '
              'may move more than a reader. Beyond it lies a route upward.',
        );
      }
      if (!game.held('WIRE')) {
        return seek(
          'WIRE',
          'The space beyond the hatch hides something '
              'thin enough to hold silver pieces together.',
        );
      }
      if (!game.held('BAR PIECES')) {
        if (!game.held('SAW')) {
          return seek(
            'SAW',
            'A silver bar needs reshaping. Even a rusty '
                'cutting tool may have a useful edge.',
          );
        }
        if (!game.held('BAR')) {
          return seek(
            exists('BAR PIECES') ? 'BAR PIECES' : 'BAR',
            'Silver in the workshop could become something protective.',
          );
        }
        return hint(
          'cut-silver',
          'The workshop is a good place to divide '
              'silver into lengths for a sacred shape.',
        );
      }
      return hint(
        'cross',
        'Two silver lengths crossing, held by wire: '
            'imagine the symbol they could form on the workshop bench.',
      );
    }
    final hasVessel = exists('GOBLET OF WATER') || exists('HOLY WATER');
    if (!game.held('GOBLET') && !hasVessel) {
      if (!game.flag('cord_held')) {
        if (game.room == 10 && game.held('IRON')) {
          return hint(
            'cord-weight',
            'A tug is temporary. Something very '
                'heavy could keep the silk cord under tension after you let go.',
          );
        }
        if (game.room == 1 && game.held('IRON') && !game.held('BIBLE')) {
          return seek(
            'BIBLE',
            'Even with a weight for the bedroom mechanism, '
                'you still need the comfort of scripture to face the stairs.',
          );
        }
        if (!game.held('IRON')) {
          return seek(
            'IRON',
            'The guest bedroom mechanism needs lasting '
                'weight, not just a brief tug. You will need four free carrying units.',
          );
        }
        return hint(
          'guest-cord',
          'The guest bedroom has a hanging thread '
              'of a mystery. Its movement may affect another room.',
        );
      }
      return seek(
        'GOBLET',
        'The master bedroom has changed. A small '
            'side room may hold a vessel worthy of a ritual.',
      );
    }
    if (!game.held('BIBLE')) {
      return seek(
        'BIBLE',
        'Scripture belongs beside the silver vessel '
            'when you prepare for the haunted room.',
      );
    }
    if (!game.held('CRUCIFIX')) {
      return seek(
        'CRUCIFIX',
        'A crafted symbol cannot protect you '
            'while it waits elsewhere.',
      );
    }
    if (!game.held('HOLY WATER')) {
      if (exists('HOLY WATER')) {
        return seek(
          'HOLY WATER',
          'Blessed water is best kept close '
              'when the cloth begins to stir.',
        );
      }
      if (exists('GOBLET OF WATER') && !game.held('GOBLET OF WATER')) {
        return seek(
          'GOBLET OF WATER',
          'Water, scripture, and your silver '
              'symbol may have a special affinity when carried together.',
        );
      }
      return hint(
        'blessing',
        'The kitchen has water. In a silver vessel, '
            'beside scripture and a sacred symbol, it may become more than water.',
      );
    }
    return hint(
      'ritual-ready',
      'Faith, silver, and blessed water are ready. '
          'Beyond the icy corridor, prepare your light before meeting the cloth; '
          'there will be little time for anything but a rite.',
    );
  }

  static AdventureHint _dog(
    AdventureEngine game,
    AdventureHint Function(String, String) seek,
  ) {
    if (game.room == 26 && game.here('COAL') && game.here('RAG')) {
      return const AdventureHint(
        'embers',
        'A spark could turn those dark '
            'lumps into a pair of eyes to rival the guard at the gates.',
      );
    }
    for (final item in ['COAL', 'RAG']) {
      if (!game.held(item) && game.locations[item] != 26) {
        return seek(
          item,
          item == 'COAL'
              ? 'The sitting-room fireplace holds something that could glow '
                    'like watchful eyes.'
              : 'A workshop rag carries oil. It could help something else '
                    'glow, rather than burn away alone.',
        );
      }
    }
    return const AdventureHint(
      'dog',
      'The tunnel guard fears what it '
          'resembles. Dark lumps and an oily scrap at its feet might suggest '
          'a rival with glowing eyes.',
    );
  }
}
