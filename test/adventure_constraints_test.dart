import 'package:flutter_test/flutter_test.dart';
import 'package:cloak_of_death_flutter/game/adventure_engine.dart';
import 'package:cloak_of_death_flutter/data/room_definitions.dart';
import 'support/walkthrough.dart';

void run(AdventureEngine game, String command) {
  game.execute(
    command,
    roomDefinitions.firstWhere((r) => r.id == game.room).connections,
  );
}

AdventureEngine scene(int room, List<String> held) {
  final game = AdventureEngine()..room = room;
  for (final object in held) {
    game.locations[object] = -1;
  }
  if (held.contains('MATCHES')) game.flags['matches_reached'] = true;
  return game;
}

void main() {
  group('Turn and candle constraints', () {
    test(
      'navigation paths, failed commands and inventory have correct costs',
      () {
        final game = scene(1, ['CANDLE', 'MATCHES']);
        run(game, 'LIGHT CANDLE');
        expect(game.candleLife, 198);
        run(game, 'GO WEST');
        expect(game.room, 2);
        expect(game.moves, 2);
        expect(game.candleLife, 197);
        run(game, 'NONSENSE');
        expect(game.candleLife, 196);
        run(game, 'I');
        run(game, 'INVENTORY');
        run(game, ' ');
        expect(game.moves, 3);
        expect(game.candleLife, 196);
        run(game, 'S'); // Blocked movement still takes a turn.
        expect(game.moves, 4);
        expect(game.candleLife, 195);
      },
    );

    test('extinguishing pauses fuel; relighting cannot replenish it', () {
      final game = scene(1, ['CANDLE', 'MATCHES']);
      run(game, 'LIGHT CANDLE');
      run(game, 'EXTINGUISH CANDLE');
      for (var i = 0; i < 300; i++) {
        run(game, 'WAIT');
      }
      expect(game.candleLife, 198);
      run(game, 'LIGHT CANDLE');
      expect(game.candleLife, 197);
    });

    test(
      '199 burning actions exhaust the candle permanently, with warnings',
      () {
        final game = scene(1, ['CANDLE', 'MATCHES']);
        run(game, 'LIGHT CANDLE');
        for (var i = 0; i < 188; i++) {
          run(game, 'WAIT');
        }
        expect(game.candleLife, 10);
        expect(game.messages.join(' '), contains('flickering'));
        run(game, 'WAIT');
        expect(game.messages.join(' '), isNot(contains('flickering')));
        for (var i = 0; i < 9; i++) {
          run(game, 'WAIT');
        }
        expect(game.candleLife, 0);
        expect(game.present('CANDLE'), isFalse);
        expect(game.present('LIT CANDLE'), isFalse);
        run(game, 'LIGHT CANDLE');
        expect(game.candleLife, 0);
        expect(game.hasLight, isFalse);
      },
    );

    test(
      'dropped candle lights only its room, burns remotely, and can be retrieved',
      () {
        final game = scene(16, ['CANDLE', 'MATCHES']);
        run(game, 'LIGHT CANDLE');
        run(game, 'DROP CANDLE');
        expect(game.hasLight, isTrue);
        expect(game.isDark, isFalse);
        expect(game.inventory, isNot(contains('LIT CANDLE')));
        run(game, 'S');
        run(game, 'N');
        expect(game.candleLife, 195);
        run(game, 'GET CANDLE');
        expect(game.held('LIT CANDLE'), isTrue);
        run(game, 'THROW CANDLE');
        expect(game.isDark, isTrue);
        expect(game.here('CANDLE'), isTrue);
      },
    );

    test('all indoor rooms above 14 are dark without a local light', () {
      final game = AdventureEngine();
      for (var room = 1; room <= 27; room++) {
        game.room = room;
        expect(game.isDark, room > 14 && room < 27, reason: 'Room $room');
      }
      game.room = 16;
      run(game, 'LOOK SHELVES');
      expect(game.locations['BOOK'], 0);
      expect(game.visible, isEmpty);
    });
  });

  group('Carrying and object conservation', () {
    test('six unit ceiling and four-unit iron in either pickup order', () {
      final full = scene(3, [
        'BIBLE',
        'KNIFE',
        'MATCHES',
        'CANDLE',
        'COAL',
        'WINE',
      ]);
      run(full, 'GET BREAD');
      expect(full.held('BREAD'), isFalse);
      expect(full.inventoryLoad, 6);
      final iron = scene(23, ['KNIFE', 'CANDLE', 'MATCHES']);
      run(iron, 'GET IRON');
      expect(iron.held('IRON'), isFalse);
      run(iron, 'DROP MATCHES');
      run(iron, 'GET IRON');
      expect(iron.inventoryLoad, 6);
      run(iron, 'GET MATCHES');
      expect(iron.held('MATCHES'), isFalse);
      run(iron, 'DROP IRON');
      run(iron, 'GET MATCHES');
      expect(iron.inventoryLoad, 3);
    });

    test('cut and craft consume materials and cannot duplicate them', () {
      final game = scene(25, ['SAW', 'BAR', 'WIRE']);
      run(game, 'CUT BAR');
      expect(game.locations['BAR'], 0);
      expect(game.held('BAR PIECES'), isTrue);
      run(game, 'MAKE CRUCIFIX');
      expect(game.inventoryLoad, 1);
      expect(game.locations['BAR PIECES'], 0);
      expect(game.locations['WIRE'], 0);
      run(game, 'GET BAR PIECES');
      run(game, 'GET WIRE');
      expect(game.inventoryLoad, 1);
      run(game, 'GET CRUCIFIX');
      expect(game.inventoryLoad, 2);
    });

    test('cutting pieces again destroys them', () {
      final game = scene(25, ['SAW', 'BAR PIECES']);
      run(game, 'CUT BAR');
      expect(game.locations['BAR PIECES'], 0);
      expect(game.inventoryLoad, 1);
    });

    test(
      'water is a filled goblet and can be blessed after acquiring a missing relic',
      () {
        final game = scene(3, ['GOBLET', 'BIBLE']);
        run(game, 'LOOK SINK');
        run(game, 'GET WATER');
        expect(game.inventoryLoad, 2);
        expect(game.locations['GOBLET'], 0);
        expect(game.held('GOBLET OF WATER'), isTrue);
        game.locations['CRUCIFIX'] = 3;
        run(game, 'GET CRUCIFIX');
        expect(game.held('HOLY WATER'), isTrue);
        expect(game.locations['GOBLET OF WATER'], 0);
        expect(game.locations['WATER'], 3);
        run(game, 'DROP HOLY WATER');
        run(game, 'GET GOBLET');
        expect(game.held('HOLY WATER'), isTrue);
        run(game, 'POUR WATER');
        expect(game.held('GOBLET'), isTrue);
        expect(game.locations['HOLY WATER'], 0);
      },
    );

    test('original GET capacity check also applies to filling water', () {
      final game = scene(3, [
        'GOBLET',
        'BIBLE',
        'CRUCIFIX',
        'WINE',
        'BREAD',
        'CANDLE',
      ]);
      run(game, 'LOOK SINK');
      run(game, 'GET WATER');
      expect(game.held('GOBLET'), isTrue);
      expect(game.held('HOLY WATER'), isFalse);
      run(game, 'DROP CANDLE');
      run(game, 'GET WATER');
      expect(game.held('HOLY WATER'), isTrue);
      expect(game.inventoryLoad, 5);
    });
  });

  group('Puzzle prerequisites and consequences', () {
    test('matches require a chair, and moving resets standing position', () {
      final game = scene(3, []);
      game.locations['CUPBOARD'] = 3;
      run(game, 'LOOK CUPBOARD');
      run(game, 'GET MATCHES');
      expect(game.held('MATCHES'), isFalse);
      game.locations['CHAIR'] = 3;
      run(game, 'CLIMB CHAIR');
      run(game, 'S');
      run(game, 'N');
      run(game, 'GET MATCHES');
      expect(game.held('MATCHES'), isFalse);
      run(game, 'CLIMB CHAIR');
      run(game, 'GET MATCHES');
      expect(game.held('MATCHES'), isTrue);
      run(game, 'DROP MATCHES');
      run(game, 'S');
      run(game, 'N');
      run(game, 'GET MATCHES');
      expect(game.held('MATCHES'), isTrue);
    });

    test(
      'feeding rat consumes bread but does not replace the knife prerequisite',
      () {
        final game = scene(1, ['BREAD']);
        run(game, 'LOOK');
        run(game, 'FEED RAT');
        run(game, 'GO CORRIDOR');
        expect(game.room, 1);
        expect(game.locations['BREAD'], 0);
        expect(game.here('RAT'), isTrue);
      },
    );

    for (final animal in ['RAT', 'DOG']) {
      test('attacking $animal is fatal and terminal', () {
        final game = scene(animal == 'RAT' ? 1 : 26, ['KNIFE']);
        run(game, 'KILL $animal');
        expect(game.outcome, 'dead');
        final before = game.toJson();
        run(game, 'W');
        expect(game.toJson(), before);
      });
    }

    test('cellar key is consumed; unpropped door traps the player', () {
      final game = scene(5, ['KEY']);
      run(game, 'UNLOCK DOOR');
      expect(game.locations['KEY'], 0);
      expect(game.messages.join(' '), contains('without a prop'));
      expect(game.messages.join(' '), contains('broken latch'));
      run(game, 'OPEN DOOR');
      expect(game.messages.join(' '), contains('without a prop'));
      run(game, 'GO DOOR');
      expect(game.messages.join(' '), contains('Nothing was holding it open'));
      run(game, 'U');
      expect(game.room, 23);
      run(game, 'OPEN DOOR');
      expect(game.messages.join(' '), contains('latch is broken'));
    });

    test('chest props door, and picking it up removes the prop', () {
      final game = scene(5, ['KEY', 'CHEST']);
      run(game, 'DROP CHEST');
      expect(game.flag('door_propped'), isFalse);
      expect(
        game.messages.join(' '),
        contains('beside the closed cellar door'),
      );
      run(game, 'UNLOCK DOOR');
      expect(
        game.messages.join(' '),
        contains('chest is keeping the door open'),
      );
      run(game, 'OPEN DOOR');
      expect(
        game.messages.join(' '),
        contains('chest is keeping the door open'),
      );
      run(game, 'GO DOOR');
      run(game, 'U');
      expect(game.room, 5);
      run(game, 'GET CHEST');
      run(game, 'GO DOOR');
      run(game, 'U');
      expect(game.room, 23);
    });

    test(
      'dropping chest after opening reports the prop and permits return',
      () {
        final game = scene(5, ['KEY', 'CHEST']);
        run(game, 'OPEN DOOR');
        expect(game.messages.join(' '), contains('without a prop'));
        run(game, 'DROP CHEST');
        expect(game.flag('door_propped'), isTrue);
        expect(
          game.messages.join(' '),
          contains('chest is keeping the door open'),
        );
        run(game, 'GO DOOR');
        expect(game.messages.join(' '), isNot(contains('slammed shut')));
        run(game, 'U');
        expect(game.room, 5);
        expect(game.moves, 4);
      },
    );

    test('unlocking a remote door cannot change it', () {
      final game = scene(1, ['KEY']);
      run(game, 'UNLOCK DOOR');
      expect(game.flag('door_unlocked'), isFalse);
      expect(game.held('KEY'), isTrue);
    });

    test('pool table opens west return, reset by reentering library', () {
      final game = scene(16, ['CANDLE', 'MATCHES']);
      run(game, 'LIGHT CANDLE');
      run(game, 'PUSH BOOK');
      expect(game.locations['PASSAGEWAY'], 0); // Book must be discovered.
      run(game, 'LOOK SHELVES');
      run(game, 'GET BOOK');
      run(game, 'PUSH BOOK');
      expect(game.locations['PASSAGEWAY'], 0); // Must be on shelf.
      run(game, 'DROP BOOK');
      run(game, 'PUSH BOOK');
      run(game, 'GO PASSAGEWAY');
      run(game, 'D');
      run(game, 'W');
      expect(game.room, 17);
      run(game, 'U');
      run(game, 'E');
      run(game, 'PUSH TABLE');
      run(game, 'W');
      run(game, 'D');
      run(game, 'W');
      expect(game.room, 16);
      run(game, 'PUSH BOOK');
      run(game, 'GO PASSAGEWAY');
      run(game, 'W');
      expect(game.room, 17);
    });

    test('hatch requires removing nails with the hammer', () {
      final game = scene(21, []);
      run(game, 'GO HATCH');
      run(game, 'REMOVE NAILS');
      run(game, 'GO HATCH');
      expect(game.room, 21);
      game.locations['HAMMER'] = -1;
      run(game, 'REMOVE NAILS');
      run(game, 'GO HATCH');
      expect(game.room, 20);
    });

    test(
      'cord pull expires on leaving; weighted cord opens annexe until iron is moved',
      () {
        final game = scene(10, ['IRON']);
        game.locations['CORD'] = 10;
        run(game, 'PULL CORD');
        run(game, 'E');
        run(game, 'W');
        run(game, 'DROP IRON');
        expect(game.locations['ANNEXE'], 0);
        expect(game.messages.join(' '), isNot(contains('holds the cord taut')));
        run(game, 'GET IRON');
        run(game, 'PULL CORD');
        run(game, 'DROP IRON');
        expect(game.locations['ANNEXE'], 13);
        expect(game.messages.join(' '), contains('iron holds the cord taut'));
        expect(
          game.messages.join(' '),
          contains('mechanism settle into place'),
        );
        run(game, 'GET IRON');
        expect(game.locations['ANNEXE'], 0);
      },
    );

    test('dog needs both dropped fuel objects and carried matches', () {
      final game = scene(26, ['GATE KEY', 'COAL', 'RAG']);
      run(game, 'UNLOCK GATES');
      expect(game.flag('gates_unlocked'), isFalse);
      run(game, 'DROP COAL');
      run(game, 'DROP RAG');
      run(game, 'BURN COAL');
      expect(game.here('DOG'), isTrue);
      game.locations['MATCHES'] = -1;
      run(game, 'BURN COAL');
      expect(game.locations['DOG'], 0);
      expect(game.locations['RAG'], 0);
      expect(game.locations['COAL'], 0);
      run(game, 'UNLOCK GATES');
      expect(game.outcome, 'playing');
      run(game, 'E');
      expect(game.outcome, 'won');
    });

    test('burning the rag alone destroys it without scaring the dog', () {
      final game = scene(26, ['RAG', 'MATCHES']);
      run(game, 'LIGHT RAG');
      expect(game.locations['RAG'], 0);
      expect(game.here('DOG'), isTrue);
    });
  });

  group('Cloak and safe', () {
    test('entry, one action, then death; unrecognized commands also count', () {
      final game = scene(14, ['BIBLE', 'CRUCIFIX']);
      run(game, 'E');
      expect(game.cloakTurns, 1);
      run(game, 'NONSENSE');
      expect(game.outcome, 'playing');
      run(game, 'LOOK PAINTING');
      expect(game.outcome, 'dead');
    });

    test('lighting after entry leaves no spare action before exorcism', () {
      final game = scene(14, [
        'BIBLE',
        'CRUCIFIX',
        'HOLY WATER',
        'CANDLE',
        'MATCHES',
      ]);
      run(game, 'E');
      run(game, 'LIGHT CANDLE');
      run(game, 'DROP MATCHES');
      expect(game.outcome, 'dead');
    });

    test(
      'exorcism needs no bread/wine, consumes water, and returns empty goblet',
      () {
        final game = scene(14, [
          'BIBLE',
          'CRUCIFIX',
          'HOLY WATER',
          'CANDLE',
          'MATCHES',
        ]);
        run(game, 'LIGHT CANDLE');
        run(game, 'E');
        run(game, 'EXORCISE CLOAK');
        expect(game.flag('cloak_exorcised'), isTrue);
        expect(game.held('GOBLET'), isTrue);
        expect(game.locations['HOLY WATER'], 0);
        for (var i = 0; i < 4; i++) {
          run(game, 'WAIT');
        }
        expect(game.outcome, 'playing');
      },
    );

    test('exorcism cannot be performed remotely', () {
      final game = scene(25, ['BIBLE', 'CRUCIFIX', 'HOLY WATER']);
      run(game, 'EXORCISE CLOAK');
      expect(game.flag('cloak_exorcised'), isFalse);
      expect(game.held('HOLY WATER'), isTrue);
    });

    test('cloak approach persists across leaving and restoring', () {
      final game = scene(14, ['BIBLE', 'CRUCIFIX']);
      run(game, 'E');
      run(game, 'W');
      final restored = AdventureEngine.fromJson(game.toJson());
      run(restored, 'E');
      expect(restored.cloakTurns, 2);
      run(restored, 'WAIT');
      expect(restored.outcome, 'dead');
    });

    test('painting pickup reveals fixed safe; combination requires prompt', () {
      final game = scene(15, []);
      game.flags['cloak_exorcised'] = true;
      run(game, '1327');
      expect(game.flag('safe_open'), isFalse);
      run(game, 'GET PAINTING');
      expect(game.here('SAFE'), isTrue);
      run(game, 'W');
      run(game, 'DROP PAINTING');
      expect(game.locations['SAFE'], 15);
      run(game, 'E');
      run(game, 'OPEN SAFE');
      final restored = AdventureEngine.fromJson(game.toJson());
      expect(restored.awaitingCombination, isTrue);
      run(restored, '1327');
      expect(restored.flag('safe_open'), isTrue);
    });

    test('wrong safe combination kills and remains terminal after loading', () {
      final game = scene(15, []);
      game.flags['cloak_exorcised'] = true;
      game.locations['SAFE'] = 15;
      run(game, 'OPEN SAFE');
      run(game, '1234');
      expect(game.outcome, 'dead');
      final restored = AdventureEngine.fromJson(game.toJson());
      run(restored, '1327');
      expect(restored.outcome, 'dead');
      expect(restored.flag('safe_open'), isFalse);
    });
  });

  test('walkthrough also wins when restored after every command', () {
    var game = AdventureEngine();
    for (final command in walkthroughCommands) {
      run(game, command);
      game = AdventureEngine.fromJson(game.toJson());
      expect(game.inventoryLoad, lessThanOrEqualTo(6), reason: command);
    }
    expect(game.outcome, 'won');
    expect(game.candleLife, greaterThan(0));
  });

  test(
    'legacy save migration reconciles variants and preserves excess objects in room',
    () {
      final game = AdventureEngine.fromJson({
        'currentRoomId': 1,
        'inventory': ['IRON', 'BIBLE', 'LIT CANDLE', 'MATCHES'],
        'objectLocations': {'CANDLE': -1, 'BAR PIECES': -1, 'DOG': 5},
        'gameFlags': {},
        'candleLife': 290,
      });
      expect(game.inventoryLoad, lessThanOrEqualTo(6));
      expect(game.locations['CANDLE'], 0);
      expect(game.locations['BAR PIECES'], 0);
      expect(game.locations['DOG'], 26);
      expect(game.candleLife, 199);
      for (final item in ['IRON', 'BIBLE', 'LIT CANDLE', 'MATCHES']) {
        expect(game.present(item), isTrue);
      }
    },
  );
}
