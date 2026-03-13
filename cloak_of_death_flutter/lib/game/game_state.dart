import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_data.dart';
import '../models/room.dart';

/// Manages the current game state, persisting to SharedPreferences
class GameState extends ChangeNotifier {
  GameData? _gameData;
  int _currentRoomId = 1;
  List<String> _inventory = [];
  Map<String, bool> _gameFlags = {};
  List<String> _outputMessages = [];
  int _moveCount = 0;
  String? _selectedObject;

  Map<String, int> _objectLocations = {};

  double _pixelRenderSpeed = 2000.0;
  bool _autoAnimateRooms = true;
  bool _showDebugInfo = false;

  int _candleLife = 0;

  static const int maxInventory = 12;

  GameData? get gameData => _gameData;
  Room? get currentRoom => _gameData?.getRoomById(_currentRoomId);
  List<String> get inventory => List.unmodifiable(_inventory);
  int get inventoryCount => _inventory.length;
  List<String> get outputMessages => List.unmodifiable(_outputMessages);
  int get moveCount => _moveCount;
  int get currentRoomId => _currentRoomId;
  String? get selectedObject => _selectedObject;
  double get pixelRenderSpeed => _pixelRenderSpeed;
  bool get autoAnimateRooms => _autoAnimateRooms;
  bool get showDebugInfo => _showDebugInfo;
  bool get isDark => _currentRoomId == 25 || _currentRoomId == 26;
  bool get hasLitCandle => _inventory.contains('LIT CANDLE');
  bool get isTooDarkToSee => isDark && !hasLitCandle;

  Future<void> initialize() async {
    _gameData = await GameData.loadFromAssets();
    await _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('cloak_save_state');

    if (savedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(savedData);
        _currentRoomId = data['currentRoomId'] ?? 1;
        _inventory = List<String>.from(data['inventory'] ?? []);
        _gameFlags = Map<String, bool>.from(data['gameFlags'] ?? {});
        _objectLocations = Map<String, int>.from(data['objectLocations'] ?? {});
        _moveCount = data['moveCount'] ?? 0;
        _candleLife = data['candleLife'] ?? 0;
        _outputMessages = List<String>.from(data['outputMessages'] ?? []);
      } catch (e) {
        _initNewGame();
      }
    } else {
      _initNewGame();
    }
    notifyListeners();
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'currentRoomId': _currentRoomId,
      'inventory': _inventory,
      'gameFlags': _gameFlags,
      'objectLocations': _objectLocations,
      'moveCount': _moveCount,
      'candleLife': _candleLife,
      'outputMessages': _outputMessages,
    };
    await prefs.setString('cloak_save_state', json.encode(data));
  }

  void _initNewGame() {
    _currentRoomId = 1;
    _inventory = [];
    _gameFlags = {
      'safe_open': false,
      'cupboard_open': false,
      'dog_terrified': false,
      'door_unlocked': false,
      'gates_unlocked': false,
      'chest_broken': false,
      'painting_moved': false,
      'hatch_open': false,
      'bookshelf_moved': false,
      'cloak_exorcised': false,
    };
    _objectLocations = {
      'CHAIR': 2,
      'MATCHES': 0,
      'KNIFE': 0,
      'COAL': 0,
      'BIBLE': 0,
      'LETTER': 0,
      'CHEST': 6,
      'KEY': 0,
      'CANDLE': 4,
      'RAG': 25,
      'HAMMER': 24,
      'WIRE': 22,
      'SAW': 24,
      'BAR': 25,
      'CRUCIFIX': 0,
      'IRON': 20,
      'GOBLET': 12,
      'WINE': 21,
      'WATER': 0,
      'BREAD': 3,
      'KNIFE': 3,
      'PAINTING': 13,
      'SAFE': 0,
      'GATE KEY': 0,
      'RAT': 1,
      'CUPBOARD': 0,
      'SINK': 3,
    };
    _moveCount = 0;
    _candleLife = 0;
    _outputMessages = [
      'Welcome to CLOAK OF DEATH',
      'by David Cockram. Remember, in the dead',
      'of night,no-one will hear your SCREAMS!!',
      '',
    ];
    describeCurrentRoom();
  }

  void setPixelRenderSpeed(double speed) {
    _pixelRenderSpeed = speed.clamp(1.0, 5000.0);
    notifyListeners();
  }

  void setAutoAnimateRooms(bool value) {
    _autoAnimateRooms = value;
    notifyListeners();
  }

  void setShowDebugInfo(bool value) {
    _showDebugInfo = value;
    notifyListeners();
  }

  Map<String, int> getAvailableExits() {
    return currentRoom?.connections ?? {};
  }

  List<String> getVisibleObjects() {
    if (isTooDarkToSee) return [];

    List<String> visible = [];
    _objectLocations.forEach((obj, room) {
      if (room == _currentRoomId) visible.add(obj);
    });

    if (_currentRoomId == 8) {
      visible.add('FIREPLACE');
    }
    if (_currentRoomId == 7) {
      visible.add('DESK');
    }
    if (_currentRoomId == 26 && !_gameFlags['dog_terrified']!) {
      visible.add('DOG');
    }
    if (_currentRoomId == 16) {
      visible.add('SHELVES');
    }
    if (_currentRoomId == 18) {
      visible.add('TABLE');
    }

    return visible;
  }

  void selectObject(String object) {
    _selectedObject = object;
    notifyListeners();
  }

  void clearSelectedObject() {
    _selectedObject = null;
    notifyListeners();
  }

  List<String> getAvailableActionsForObject(String object) {
    final List<String> actions = ['LOOK', 'EXAMINE'];
    final bool inInventory = _inventory.contains(object);
    
    if (inInventory) {
      actions.add('DROP');
    } else if (_objectLocations[object] == _currentRoomId || 
               (object == 'SAFE' && _currentRoomId == 4) ||
               (object == 'DOOR' && (_currentRoomId == 2 || _currentRoomId == 6)) ||
               (object == 'GATE' && _currentRoomId == 7)) {
      actions.add('GET');
    }

    switch (object) {
      case 'DOOR': case 'GATE': case 'SAFE': actions.addAll(['OPEN', 'UNLOCK', 'PUSH', 'PULL']); break;
      case 'CANDLE': case 'LIT CANDLE': actions.addAll(['LIGHT', 'EXTINGUISH']); break;
      case 'MATCHES': actions.add('LIGHT'); break;
      case 'LETTER': case 'BIBLE': actions.add('READ'); break;
      case 'KEY': case 'GATE KEY': case 'HAMMER': case 'SAW': case 'BAR': case 'WIRE': case 'KNIFE': case 'HOLY WATER': case 'WATER': case 'CRUCIFIX': actions.add('USE'); break;
      case 'CHAIR': actions.add('CLIMB'); break;
      case 'BREAD': actions.add('USE'); break;
    }
    return actions.toSet().toList();
  }

  void executeObjectVerb(String verb, String object) {
    final command = '$verb $object';
    _selectedObject = null;
    processCommand(command);
  }

  List<String> _wrapText(String text, {int width = 40}) {
    if (text.isEmpty) return [];
    
    final words = text.split(' ');
    final lines = <String>[];
    String currentLine = '';

    for (final word in words) {
      if (word.isEmpty) continue;
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + 1 + word.length <= width) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  void addMessage(String message) {
    if (message.isEmpty) {
      _outputMessages.add('');
    } else {
      _outputMessages.addAll(_wrapText(message));
    }
    
    if (_outputMessages.length > 50) {
      _outputMessages.removeRange(0, _outputMessages.length - 50);
    }
  }

  void describeCurrentRoom() {
    final room = currentRoom;
    if (room == null) return;

    addMessage('');
    if (isTooDarkToSee) {
      addMessage('► IT\'S TOO DARK TO SEE');
    } else {
      addMessage('You are ${room.description}.');
      final exits = getAvailableExits();
      if (exits.isNotEmpty) {
        final mappedExits = exits.keys.map((e) {
          switch (e) {
            case 'N': return 'North';
            case 'S': return 'South';
            case 'E': return 'East';
            case 'W': return 'West';
            case 'U': return 'Up';
            case 'D': return 'Down';
            default: return e;
          }
        }).join(",");
        addMessage('Exits are $mappedExits.');
      }

      final visible = getVisibleObjects();
      if (visible.isNotEmpty) {
        final mappedItems = visible.map((obj) {
          switch (obj) {
            case 'RAT': return 'Hungry looking rat.';
            case 'CHAIR': return 'Wicker chair.';
            case 'BREAD': return 'Half eaten loaf of bread.';
            case 'KNIFE': return 'Carving knife.';
            case 'CUPBOARD': return 'Tall cupboard.';
            case 'SINK': return 'Sink.';
            case 'FIREPLACE': return 'Fireplace.';
            case 'COAL': return 'Lumps of coal.';
            case 'CLOCK': return 'Grandfather clock.';
            case 'DESK': return 'Writing desk.';
            case 'BIBLE': return 'Leather bound BIBLE.';
            case 'LETTER': return 'Letter.';
            case 'CHEST': return 'Old wooden chest.';
            case 'DOOR': return 'Cellar door.';
            case 'KEY': return 'Small key.';
            case 'CANDLE': return 'Candle.';
            case 'IRON': return 'Huge lump of iron.';
            case 'SAW': return 'Rusty saw.';
            case 'HAMMER': return 'Claw hammer.';
            case 'BAR': return 'SILVER BAR.';
            case 'RAG': return 'Oil soaked rag.';
            case 'DOG': return 'Ferocious dog.';
            case 'GATE': return 'Heavy iron gates.';
            case 'EMBERS': return 'Burning embers.';
            case 'BOOK': return 'Book.';
            case 'SHELVES': return 'Shelves full of books.';
            case 'PASSAGEWAY': return 'Secret passageway.';
            case 'WATER': return 'Water.';
            case 'WINE': return 'Bottle of wine.';
            default: return '${obj[0]}${obj.substring(1).toLowerCase()}.';
          }
        }).join(" ");
        addMessage('Visible items: $mappedItems');
      }
    }
    addMessage('');
  }

  int _getVerbId(String verb) {
    switch (verb) {
      case 'WALK': case 'GO': case 'N': case 'S': case 'E': case 'W': case 'U': case 'D':
      case 'NORT': case 'NORTH': case 'SOUT': case 'SOUTH': case 'EAST': case 'WEST': case 'UP': case 'DOWN': return 1;
      case 'LOOK': case 'EXAM': case 'EXAMINE': case 'L': case 'X': return 2;
      case 'SEAR': case 'SEARCH': case 'TAKE': case 'GRAB': case 'LIFT': case 'GET': case 'PICK': return 3;
      case 'LEAV': case 'LEAVE': case 'DROP': case 'THRO': case 'THROW': case 'TOSS': return 4;
      case 'OPEN': return 5;
      case 'UNLO': case 'UNLOCK': return 6;
      case 'CLOS': case 'CLOSE': case 'LOCK': return 7;
      case 'BURN': case 'LIGH': case 'LIGHT': return 8;
      case 'EXTI': case 'EXTINGUISH': case 'SNUF': case 'SNUFF': return 9;
      case 'READ': return 10;
      case 'HELP': return 11;
      case 'POUR': case 'EMPT': case 'EMPTY': return 12;
      case 'CHOP': case 'SMAS': case 'SMASH': case 'BREA': case 'BREAK': return 13;
      case 'QUIT': return 14;
      case 'INVE': case 'INVENTORY': case 'I': return 15;
      case 'DRIN': case 'DRINK': return 16;
      case 'EAT': return 17;
      case 'SLEE': case 'SLEEP': return 18;
      case 'FEED': case 'OFFE': case 'OFFER': return 19;
      case 'GIVE': return 20;
      case 'PUNC': case 'PUNCH': case 'STRI': case 'STRIKE': case 'HAMM': return 21;
      case 'WAIT': return 22;
      case 'KICK': return 23;
      case 'PUSH': case 'PULL': case 'PRES': case 'PRESS': return 24;
      case 'TOUC': case 'TOUCH': case 'CLIM': case 'CLIMB': return 25;
      case 'STAN': case 'STAND': return 26;
      case 'EXOR': case 'EXORCISE': return 27;
      case 'MAKE': return 28;
      case 'SAVE': return 29;
      case 'FUCK': case 'PISS': return 30; // Original ATARI easter eggs
      case 'JUMP': return 31;
      case 'KILL': return 32;
      case 'FILL': return 33;
      case 'SCOR': case 'SCORE': return 34;
      case 'WAVE': return 35;
      case 'SHAK': case 'SHAKE': return 36;
      case 'WEAR': return 37;
      case 'TIE': return 38;
      case 'SHOU': case 'SHOUT': return 39;
      case 'USE': case 'REMO': case 'REMOVE': case 'CUT': return 100;
      default: return 0;
    }
  }

  int _getNounId(String noun) {
    switch (noun) {
      case 'BALL': return 1;
      case 'BOOK': return 4;
      case 'BIBL': case 'BIBLE': return 5;
      case 'WINE': return 6;
      case 'BOTT': case 'BOTTLE': return 7;
      case 'BREA': case 'BREAD': return 8;
      case 'CAND': case 'CANDLE': case 'LIT CANDLE': return 10;
      case 'CHAI': case 'CHAIR': return 11;
      case 'CHES': case 'CHEST': return 12;
      case 'COAL': return 13;
      case 'CRUC': case 'CRUCIFIX': return 14;
      case 'GOBL': case 'GOBLET': return 15;
      case 'HAMM': case 'HAMMER': return 18;
      case 'SAW': return 19;
      case 'IRON': return 20;
      case 'KNIF': case 'KNIFE': return 21;
      case 'LETT': case 'LETTER': return 23;
      case 'MATC': case 'MATCHES': return 24;
      case 'PAIN': case 'PAINTING': return 25;
      case 'WIRE': return 27;
      case 'WATE': case 'WATER': return 28;
      case 'BAR': return 9;
      case 'RAG': return 20;
      case 'CLOA': case 'CLOAK': return 30;
      case 'CLOC': case 'CLOCK': case 'GRANDFATHER CLOCK': return 32;
      case 'CORD': return 33;
      case 'CORR': case 'CORRIDOR': return 35;
      case 'CUPB': case 'CUPBOARD': return 36;
      case 'DESK': return 37;
      case 'DOG': return 38;
      case 'DOOR': return 39;
      case 'EMBE': case 'EMBERS': return 41;
      case 'FIRE': case 'FIREPLACE': return 42;
      case 'GATE': case 'GATES': return 43;
      case 'HATC': case 'HATCH': return 44;
      case 'PASS': case 'PASSAGEWAY': return 46;
      case 'RAT': return 47;
      case 'SAFE': return 48;
      case 'SHEL': case 'SHELVES': return 50;
      case 'SINK': return 51;
      case 'TABL': case 'TABLE': return 52;
      case 'ANNE': case 'ANNEXE': return 53;
      case 'SKEL': case 'SKELETON KEY': case 'KEY': return 16;
      case 'GATE KEY': return 17;
      case 'NAIL': case 'NAILS': return 82;
      default: return 0;
    }
  }

  void processCommand(String command) {
    if (command.trim().isEmpty) return;

    addMessage('What shall I do?${command.toUpperCase()}');
    _moveCount++;
    if (_candleLife > 0 && hasLitCandle) {
      _candleLife--;
      if (_candleLife == 0) {
        _inventory.remove('LIT CANDLE');
        _inventory.add('CANDLE');
        addMessage('The candle is dead.');
      } else if (_candleLife < 10) {
        addMessage('The candle is flickering!!');
      }
    }

    if (command == '1327') {
      if (_currentRoomId == 13 && _gameFlags['painting_moved'] == true) {
        addMessage("You've cracked it!");
        _gameFlags['safe_open'] = true;
        _objectLocations['GATE KEY'] = 13;
        saveState();
        notifyListeners();
        return;
      } else {
        addMessage("I don't understand you.");
        saveState();
        notifyListeners();
        return;
      }
    }

    final words = command.trim().toUpperCase().split(RegExp(r'\s+'));
    final verbString = words[0];
    final nounString = words.length > 1 ? words.skip(1).join(' ') : '';

    int v = _getVerbId(verbString);
    if (v == 0) {
      addMessage("I don't recognise that VERB.");
      saveState();
      notifyListeners();
      return;
    }

    int o = 0;
    if (nounString.isNotEmpty) {
      if (['N', 'S', 'E', 'W', 'U', 'D', 'NORTH', 'SOUTH', 'EAST', 'WEST', 'UP', 'DOWN'].contains(verbString)) {
        // Just movement
      } else {
        o = _getNounId(nounString);
        if (o == 0 && nounString != 'AROUND') {
           addMessage("I don't recognise that NOUN.");
           saveState();
           notifyListeners();
           return;
        }
      }
    } else if (['N', 'S', 'E', 'W', 'U', 'D', 'NORTH', 'SOUTH', 'EAST', 'WEST', 'UP', 'DOWN'].contains(verbString)) {
       // Single letter movement
    } else if (v != 15 && v != 2 && v != 11 && v != 14 && v != 34) { // Commands that don't need nouns
       addMessage("I don't understand you.");
       saveState();
       notifyListeners();
       return;
    }

    _dispatchLogic(v, o, verbString, nounString);
    
    saveState();
    notifyListeners();
  }

  void _dispatchLogic(int v, int o, String verbString, String nounString) {
    if (v == 1) { // GO / MOVE
       if (['N', 'S', 'E', 'W', 'U', 'D', 'NORTH', 'SOUTH', 'EAST', 'WEST', 'UP', 'DOWN'].contains(verbString)) {
         moveInDirection(verbString[0]);
       } else if (o == 39 && _gameFlags['door_unlocked'] == true && _currentRoomId == 5) {
         _currentRoomId = 20;
         _moveCount++;
         describeCurrentRoom();
       } else if (o == 35) { // CORRIDOR
         moveInDirection('N');
       } else if (o == 46 && _gameFlags['bookshelf_moved'] == true) { // PASSAGEWAY
         moveInDirection('U');
       } else if (o == 44 && _gameFlags['hatch_open'] == true && _currentRoomId == 19) {
         _currentRoomId = 22;
         _moveCount++;
         describeCurrentRoom();
       } else {
         addMessage("You can't go that way.");
       }
    } else if (v == 2) { // EXAMINE / LOOK
       if (nounString == 'AROUND' || nounString.isEmpty) {
         describeCurrentRoom();
       } else if (o == 51 && _currentRoomId == 3) {
         if (_objectLocations['WATER'] == 0) _objectLocations['WATER'] = 3;
         addMessage("I can see something!");
       } else if (o == 36 && _currentRoomId == 3 && _gameFlags['cupboard_open'] == true) {
         if (_objectLocations['MATCHES'] == 0) _objectLocations['MATCHES'] = 3;
         if (_objectLocations['KNIFE'] == 0) _objectLocations['KNIFE'] = 3;
         addMessage("I can see something!");
       } else if (o == 42 && _currentRoomId == 8) {
         if (_objectLocations['COAL'] == 0) _objectLocations['COAL'] = 8;
         addMessage("I can see something!");
       } else if (o == 37 && _currentRoomId == 7) {
         if (_objectLocations['BIBLE'] == 0) _objectLocations['BIBLE'] = 7;
         if (_objectLocations['LETTER'] == 0) _objectLocations['LETTER'] = 7;
         addMessage("I can see something!");
       } else if (o == 12 && _currentRoomId == _objectLocations['CHEST'] && _gameFlags['chest_broken'] == true) {
         if (_objectLocations['KEY'] == 0) _objectLocations['KEY'] = _currentRoomId;
         addMessage("I can see something!");
       } else if (o == 48 && _currentRoomId == 13 && _gameFlags['safe_open'] == true) {
         addMessage("I can see something!");
       } else if (o == 50 && _currentRoomId == 16) {
         if (_objectLocations['BOOK'] == null || _objectLocations['BOOK'] == 0) _objectLocations['BOOK'] = 16;
         addMessage("I can see something!");
       } else if (o == 5) {
         addMessage("It falls open at the first page.");
       } else if (o == 6) {
         addMessage("French red. Maybe you should try it.");
       } else if (o == 25) {
         addMessage("It's an oil painting of two horses.");
       } else if (o == 32) {
         addMessage("It's getting terribly late!!");
       } else if (o == 4) {
         addMessage("THE EXORCIST - How apt.");
       } else if (o == 38) {
         addMessage("It has eyes like red embers.");
       } else if (o == 47) {
         addMessage("Looks pretty nasty!!");
       } else {
         addMessage("I don't notice anything in particular.");
       }
    } else if (v == 3) { // GET / TAKE
       if (o > 28) { // EXACT emulation of ATARI line 1400/14
         addMessage("Not a very good idea.");
       } else if (_inventory.length >= maxInventory) {
         addMessage("You are carrying too much.");
       } else if (o == 28 && _currentRoomId == 3) { // WATER
         if (_inventory.contains('GOBLET')) {
           _inventory.remove('GOBLET');
           if (_inventory.contains('BIBLE') && _inventory.contains('CRUCIFIX')) {
             _inventory.add('HOLY WATER');
             addMessage("HOLY WATER!!");
           } else {
             _inventory.add('WATER');
             addMessage("Ok");
           }
         } else {
           addMessage("You don't have anything to put it in.");
         }
       } else if (_objectLocations[nounString] == _currentRoomId || getVisibleObjects().contains(nounString)) {
         _objectLocations[nounString] = -1;
         _inventory.add(nounString);
         addMessage("Ok");
       } else {
         addMessage("I don't see it here.");
       }
    } else if (v == 4) { // DROP / LEAVE
       if (_inventory.contains(nounString)) {
         _inventory.remove(nounString);
         _objectLocations[nounString] = _currentRoomId;
         if (o == 11 || o == 12) {
           addMessage("CRASH!!!");
         } else if (o == 25) {
           _gameFlags['painting_moved'] = true;
           addMessage("Ok");
         } else {
           addMessage("Ok");
         }
       } else {
         addMessage("You aren't carrying it!!");
       }
    } else if (v == 5) { // OPEN
       if (o == 36 && _currentRoomId == 3) {
         _gameFlags['cupboard_open'] = true;
         addMessage("Ok");
       } else if (o == 48 && _currentRoomId == 13 && _gameFlags['painting_moved'] == true) {
         addMessage("Enter the 4 digit combination");
       } else {
         addMessage("Sorry, but I can't do that.");
       }
    } else if (v == 6) { // UNLOCK
       if (o == 39 && _inventory.contains('KEY')) {
         _gameFlags['door_unlocked'] = true;
         addMessage("Ok");
       } else if (o == 43 && _inventory.contains('GATE KEY') && _currentRoomId == 26) {
         addMessage("CONGRATULATIONS!! You have escaped into an open courtyard. Evil forces try to");
         addMessage("force you back, but freedom is just a few steps away...");
         _gameFlags['gates_unlocked'] = true;
       } else {
         addMessage("The door is locked.");
       }
    } else if (v == 8) { // BURN / LIGHT
       if (o == 10 && _inventory.contains('MATCHES') && _inventory.contains('CANDLE')) {
         _inventory.remove('CANDLE');
         _inventory.add('LIT CANDLE');
         _candleLife = 300;
         addMessage("Ok");
       } else if (o == 13 && _currentRoomId == 26 && _objectLocations['COAL'] == 26 && _objectLocations['RAG'] == 26) {
         _gameFlags['dog_terrified'] = true;
         _objectLocations['COAL'] = 0;
         _objectLocations['RAG'] = 0;
         addMessage("The coals glow like the dog's eyes, and he runs away, terrified!");
       } else {
         addMessage("It's already lit!!");
       }
    } else if (v == 9) { // EXTINGUISH
       if (o == 10 && _inventory.contains('LIT CANDLE')) {
         _inventory.remove('LIT CANDLE');
         _inventory.add('CANDLE');
         addMessage("It went out!!");
       } else {
         addMessage("Ok. Nothing happens.");
       }
    } else if (v == 10) { // READ
       if (o == 23 && _inventory.contains('LETTER')) {
         addMessage("3 CEMETARY WAY, GOOLE....One free through heaven.....?");
       } else {
         addMessage("I don't understand you.");
       }
    } else if (v == 15) { // INVENTORY
       if (_inventory.isEmpty) {
         addMessage("You are carrying nothing whatsoever.");
       } else {
         addMessage("You are carrying: ${_inventory.join(", ")}");
       }
    } else if (v == 23) { // KICK
       if (o == 12 && _currentRoomId == _objectLocations['CHEST']) {
         addMessage("The lid flew open!");
         _gameFlags['chest_broken'] = true;
         _objectLocations['KEY'] = _currentRoomId;
       } else {
         addMessage("Temper!!");
       }
    } else if (v == 24) { // PUSH / PULL
       if (o == 4 && _currentRoomId == 16) {
         addMessage("Something happened!");
         _gameFlags['bookshelf_moved'] = true;
       } else if (o == 52 && _currentRoomId == 18) {
         addMessage("Ok");
       } else {
         addMessage("Ok. Nothing happens.");
       }
    } else if (v == 25) { // CLIMB
       if (o == 11 && _currentRoomId == 3 && _objectLocations['CHAIR'] == 3) {
         addMessage("Ok, you're standing on the chair.");
       } else {
         addMessage("You must be joking!!");
       }
    } else if (v == 27) { // EXORCISE
       if (o == 30 && _inventory.contains('BIBLE') && _inventory.contains('CRUCIFIX') && _inventory.contains('HOLY WATER')) {
         addMessage("Something happened in a BLINDING flash of light!!");
         _gameFlags['cloak_exorcised'] = true;
       } else {
         addMessage("I don't understand you.");
       }
    } else if (v == 28) { // MAKE
       if (o == 14 && _inventory.contains('SAW') && _inventory.contains('BAR')) {
         _inventory.remove('BAR');
         _inventory.add('CRUCIFIX');
         addMessage("That should prove useful.");
       } else {
         addMessage("What with?");
       }
    } else if (v == 38) { // TIE
       addMessage("I don't understand you.");
    } else if (v == 100) { // Custom logic for USE/REMOVE/CUT
       if (verbString == 'REMOVE' && o == 82 && _inventory.contains('HAMMER') && _currentRoomId == 19) {
         addMessage("Ok");
         _gameFlags['hatch_open'] = true;
       } else if (verbString == 'CUT' && o == 28 && _inventory.contains('SAW') && _inventory.contains('BAR')) {
         addMessage("Ok");
       } else {
         addMessage("Sorry, but I can't do that.");
       }
    } else {
       if (nounString.isNotEmpty) {
         addMessage("Sorry, but I can't do that.");
       } else {
         addMessage("I don't understand you.");
       }
    }
  }

  bool moveInDirection(String direction) {
    final dir = direction.toUpperCase();
    final exits = getAvailableExits();

    if (_currentRoomId == 26 && dir == 'E' && !_gameFlags['dog_terrified']!) {
      addMessage('The dog snarls, revealing bloodstained fangs!!');
      return false;
    }
    if (_currentRoomId == 1 && dir == 'N' && !_inventory.contains('KNIFE')) {
      addMessage('What about the rat?');
      return false;
    }

    if (_currentRoomId == 1 && dir == 'U' && !_inventory.contains('BIBLE')) {
      addMessage("I'm too scared. It looks very creepy!!");
      return false;
    }

    if (exits.containsKey(dir)) {
      final destRoom = exits[dir]!;
      _currentRoomId = destRoom;
      _moveCount++;

      if (isTooDarkToSee) {
        addMessage('It\'s difficult, moving in the dark!!');
      }

      describeCurrentRoom();
      saveState();
      notifyListeners();
      return true;
    } else {
      addMessage("You can't go that way.");
      return false;
    }
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cloak_save_state');
    _initNewGame();
    notifyListeners();
  }
}
