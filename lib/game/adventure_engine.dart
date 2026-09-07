/// Deterministic adventure rules. Flutter, rendering and persistence live outside
/// this class. Object locations are authoritative: 0 absent, -1 held, >0 room.
/// See docs/game-logic-audit.md for cassette evidence and intentional repairs.
class AdventureEngine {
  static const capacity = 6;
  // BASIC LC starts at 1 and the candle disappears when LC reaches 200.
  static const candleBurnTurns = 199;
  static const initialLocations = <String, int>{
    'BALL': 0,
    'BAR': 25,
    'BAR PIECES': 0,
    'BIBLE': 0,
    'BOOK': 0,
    'WINE': 22,
    'BREAD': 3,
    'CANDLE': 4,
    'LIT CANDLE': 0,
    'CHAIR': 2,
    'CHEST': 6,
    'COAL': 0,
    'CRUCIFIX': 0,
    'GOBLET': 12,
    'WATER': 0,
    'GOBLET OF WATER': 0,
    'HOLY WATER': 0,
    'HAMMER': 24,
    'IRON': 23,
    'KEY': 0,
    'GATE KEY': 0,
    'KNIFE': 3,
    'LETTER': 0,
    'MATCHES': 0,
    'PAINTING': 15,
    'RAG': 25,
    'SAW': 24,
    'WIRE': 20,
    'CLOAK': 15,
    'CLOCK': 8,
    'CORD': 0,
    'CORRIDOR': 0,
    'CUPBOARD': 0,
    'DESK': 7,
    'DOG': 26,
    'DOOR': 5,
    'EMBERS': 0,
    'FIREPLACE': 8,
    'GATE': 26,
    'HATCH': 21,
    'PASSAGEWAY': 0,
    'RAT': 1,
    'SAFE': 0,
    'SHELVES': 16,
    'SINK': 3,
    'TABLE': 21,
    'ANNEXE': 0,
  };
  static const portable = {
    'BALL',
    'BAR',
    'BAR PIECES',
    'BIBLE',
    'BOOK',
    'WINE',
    'BREAD',
    'CANDLE',
    'LIT CANDLE',
    'CHAIR',
    'CHEST',
    'COAL',
    'CRUCIFIX',
    'GOBLET',
    'WATER',
    'GOBLET OF WATER',
    'HOLY WATER',
    'HAMMER',
    'IRON',
    'KEY',
    'GATE KEY',
    'KNIFE',
    'LETTER',
    'MATCHES',
    'PAINTING',
    'RAG',
    'SAW',
    'WIRE',
  };

  int room = 1;
  int moves = 0;
  int candleLife = candleBurnTurns;
  int cloakTurns = 0;
  String outcome = 'playing';
  bool awaitingCombination = false;
  final Map<String, int> locations = Map.of(initialLocations);
  final Map<String, bool> flags = {};
  final List<String> messages = [];
  bool describeRoom = false;

  List<String> get inventory => locations.keys.where(held).toList();
  int get inventoryLoad => inventory.fold(0, (n, o) => n + weight(o));
  static int weight(String object) => object == 'IRON' ? 4 : 1;
  bool held(String object) => locations[object] == -1;
  bool here(String object) => locations[object] == room;
  bool present(String object) => held(object) || here(object);
  bool flag(String name) => flags[name] == true;
  bool get isPlaying => outcome == 'playing';
  bool get hasLight => present('LIT CANDLE');
  static bool roomNeedsLight(int id) => id > 14 && id != 27;
  bool get isDark => roomNeedsLight(room) && !hasLight;
  List<String> get visible => isDark ? [] : locations.keys.where(here).toList();
  void say(String message) => messages.add(message);

  Map<String, int> exits(Map<String, int> base) {
    final result = Map<String, int>.of(base);
    if (room == 14) result['E'] = 15;
    if (room == 17) {
      result.remove('D');
      if (flag('table_pushed')) result['W'] = 16;
    }
    return result;
  }

  static const _verbs = <String, String>{
    'WALK': 'GO',
    'EXAM': 'LOOK',
    'X': 'LOOK',
    'L': 'LOOK',
    'SEAR': 'GET',
    'TAKE': 'GET',
    'GRAB': 'GET',
    'LIFT': 'GET',
    'PICK': 'GET',
    'LEAV': 'DROP',
    'THRO': 'THROW',
    'TOSS': 'THROW',
    'UNLO': 'OPEN',
    'LOCK': 'CLOSE',
    'BURN': 'LIGHT',
    'LIGH': 'LIGHT',
    'EXTI': 'EXTINGUISH',
    'SNUF': 'EXTINGUISH',
    'INVE': 'INVENTORY',
    'I': 'INVENTORY',
    'EMPT': 'POUR',
    'SMAS': 'CUT',
    'BREA': 'CUT',
    'CHOP': 'CUT',
    'DRIN': 'DRINK',
    'OFFE': 'FEED',
    'EXOR': 'EXORCISE',
    'CLIM': 'CLIMB',
    'REMO': 'REMOVE',
    'SCOR': 'SCORE',
    'PUNC': 'HIT',
    'STRI': 'HIT',
    'HAMM': 'HIT',
    'PRES': 'PUSH',
    'SLEE': 'SLEEP',
    'STAN': 'STAND',
    'SHOU': 'SHOUT',
    'TOUC': 'TOUCH',
    'SHAK': 'SHAKE',
  };
  static const _directions = {
    'N': 'N',
    'NORT': 'N',
    'S': 'S',
    'SOUT': 'S',
    'E': 'E',
    'EAST': 'E',
    'W': 'W',
    'WEST': 'W',
    'U': 'U',
    'UP': 'U',
    'D': 'D',
    'DOWN': 'D',
  };
  static String _prefix(String word) =>
      word.length > 4 ? word.substring(0, 4) : word;

  String noun(String text) {
    // Explicit UI names preserve state variants; original four-letter aliases
    // resolve to the current variant of each physical object.
    if (text == 'BAR PIECES' ||
        text == 'HOLY WATER' ||
        text == 'GOBLET OF WATER' ||
        text == 'GATE KEY' ||
        text == 'LIT CANDLE') {
      return text;
    }
    final prefix = _prefix(text);
    if (prefix == 'CAND') {
      return locations['LIT CANDLE'] != 0 ? 'LIT CANDLE' : 'CANDLE';
    }
    if (prefix == 'BAR') {
      return locations['BAR PIECES'] != 0 ? 'BAR PIECES' : 'BAR';
    }
    if (prefix == 'KEY' || prefix == 'SKEL') {
      return locations['KEY'] != 0 ? 'KEY' : 'GATE KEY';
    }
    if (prefix == 'GOBL') {
      if (locations['HOLY WATER'] != 0) return 'HOLY WATER';
      if (locations['GOBLET OF WATER'] != 0) return 'GOBLET OF WATER';
      return 'GOBLET';
    }
    const aliases = {
      'BOTT': 'WINE',
      'LOAF': 'BREAD',
      'CLAW': 'HAMMER',
      'CARV': 'KNIFE',
      'OIL': 'RAG',
      'GRAN': 'CLOCK',
      'CROS': 'CRUCIFIX',
      'GHOS': 'CLOAK',
      'POOL': 'TABLE',
      'NAIL': 'NAILS',
      'GATE': 'GATE',
      'AROU': 'AROUND',
    };
    if (aliases.containsKey(prefix)) return aliases[prefix]!;
    for (final object in initialLocations.keys) {
      if (_prefix(object) == prefix) return object;
    }
    return text;
  }

  /// One command transaction, including failed commands. Inventory and blank
  /// input do not advance BASIC's turn loop. Effects precede timed hazards.
  void execute(String input, Map<String, int> baseExits) {
    messages.clear();
    describeRoom = false;
    final command = input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    if (command.isEmpty || !isPlaying) return;
    if (awaitingCombination) {
      awaitingCombination = false;
      if (command == '1327') {
        flags['safe_open'] = true;
        say("You've cracked it!");
      } else {
        die('A violent surge of electricity! You drop dead on the floor.');
      }
      finishTurn();
      return;
    }
    final words = command.split(' ');
    final verbPrefix = _prefix(words.first);
    final verb = _verbs[verbPrefix] ?? words.first;
    final object = noun(words.skip(1).join(' '));
    if (verb == 'INVENTORY') {
      say(
        inventory.isEmpty
            ? 'You are carrying nothing whatsoever.'
            : 'You are carrying: ${inventory.join(', ')}',
      );
      return;
    }
    final direction =
        _directions[verbPrefix] ??
        (verb == 'GO' ? _directions[_prefix(object)] : null);
    if (direction != null) {
      move(direction, exits(baseExits));
    } else {
      final emptyContents =
          verb == 'DROP' && _prefix(words.skip(1).join(' ')) == 'WATE';
      act(emptyContents ? 'POUR' : verb, object);
    }
    // BASIC INPUT inside OPEN SAFE does not return to the turn loop until the
    // combination is submitted. Two UI submissions are one adventure turn.
    if (!awaitingCombination) finishTurn();
  }

  void finishTurn() {
    moves++;
    if (locations['LIT CANDLE'] != 0 && candleLife > 0) {
      candleLife--;
      if (candleLife == 0) {
        locations['LIT CANDLE'] = 0;
        say('The candle is dead.');
      } else if (candleLife == 10 || candleLife < 5) {
        say('The candle is flickering!!');
      }
    }
    if (!isPlaying) return;
    if (room == 15 && !flag('cloak_exorcised')) {
      cloakTurns++;
      if (cloakTurns >= 3) {
        die(
          'Cold, bony fingers grip your throat, and you slip into eternal darkness...',
        );
      } else if (!isDark) {
        say(
          cloakTurns == 1
              ? 'A bloodstained cloak is standing upright!!'
              : 'A bloodstained cloak is moving slowly towards you!!',
        );
      }
    }
    if (room == 27) {
      outcome = 'won';
      say(
        'CONGRATULATIONS!! You have escaped into an open courtyard. Evil forces try to force you back, but freedom is just a few steps away...',
      );
    }
  }

  void die(String message) {
    outcome = 'dead';
    say(message);
  }

  void enter(int destination) {
    room = destination;
    flags['on_chair'] = false;
    flags['cord_pulled'] = false;
    if (room == 16) flags['table_pushed'] = false;
    if (room == 17) locations['PASSAGEWAY'] = 0;
    if (room == 23 && !flag('door_propped')) {
      locations['DOOR'] = 23;
      say('The door slammed shut behind you!!');
    }
    describeRoom = true;
  }

  void move(String direction, Map<String, int> available) {
    if (room == 1 &&
        direction == 'U' &&
        !held('BIBLE') &&
        !flag('cloak_exorcised')) {
      say("I'm too scared. It looks very creepy!!");
    } else if (room == 14 &&
        direction == 'E' &&
        !flag('cloak_exorcised') &&
        (!held('BIBLE') || !held('CRUCIFIX'))) {
      say("That's the haunted bedroom!!");
    } else if (room == 23 && direction == 'U' && !flag('door_propped')) {
      say('The door is locked.');
    } else if (room == 26 && direction == 'E' && here('DOG')) {
      say('The dog snarls, revealing bloodstained fangs!!');
    } else if (room == 26 && direction == 'E' && !flag('gates_unlocked')) {
      say('The gates are locked.');
    } else if (available.containsKey(direction)) {
      if (isDark) say("It's difficult, moving in the dark!!");
      enter(available[direction]!);
    } else {
      say("You can't go that way.");
    }
  }

  bool requirePresent(String object) {
    if (present(object)) return true;
    say("I don't see it here.");
    return false;
  }

  bool requireHeld(String object) {
    if (held(object)) return true;
    say("You aren't carrying it!!");
    return false;
  }

  void reveal(String object) {
    if (locations[object] == 0) locations[object] = room;
    say('I can see something!');
  }

  void blessWater() {
    if (held('BIBLE') && held('CRUCIFIX') && held('GOBLET OF WATER')) {
      locations['GOBLET OF WATER'] = 0;
      locations['HOLY WATER'] = -1;
      say('HOLY WATER!!');
    }
  }

  void act(String verb, String object) {
    switch (verb) {
      case 'GO':
        if (object == 'CORRIDOR' && room == 1) {
          if (!requirePresent(object)) return;
          if (!held('KNIFE')) {
            say('What about the rat?');
            return;
          }
          enter(5);
        } else if (object == 'DOOR' && room == 5) {
          if (!flag('door_unlocked')) {
            say('The door is locked.');
            return;
          }
          enter(23);
        } else if (object == 'PASSAGEWAY' && room == 16 && here(object)) {
          enter(17);
        } else if (object == 'ANNEXE' && room == 13 && here(object)) {
          enter(12);
        } else if (object == 'HATCH' && room == 21 && flag('hatch_open')) {
          enter(20);
        } else if (object == 'GATE' && room == 26) {
          move('E', {'E': 27});
        } else {
          say("You can't go that way.");
        }
      case 'LOOK':
      case 'EXAMINE':
        if (isDark) {
          say("It's too dark to see.");
          return;
        }
        if (object.isEmpty || object == 'AROUND') {
          if (room == 1 && !here('CORRIDOR')) reveal('CORRIDOR');
          if (room == 3 && !here('CUPBOARD')) reveal('CUPBOARD');
          if (room == 10 && !flag('cord_held')) reveal('CORD');
          describeRoom = true;
          return;
        }
        if (!requirePresent(object)) return;
        switch (object) {
          case 'SINK':
            reveal('WATER');
          case 'CUPBOARD':
            reveal('MATCHES');
          case 'FIREPLACE':
            reveal('COAL');
          case 'DESK':
            reveal('BIBLE');
          case 'SHELVES':
            reveal('BOOK');
          case 'TABLE':
            reveal('BALL');
          case 'CHEST':
            if (flag('chest_broken') && !flag('small_key_found')) {
              reveal('KEY');
            } else {
              say('An old wooden chest.');
            }
          case 'SAFE':
            if (flag('safe_open') && !flag('gate_key_found')) {
              reveal('GATE KEY');
            } else {
              say('A locked wall safe.');
            }
          case 'BIBLE':
            say('It falls open at the first page.');
          case 'BOOK':
            say('THE EXORCIST - How apt.');
          case 'WINE':
            say('French red. Maybe you should try it.');
          case 'PAINTING':
            say("It's an oil painting of two horses.");
          case 'CLOCK':
            say("It's getting terribly late!!");
          case 'DOG':
            say('It has eyes like red embers.');
          case 'RAT':
            say('Looks pretty nasty!!');
          case 'BALL':
            say("It's a no.7");
          case 'CORD':
            say(
              flag('cord_held')
                  ? 'The cord is held tight.'
                  : 'A silk cord hangs from the ceiling.',
            );
          default:
            say("I don't notice anything in particular.");
        }
      case 'GET':
        take(object);
      case 'DROP':
        drop(object);
      case 'THROW':
        if (!requireHeld(object)) return;
        drop(object);
        if (object == 'LIT CANDLE') {
          locations[object] = 0;
          locations['CANDLE'] = room;
          say('It went out!!');
        } else if (object == 'WINE') {
          locations[object] = 0;
          say('SPLASH!!!');
        }
      case 'OPEN':
        open(object);
      case 'LIGHT':
        light(object);
      case 'EXTINGUISH':
        if (object == 'LIT CANDLE' && requireHeld(object)) {
          locations[object] = 0;
          locations['CANDLE'] = -1;
          say('It went out!!');
        } else {
          say("It's not lit!!");
        }
      case 'READ':
        if (!requirePresent(object)) return;
        switch (object) {
          case 'BIBLE':
            say('In the beginning God created the heaven and the earth...');
          case 'BOOK':
            say('THE EXORCIST - How apt.');
          case 'LETTER':
            say('3 CEMETARY WAY, GOOLE... One for free through heaven...?');
          default:
            say("I don't understand you.");
        }
      case 'CUT':
        if (!requireHeld(object)) return;
        if (room != 25 || !held('SAW')) {
          say("You can't do that just yet.");
          return;
        }
        if (object == 'BAR') {
          locations[object] = 0;
          locations['BAR PIECES'] = -1;
          say('Ok');
        } else if (object == 'BAR PIECES') {
          locations[object] = 0;
          say('The pieces were so small, I lost them.');
        } else {
          say('Vandal!!');
        }
      case 'MAKE':
        if (object == 'CRUCIFIX' &&
            room == 25 &&
            held('BAR PIECES') &&
            held('WIRE')) {
          locations['BAR PIECES'] = 0;
          locations['WIRE'] = 0;
          locations['CRUCIFIX'] = room;
          say('That should prove useful.');
        } else {
          say('What with?');
        }
      case 'KICK':
      case 'KILL':
      case 'HIT':
        if (!requirePresent(object)) return;
        if (object == 'RAT' || object == 'DOG') {
          die(
            object == 'RAT'
                ? 'The rat attacks you! This game is over.'
                : 'The dog tears you apart!!',
          );
        } else if (verb == 'KICK' &&
            object == 'CHEST' &&
            here(object) &&
            !flag('chest_broken')) {
          flags['chest_broken'] = true;
          say('The lid flew open!');
        } else {
          say('Temper!!');
        }
      case 'PUSH':
      case 'PULL':
        if (!requirePresent(object)) return;
        if (object == 'BOOK' && room == 16 && here(object)) {
          locations['PASSAGEWAY'] = room;
          say('Something happened!');
        } else if (object == 'TABLE' && room == 21) {
          flags['table_pushed'] = true;
          say('Something happened!');
        } else if (object == 'CORD' &&
            room == 10 &&
            verb == 'PULL' &&
            !flag('cord_held')) {
          flags['cord_pulled'] = true;
          say('A strange rumbling noise...');
        } else {
          say('Ok. Nothing happens.');
        }
      case 'CLIMB':
        if (object == 'CHAIR' && here(object)) {
          flags['on_chair'] = true;
          say("Ok, you're standing on the chair.");
        } else {
          say('You must be joking!!');
        }
      case 'REMOVE':
        if ((object == 'NAILS' || object == 'HATCH') &&
            room == 21 &&
            held('HAMMER')) {
          flags['hatch_open'] = true;
          say('Ok');
        } else {
          say("You can't do that just yet.");
        }
      case 'EXORCISE':
        if (object == 'CLOAK' &&
            room == 15 &&
            !flag('cloak_exorcised') &&
            held('BIBLE') &&
            held('CRUCIFIX') &&
            held('HOLY WATER')) {
          flags['cloak_exorcised'] = true;
          locations['HOLY WATER'] = 0;
          locations['GOBLET'] = -1;
          say('Something happened in a BLINDING flash of light!!');
        } else {
          say("You can't do that just yet.");
        }
      case 'FEED':
        if (!requirePresent(object)) return;
        if ((object == 'RAT' || object == 'DOG') && held('BREAD')) {
          locations['BREAD'] = 0;
          say('It nearly took my hand off!!');
        } else {
          say("You can't do that just yet.");
        }
      case 'EAT':
        if (object == 'BREAD' && requireHeld(object)) {
          locations[object] = 0;
          say('Revolting!!');
        } else {
          say('You must be joking!!');
        }
      case 'DRINK':
        if (object == 'WINE' && requireHeld(object)) {
          locations[object] = 0;
          say('WOW! MY HEAD IS SPINNING!!');
        } else {
          emptyWater();
        }
      case 'POUR':
        if (object == 'WATER' ||
            object == 'GOBLET OF WATER' ||
            object == 'HOLY WATER') {
          emptyWater();
        } else {
          say("I don't understand you.");
        }
      case 'FILL':
        say('What with?');
      case 'WAIT':
        say('Time passes...');
      case 'HELP':
        say("Sorry, you're on your own. PERSEVERE.");
      case 'SAVE':
        say('Game saved.');
      case 'SCORE':
        say('Give yourself 10/10 if you can get out alive.');
      default:
        say("I don't understand you.");
    }
  }

  void take(String object) {
    if (!portable.contains(object)) {
      say('Not a very good idea.');
      return;
    }
    if (held(object)) {
      say('You already have it.');
      return;
    }
    if (inventoryLoad >= capacity) {
      say('You are carrying too much.');
      return;
    }
    if (object == 'WATER' && room == 3) {
      if (!requirePresent('WATER')) return;
      if (!held('GOBLET')) {
        say("You don't have anything to put it in.");
        return;
      }
      locations['GOBLET'] = 0;
      locations['GOBLET OF WATER'] = -1;
      blessWater();
      say('Ok');
      return;
    }
    if (!here(object)) {
      say("I don't see it here.");
      return;
    }
    if (inventoryLoad + weight(object) > capacity) {
      say('You are carrying too much.');
      return;
    }
    if (object == 'MATCHES' && !flag('matches_reached') && !flag('on_chair')) {
      say("You can't do that just yet.");
      return;
    }
    locations[object] = -1;
    if (object == 'BIBLE' && locations['LETTER'] == 0) {
      locations['LETTER'] = room;
    }
    if (object == 'KEY') flags['small_key_found'] = true;
    if (object == 'GATE KEY') flags['gate_key_found'] = true;
    if (object == 'MATCHES') flags['matches_reached'] = true;
    if (object == 'PAINTING' && locations['SAFE'] == 0) {
      locations['SAFE'] = room;
    }
    if (object == 'CHAIR') flags['on_chair'] = false;
    if (object == 'CHEST') {
      flags['door_propped'] = false;
      locations['DOOR'] = 5;
    }
    if (object == 'IRON') {
      locations['CORD'] = 10;
      locations['ANNEXE'] = 0;
      flags['cord_held'] = false;
    }
    blessWater();
    say('Ok');
  }

  void drop(String object) {
    // GOBLET resolves to its current filled or empty container variant.
    if (!requireHeld(object)) return;
    locations[object] = room;
    if (object == 'CHEST' && room == 5 && flag('door_unlocked')) {
      flags['door_propped'] = true;
      locations['DOOR'] = 5;
    }
    if (object == 'IRON' && room == 10 && flag('cord_pulled')) {
      locations['ANNEXE'] = 13;
      flags['cord_held'] = true;
    }
    say('Ok');
  }

  void open(String object) {
    if (!requirePresent(object)) return;
    if (object == 'DOOR') {
      if (room == 23) {
        say('The latch is broken!!');
        return;
      }
      if (flag('door_unlocked')) {
        say("It's OPEN.");
        return;
      }
      if (!held('KEY')) {
        say("You can't do that just yet.");
        return;
      }
      flags['door_unlocked'] = true;
      locations['KEY'] = 0;
      flags['door_propped'] = here('CHEST');
      say('Ok');
    } else if (object == 'GATE') {
      if (here('DOG')) {
        say('The dog snarls, revealing bloodstained fangs!!');
        return;
      }
      if (!held('GATE KEY')) {
        say("You can't do that just yet.");
        return;
      }
      flags['gates_unlocked'] = true;
      say('Ok');
    } else if (object == 'SAFE') {
      if (flag('safe_open')) {
        say("It's OPEN.");
        return;
      }
      awaitingCombination = true;
      say('Enter the 4 digit combination');
    } else if (object == 'CHEST' || object == 'HATCH') {
      say('Tell me how.');
    } else {
      say('Ok');
    }
  }

  void light(String object) {
    if (!requirePresent(object)) return;
    if (object == 'LIT CANDLE' || object == 'EMBERS') {
      say("It's already lit!!");
      return;
    }
    if (!held('MATCHES')) {
      say("You can't do that just yet.");
      return;
    }
    if (object == 'CANDLE' && held(object) && candleLife > 0) {
      locations[object] = 0;
      locations['LIT CANDLE'] = -1;
      say('Ok');
    } else if ((object == 'COAL' || object == 'RAG') &&
        here('COAL') &&
        here('RAG')) {
      locations['COAL'] = 0;
      locations['RAG'] = 0;
      locations['EMBERS'] = room;
      if (here('DOG')) {
        locations['DOG'] = 0;
        flags['dog_terrified'] = true;
        say(
          "The coals glow like the dog's eyes, and he runs away, terrified!!",
        );
      } else {
        say('Ok');
      }
    } else if (object == 'RAG' || object == 'MATCHES') {
      locations[object] = 0;
      say('Burns away nicely!!');
    } else {
      say("You can't do that just yet.");
    }
  }

  void emptyWater() {
    if (!held('GOBLET OF WATER') && !held('HOLY WATER')) {
      say("You aren't carrying it!!");
      return;
    }
    locations['GOBLET OF WATER'] = 0;
    locations['HOLY WATER'] = 0;
    locations['GOBLET'] = -1;
    say('SPLASH!!!');
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'currentRoomId': room,
    'moveCount': moves,
    'objectLocations': Map<String, int>.of(locations),
    'gameFlags': Map<String, bool>.of(flags),
    'candleLife': candleLife,
    'cloakTurns': cloakTurns,
    'outcome': outcome,
    'awaitingCombination': awaitingCombination,
  };

  AdventureEngine();

  factory AdventureEngine.fromJson(Map<String, dynamic> data) {
    final engine = AdventureEngine();
    engine.room = data['currentRoomId'] as int? ?? 1;
    if (engine.room < 1 || engine.room > 27) {
      throw const FormatException('Invalid room');
    }
    engine.moves = data['moveCount'] as int? ?? 0;
    engine.locations.addAll(
      Map<String, int>.from(data['objectLocations'] ?? {}),
    );
    engine.flags.addAll(Map<String, bool>.from(data['gameFlags'] ?? {}));
    engine.candleLife = (data['candleLife'] as int? ?? candleBurnTurns).clamp(
      0,
      candleBurnTurns,
    );
    engine.cloakTurns = data['cloakTurns'] as int? ?? 0;
    engine.outcome = data['outcome'] as String? ?? 'playing';
    engine.awaitingCombination = data['awaitingCombination'] as bool? ?? false;
    if (data['schemaVersion'] != 2) {
      // v1 duplicated inventory and locations, and left consumed variants held.
      final inventory = List<String>.from(data['inventory'] ?? []);
      engine.locations.updateAll((key, value) => value == -1 ? 0 : value);
      for (final object in inventory) {
        engine.locations[object] = -1;
      }
      if (engine.held('WATER')) {
        engine.locations['WATER'] = 3;
        engine.locations['GOBLET OF WATER'] = -1;
      }
      for (final variants in [
        ['CANDLE', 'LIT CANDLE'],
        ['BAR', 'BAR PIECES'],
        ['GOBLET', 'GOBLET OF WATER', 'HOLY WATER'],
      ]) {
        final heldVariants = variants.where(engine.held).toList();
        if (heldVariants.isNotEmpty) {
          for (final object in variants) {
            if (object != heldVariants.last) engine.locations[object] = 0;
          }
        }
      }
      engine.locations['DOG'] =
          engine.flag('dog_terrified') || engine.locations['EMBERS'] == 26
          ? 0
          : 26;
      engine.locations['DOOR'] = 5;
      engine.flags['door_propped'] =
          engine.flag('door_unlocked') && engine.locations['CHEST'] == 5;
      engine.flags['matches_reached'] = engine.locations['MATCHES'] != 0;
      engine.flags['small_key_found'] =
          engine.flag('door_unlocked') || engine.locations['KEY'] != 0;
      if (engine.flag('door_unlocked')) engine.locations['KEY'] = 0;
      engine.flags['cord_held'] = engine.locations['ANNEXE'] == 13;
      if (engine.flag('cord_held')) engine.locations['CORD'] = 10;
      if (engine.candleLife == 0 && engine.locations['CANDLE'] != 0) {
        engine.candleLife = candleBurnTurns;
      }
      for (final object in engine.inventory.reversed) {
        if (engine.inventoryLoad <= capacity) break;
        engine.locations[object] = engine.room;
      }
      engine.say(
        'Saved game upgraded to original rules. Any excess carried items were placed in this room.',
      );
    }
    return engine;
  }
}
