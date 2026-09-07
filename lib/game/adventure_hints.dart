import 'adventure_engine.dart';

/// Read-only guidance derived from puzzle state, never a walkthrough cursor.
/// Item locations also allow recovery after dropping equipment or restoring.
class AdventureHint {
  final String id;
  final String text;
  const AdventureHint(this.id, this.text);
}

class AdventureHints {
  /// Finite, increasingly practical guidance for the current prerequisite.
  /// Unknown steps have just their primary hint, never a fabricated paraphrase.
  static List<String> variants(AdventureHint hint) =>
      {hint.text, ...?_details[hint.id]}.toList(growable: false);

  static const _details = <String, List<String>>{
    'carrying-space': [
      'You have six carrying units. The heavy iron takes four; most other items take one. Leave finished tools in a known room.',
    ],
    'safe-code': [
      'Examine the study desk and take the Bible to uncover the letter. Read the letter for the combination clue.',
      'Enter 1327 in the safe keypad. After it opens, examine the safe to find the gate key.',
    ],
    'cloak-danger': [
      'EXORCISE CLOAK requires the Bible, crucifix, and holy water in your inventory. If anything is missing, go west immediately.',
    ],
    'spent-candle': [
      'Direction commands still work in darkness, but objects are hidden. Relighting cannot restore spent candle fuel.',
    ],
    'darkness': [
      'Use LIGHT CANDLE while carrying both candle and matches. Extinguish it in bright rooms to conserve fuel.',
    ],
    'darkness-equipment': [
      'The candle starts in the pantry; matches are in the kitchen cupboard. The map can help retrieve supplies you dropped.',
    ],
    'save-fuel': [
      'EXTINGUISH CANDLE preserves the remaining wax. Map travel manages lighting automatically when you carry the supplies.',
    ],
    'passage-return': [
      'PUSH TABLE in the pool room, then go west to the attic, down to the passageway, and west to the library.',
    ],
    'escape': [
      'Go east through the unlocked tunnel gate to finish your escape.',
    ],
    'gate': ['Carry the gate key to the tunnel, OPEN GATE, then go east.'],
    'safe-contents': [
      'EXAMINE SAFE reveals the gate key; take it before leaving.',
    ],
    'painting': ['GET PAINTING reveals the wall safe behind it.'],
    'CHAIR': [
      'Carry the chair from the dining room to the kitchen and drop it there.',
      'CLIMB CHAIR, then examine the cupboard and take the matches while standing on the chair.',
    ],
    'high-cupboard': [
      'Drop the chair in the kitchen, CLIMB CHAIR, then EXAMINE CUPBOARD and GET MATCHES.',
    ],
    'KNIFE': [
      'Take the knife from the kitchen and keep it in your inventory when you GO CORRIDOR from the entrance hall.',
      'Do not attack the rat. Carrying the knife is enough to pass it safely.',
    ],
    'BIBLE': [
      'If the Bible is still hidden, EXAMINE DESK in the study reveals it. Carry it when going upstairs from the entrance hall.',
      'Keep track of the Bible after reaching upstairs: you will also need it with the crucifix and holy water for the cloak.',
    ],
    'cellar-lock': [
      'With the small key, OPEN DOOR in the dark corridor. Do not enter until the chest is keeping the door open.',
      'DROP CHEST in the dark corridor props the unlocked door. Its broken latch otherwise traps you downstairs.',
    ],
    'KEY': ['EXAMINE CHEST after breaking its lid, then take the small key.'],
    'CHEST': [
      'The chest begins in the conservatory. KICK CHEST breaks its lid; examine it to find the small key.',
      'Carry the chest to the dark corridor. Unlock the door with the key, then DROP CHEST there before going down: it holds the door open despite the broken latch.',
    ],
    'cellar-prop': [
      'Retrieve the chest and use DROP CHEST in the dark corridor beside the unlocked door, not down in the cellar.',
      'Leave the chest there after entering. Picking it up removes the prop and lets the cellar door trap you again.',
    ],
    'CANDLE': [
      'Carry matches as well as the candle; an unlit candle alone cannot illuminate the cellar.',
    ],
    'LIT CANDLE': [
      'Pick up the lit candle before leaving. It only lights the room where it is, and burns fuel even when dropped.',
    ],
    'lost-matches': [
      'A remaining lit candle still works, but once extinguished it cannot be relit without matches.',
    ],
    'MATCHES': [
      'Matches are needed both to light the candle and to ignite the coal and oily rag in the tunnel.',
    ],
    'HAMMER': [
      'Carry the garage hammer to the pool room and REMOVE NAILS from the hatch.',
    ],
    'hatch': [
      'REMOVE NAILS needs the hammer in your inventory. GO HATCH leads to the silver wire.',
    ],
    'attic-route': [
      'Go up from the passageway, then east from the attic to the pool room. The hammer opens its nailed hatch.',
    ],
    'book-shelf': [
      'Return the book to the library, then PULL BOOK there to reveal the passageway.',
    ],
    'library': [
      'EXAMINE SHELVES in the library, then PULL BOOK to reveal the passageway. Go through it and up to reach the attic.',
    ],
    'WIRE': [
      'The silver wire binds the cut silver bar pieces into a crucifix. Carry both to the workshop to MAKE CROSS.',
    ],
    'SAW': [
      'The rusty saw starts in the garage. Carry it and the silver bar to the workshop to CUT BAR.',
    ],
    'BAR': [
      'Use the silver bar, not the heavy iron. CUT BAR requires the saw and the workshop.',
    ],
    'BAR PIECES': [
      'Carry the bar pieces and silver wire to the workshop, then MAKE CROSS.',
    ],
    'cut-silver': [
      'In the workshop, CUT BAR with the saw. The resulting pieces can be bound with silver wire.',
    ],
    'cross': [
      'In the workshop, carry both BAR PIECES and WIRE and use MAKE CROSS. The heavy iron is for the bedroom cord, not the crucifix.',
    ],
    'cord-weight': [
      'In the guest bedroom, PULL CORD and then DROP IRON before leaving. The weight keeps the annexe open.',
    ],
    'IRON': [
      'Carry the heavy iron to the guest bedroom. PULL CORD, then DROP IRON while the cord is pulled. Keep the Bible for the entrance stairs.',
    ],
    'guest-cord': [
      'Examine the guest bedroom to reveal the cord. Pull it and drop the heavy iron there to keep the mechanism held.',
    ],
    'GOBLET': [
      'With the cord held by the iron, go to the master bedroom and enter the annexe to retrieve the silver goblet.',
    ],
    'CRUCIFIX': [
      'Carry the crucifix, Bible, and holy water together before facing the cloak.',
    ],
    'HOLY WATER': [
      'The cloak requires all three: holy water, Bible, and crucifix. Bring them into the haunted bedroom and EXORCISE CLOAK promptly.',
    ],
    'GOBLET OF WATER': [
      'Carrying the filled goblet with both the Bible and crucifix blesses its water automatically.',
    ],
    'blessing': [
      'Carry the silver goblet, Bible, and crucifix to the kitchen. EXAMINE SINK, then GET WATER; it becomes holy water automatically. Leave one carrying unit free.',
    ],
    'ritual-ready': [
      'Light the candle before entering the haunted bedroom east of the icy corridor, then EXORCISE CLOAK immediately.',
    ],
    'COAL': [
      'Bring the oily rag from the workshop and carry matches too; the coal cannot be lit without the rag beside it.',
      'In the tunnel with the dog, DROP COAL and DROP RAG, then LIGHT COAL. The glowing embers frighten the dog away.',
    ],
    'RAG': [
      'Take the rag and coal to the tunnel, with matches in your inventory. Drop both beside the dog before lighting the coal.',
      'Do not burn the rag on its own or light the pair in another room. The embers must be created where the dog is.',
    ],
    'embers': [
      'With matches in your inventory and both coal and rag on the tunnel floor, LIGHT COAL frightens the dog away.',
    ],
    'dog': [
      'DROP COAL and DROP RAG in the tunnel, then LIGHT COAL while carrying matches. Do not attack the dog.',
      'Once the dog is gone, the gate still needs its own key from the haunted bedroom safe.',
    ],
  };

  static AdventureHint next(
    AdventureEngine game,
    String Function(int) roomName,
  ) {
    AdventureHint hint(String id, String text) => AdventureHint(id, text);
    bool exists(String item) => game.locations[item] != 0;
    AdventureHint seek(String item, String clue, {String? id}) {
      final location = game.locations[item] ?? 0;
      if (location > 0 && location != game.room) {
        return hint(
          id ?? item,
          '$clue You can find the ${item.toLowerCase()} in the ${roomName(location)}.',
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
      return hint(id ?? item, clue);
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
        'The safe combination is hidden in the sound of the study letter: 1327.',
      );
    }
    if (game.room == 15 && !game.flag('cloak_exorcised')) {
      return hint(
        'cloak-danger',
        game.held('BIBLE') && game.held('CRUCIFIX') && game.held('HOLY WATER')
            ? 'You have the Bible, crucifix, and holy water. Exorcise the cloak now; staying here for three turns is fatal.'
            : 'Go west to safety now. Return with the Bible, crucifix, and holy water; the cloak kills after three turns in this room.',
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
          'You have a candle and matches. Light the candle to see this room.',
        );
      }
      return hint(
        'darkness-equipment',
        'You need a candle and matches to see here. Retrieve your lighting supplies; direction buttons still let you move in darkness.',
      );
    }
    if (game.held('LIT CANDLE') && game.room < 15) {
      return hint(
        'save-fuel',
        'This room is already bright. Extinguish the candle to save fuel for the cellar and attic.',
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
        'Collect the silver wire beyond the hatch. You will need it to bind silver bar pieces into a crucifix.',
      );
    }
    if ((game.room == 17 || game.room == 18 || game.room == 21) &&
        !game.flag('table_pushed') &&
        game.held('WIRE')) {
      return hint(
        'passage-return',
        'Push the table in the pool room to reopen the passageway route back to the library.',
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
            'Retrieve the gate key from the wall safe; it unlocks the tunnel gate.',
          );
        }
        if (!game.flag('dog_terrified')) return _dog(game, seek);
        return hint(
          'gate',
          'Use the gate key from the safe to unlock the iron gate at the end of the tunnel.',
        );
      }
      if (game.flag('safe_open')) {
        return hint(
          'safe-contents',
          'Examine the open safe to reveal the gate key, then take it.',
        );
      }
      if (exists('SAFE')) {
        return hint(
          'safe-code',
          'Open the wall safe with the four-digit combination hinted at in the study letter: 1327.',
        );
      }
      return hint(
        'painting',
        'The cloak is gone. Remove the painting in this room to uncover the wall safe.',
      );
    }
    if (!game.flag('matches_reached')) {
      if (game.locations['CHAIR'] != 3 && !game.held('CHAIR')) {
        return seek(
          'CHAIR',
          'The kitchen cupboard holds matches, but you need the dining-room chair to reach them.',
        );
      }
      return hint(
        'high-cupboard',
        'Look around the kitchen to find the cupboard. Stand on the chair to reach its matches.',
      );
    }
    if (!game.held('KNIFE') && !game.flag('door_unlocked')) {
      return seek(
        'KNIFE',
        'Carry the kitchen knife to get past the rat into the dark corridor. You do not need to attack it.',
      );
    }
    if (!game.held('BIBLE') && !game.flag('door_unlocked')) {
      return seek(
        'BIBLE',
        exists('BIBLE')
            ? 'Carry the Bible to overcome your fear and go upstairs from the entrance hall.'
            : 'Examine the study desk for the Bible. Carrying it lets you go upstairs from the entrance hall.',
      );
    }
    if (!game.flag('door_unlocked')) {
      if (game.held('KEY')) {
        return hint(
          'cellar-lock',
          'The small key unlocks the cellar door in the dark corridor. Bring the chest too: the door needs a prop before you enter.',
        );
      }
      if (game.flag('chest_broken')) {
        return seek(
          'KEY',
          'Examine the broken chest and take its small key for the cellar door.',
        );
      }
      return seek(
        'CHEST',
        'Break open the wooden chest to find the cellar key. Keep the chest: dropping it in the dark corridor will hold the unlocked door open.',
      );
    }
    if (game.room == 5 && !game.flag('door_propped')) {
      return seek(
        'CHEST',
        'Drop the chest in the dark corridor before entering the cellar. It props the door open; the broken latch otherwise leaves you trapped downstairs.',
        id: 'cellar-prop',
      );
    }
    final movingIron = exists('CRUCIFIX') && !game.flag('cord_held');
    if (!movingIron && !game.held('CANDLE') && !game.held('LIT CANDLE')) {
      return seek(
        exists('LIT CANDLE') ? 'LIT CANDLE' : 'CANDLE',
        'Bring the candle for the dark rooms. It starts in the pantry, and needs matches to light.',
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
        'Retrieve your matches so you can light the candle and the coal-and-rag fire for the dog.',
      );
    }
    if (!game.flag('dog_terrified')) return _dog(game, seek);
    if (!exists('CRUCIFIX')) {
      if (!game.flag('hatch_open')) {
        if (!game.held('HAMMER')) {
          return seek(
            'HAMMER',
            'The garage hammer can remove the nails from the pool-room hatch.',
          );
        }
        if (game.room == 21) {
          return hint(
            'hatch',
            'Use the hammer to remove the hatch nails. The store room beyond contains silver wire for the crucifix.',
          );
        }
        if (game.room == 17 || game.room == 18) {
          return hint(
            'attic-route',
            'Go up from the hidden passage to the attic, then east to the pool room and its nailed hatch.',
          );
        }
        if (game.held('BOOK')) {
          return hint(
            'book-shelf',
            'The library book operates a secret door only while it is in the library. Put it back before pulling it.',
          );
        }
        return hint(
          'library',
          'Examine the library shelves and pull the book to reveal a passageway leading up to the attic.',
        );
      }
      if (!game.held('WIRE')) {
        return seek(
          'WIRE',
          'Get the silver wire beyond the pool-room hatch. It joins the cut bar pieces into a crucifix.',
        );
      }
      if (!game.held('BAR PIECES')) {
        if (!game.held('SAW')) {
          return seek(
            'SAW',
            'You need the garage saw to cut the silver bar into crucifix pieces in the workshop.',
          );
        }
        if (!game.held('BAR')) {
          return seek(
            exists('BAR PIECES') ? 'BAR PIECES' : 'BAR',
            'The workshop silver bar provides the pieces for a crucifix. It needs cutting with the saw, then binding with silver wire.',
          );
        }
        return hint(
          'cut-silver',
          'Cut the silver bar with the saw in the workshop. Keep the pieces for the crucifix.',
        );
      }
      return hint(
        'cross',
        'Make a crucifix in the workshop using the cut silver bar pieces and silver wire, then pick it up.',
      );
    }
    final hasVessel = exists('GOBLET OF WATER') || exists('HOLY WATER');
    if (!game.held('GOBLET') && !hasVessel) {
      if (!game.flag('cord_held')) {
        if (game.room == 10 && game.held('IRON')) {
          return hint(
            'cord-weight',
            'Pull the bedroom cord and drop the heavy iron to keep it pulled. This holds the master-bedroom annexe open.',
          );
        }
        if (game.room == 1 && game.held('IRON') && !game.held('BIBLE')) {
          return seek(
            'BIBLE',
            'Keep the Bible while carrying the iron: you still need it to go upstairs from the entrance hall.',
          );
        }
        if (!game.held('IRON')) {
          return seek(
            'IRON',
            'Use the heavy cellar iron to hold down the guest-bedroom cord. It takes four carrying units; it is not the silver bar used for the crucifix.',
          );
        }
        return hint(
          'guest-cord',
          'The guest-bedroom cord opens the master-bedroom annexe. Pull it and use the heavy iron to keep it held.',
        );
      }
      return seek(
        'GOBLET',
        'Enter the annexe from the master bedroom and collect the silver goblet for holy water.',
      );
    }
    if (!game.held('BIBLE')) {
      return seek(
        'BIBLE',
        'Retrieve the Bible. You need it with the crucifix and a goblet of water to prepare holy water.',
      );
    }
    if (!game.held('CRUCIFIX')) {
      return seek(
        'CRUCIFIX',
        'Pick up your crucifix. You must carry it with the Bible and holy water to exorcise the cloak.',
      );
    }
    if (!game.held('HOLY WATER')) {
      if (exists('HOLY WATER')) {
        return seek(
          'HOLY WATER',
          'Retrieve the holy water before entering the haunted bedroom; bring the Bible and crucifix too.',
        );
      }
      if (exists('GOBLET OF WATER') && !game.held('GOBLET OF WATER')) {
        return seek(
          'GOBLET OF WATER',
          'Pick up the goblet of water while carrying the Bible and crucifix; the water will become holy water.',
        );
      }
      return hint(
        'blessing',
        'Fill the silver goblet from the kitchen sink while carrying the Bible and crucifix to make holy water.',
      );
    }
    return hint(
      'ritual-ready',
      'Bring the Bible, crucifix, and holy water into the haunted bedroom east of the icy corridor. Light your candle first, then exorcise the cloak promptly.',
    );
  }

  static AdventureHint _dog(
    AdventureEngine game,
    AdventureHint Function(String, String) seek,
  ) {
    if (game.room == 26 && game.here('COAL') && game.here('RAG')) {
      return const AdventureHint(
        'embers',
        'The coal and oily rag are together beside the dog. Light the coal with matches to frighten it away.',
      );
    }
    for (final item in ['COAL', 'RAG']) {
      if (!game.held(item) && game.locations[item] != 26) {
        return seek(
          item,
          item == 'COAL'
              ? 'Examine the sitting-room fireplace for coal. Burning it with the oily rag in the tunnel frightens the dog away.'
              : 'Get the oily rag from the workshop. The coal needs it as kindling to frighten the tunnel dog.',
        );
      }
    }
    return const AdventureHint(
      'dog',
      'Drop the coal and oily rag together in the tunnel, then light the coal with matches. The glowing embers frighten the dog away.',
    );
  }
}
