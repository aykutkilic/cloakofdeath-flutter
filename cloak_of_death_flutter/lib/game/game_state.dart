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
  // BASIC line 400: IF L>C14 AND P(C9)<>H AND P(C9)<>L THEN F1=C1
  // All rooms > 14 are dark unless lit candle is held or in the room.
  bool get isDark => _currentRoomId > 14;
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
    // P(1)-P(53) from original BASIC DATA lines 32060-32070.
    // 0 = hidden/nowhere, room number = in that room, -1 = in inventory.
    // Only tracking objects that can move or need visibility checks.
    _objectLocations = {
      'BAR': 25,         // P(2)=25 Torture Chamber
      'BIBLE': 0,        // P(4)=0  hidden (revealed by EXAMINE DESK)
      'BOOK': 0,         // P(5)=0  hidden (revealed by EXAMINE SHELVES)
      'WINE': 22,        // P(6)=22 Wine Cellar
      'BREAD': 3,        // P(7)=3  Kitchen
      'CANDLE': 4,       // P(8)=4  Pantry
      'CHAIR': 2,        // P(10)=2 Dining Room
      'CHEST': 6,        // P(11)=6 Conservatory
      'COAL': 0,         // P(12)=0 hidden (revealed by EXAMINE FIREPLACE)
      'GOBLET': 12,      // P(14)=12 (room 12)
      'HAMMER': 24,      // P(17)=24 Underground Chamber
      'IRON': 23,        // P(18)=23 Cold Damp Cellar
      'KEY': 0,          // P(19)=0  hidden (revealed by EXAMINE CHEST)
      'GATE KEY': 0,     // P(20)=0  hidden (in safe)
      'KNIFE': 3,        // P(21)=3  Kitchen
      'LETTER': 0,       // P(22)=0  hidden (revealed by EXAMINE DESK)
      'MATCHES': 0,      // P(23)=0  hidden (revealed by EXAMINE CUPBOARD)
      'PAINTING': 15,    // P(24)=15 (room 15)
      'RAG': 25,         // P(25)=25 Torture Chamber
      'SAW': 24,         // P(26)=24 Underground Chamber
      'WIRE': 20,        // P(27)=20 (room 20 = Cellar)
      'CLOAK': 15,       // P(29)=15 (room 15 = Haunted Room)
      'CLOCK': 8,        // P(32)=8  Sitting Room
      'CORD': 0,         // P(33)=-1 initially hidden; becomes visible via game events
      'CORRIDOR': 0,     // P(35)=0  hidden (revealed by LOOK AROUND at room 1)
      'CUPBOARD': 0,     // P(36)=0  hidden (revealed by LOOK AROUND at room 3)
      'DESK': 7,         // P(37)=7  Oak Panelled Study (screenshot evidence: .bas DATA has 26 but Atari screenshot shows desk at room 7)
      'DOG': 5,          // P(38)=5  Dark Corridor
      'DOOR': 0,         // P(39)=0  (state-dependent visibility)
      'EMBERS': 0,       // P(41)=0  hidden
      'FIREPLACE': 8,    // P(42)=8  Sitting Room
      'GATE': 26,        // P(43)=26 Dark Passage
      'HATCH': 21,       // P(44)=21 (room 21)
      'PASSAGEWAY': 0,   // P(46)=0  hidden (revealed by PUSH BOOK)
      'RAT': 1,          // P(47)=1  Entrance
      'SAFE': 0,         // P(48)=0  hidden (behind painting)
      'SHELVES': 16,     // P(50)=16 Library
      'SINK': 3,         // P(51)=3  Kitchen
      'TABLE': 21,       // P(52)=21 (room 21)
      'ANNEXE': 0,       // P(53)=0
      'CRUCIFIX': 0,     // P(13)=0  crafted item
      'WATER': 0,        // P(28)=0  from sink
      'HOLY WATER': 0,   // P(16)=0  crafted
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

  /// BASIC line 15: IF P(O)<>L AND P(O)<>H THEN "I don't see it here"
  /// Checks if object is in current room (visible) or in inventory (held).
  bool _isObjectPresent(String nounString) {
    return getVisibleObjects().contains(nounString) ||
        _inventory.contains(nounString);
  }

  List<String> getVisibleObjects() {
    if (isTooDarkToSee) return [];

    List<String> visible = [];
    _objectLocations.forEach((obj, room) {
      if (room == _currentRoomId) {
        // Dog disappears when terrified
        if (obj == 'DOG' && _gameFlags['dog_terrified'] == true) return;
        visible.add(obj);
      }
    });

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
      case 'USE': case 'REMO': case 'REMOVE': return 100;
      case 'CUT': return 13; // CUT = BREAK/CHOP in original BASIC
      default: return 0;
    }
  }

  /// Noun IDs match original BASIC P(O) array indices.
  /// Derived from all_strings.txt object descriptions (lines 759-796).
  int _getNounId(String noun) {
    switch (noun) {
      case 'BALL': return 1;
      case 'BAR': return 2;
      case 'BAR PIECES': return 3;
      case 'BIBL': case 'BIBLE': return 4;
      case 'BOOK': return 5;
      case 'WINE': return 6;
      case 'BOTT': case 'BOTTLE': return 6;
      case 'BREA': case 'BREAD': return 7;
      case 'CAND': case 'CANDLE': case 'LIT CANDLE': return 8;
      case 'CHAI': case 'CHAIR': return 10;
      case 'CHES': case 'CHEST': return 11;
      case 'COAL': return 12;
      case 'CRUC': case 'CRUCIFIX': return 13;
      case 'GOBL': case 'GOBLET': return 14;
      case 'HOLY WATER': return 16;
      case 'HAMM': case 'HAMMER': return 17;
      case 'IRON': return 18;
      case 'KEY': return 19;
      case 'SKEL': case 'SKELETON KEY': case 'GATE KEY': return 20;
      case 'KNIF': case 'KNIFE': return 21;
      case 'LETT': case 'LETTER': return 22;
      case 'MATC': case 'MATCHES': return 23;
      case 'PAIN': case 'PAINTING': return 24;
      case 'RAG': return 25;
      case 'SAW': return 26;
      case 'WIRE': return 27;
      case 'WATE': case 'WATER': return 28;
      case 'CLOA': case 'CLOAK': return 29;
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
      if (_gameFlags['painting_moved'] == true && _objectLocations['SAFE'] == _currentRoomId) {
        addMessage("You've cracked it!");
        _gameFlags['safe_open'] = true;
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
         // GO DOOR — enter cellar (BASIC K=35 → room 23)
         _currentRoomId = 23;
         _moveCount++;
         describeCurrentRoom();
       } else if (o == 35) { // GO CORRIDOR
         if (!_isObjectPresent('CORRIDOR')) {
           addMessage("I don't see it here.");
         } else if (_currentRoomId == 1 && !_inventory.contains('KNIFE')) {
           // BASIC line 1086: rat blocks corridor without knife
           addMessage('What about the rat?');
         } else {
           // BASIC K=7: GO CORRIDOR at room 1 → room 5
           _currentRoomId = 5;
           _moveCount++;
           describeCurrentRoom();
         }
       } else if (o == 46 && _gameFlags['bookshelf_moved'] == true && _currentRoomId == 16) { // GO PASSAGEWAY
         _currentRoomId = 17;
         _moveCount++;
         describeCurrentRoom();
       } else if (o == 44 && _gameFlags['hatch_open'] == true && _objectLocations['HATCH'] == _currentRoomId) {
         // GO HATCH — BASIC line 1020/1105
         _currentRoomId = 20; // Original: GO HATCH leads to room 20
         _moveCount++;
         describeCurrentRoom();
       } else if (o == 53) { // GO ANNEXE — BASIC K=91: room 13 special → room 12
         if (!_isObjectPresent('ANNEXE')) {
           addMessage("I don't see it here.");
         } else {
           _currentRoomId = 12;
           _moveCount++;
           describeCurrentRoom();
         }
       } else {
         addMessage("You can't go that way.");
       }
    } else if (v == 2) { // EXAMINE / LOOK
       if (nounString == 'AROUND' || nounString.isEmpty) {
         // BASIC lines 1210-1230: room-specific hidden object reveals
         bool revealed = false;
         if (_currentRoomId == 1 && _objectLocations['CORRIDOR'] == 0) {
           _objectLocations['CORRIDOR'] = _currentRoomId;
           revealed = true;
         } else if (_currentRoomId == 3 && _objectLocations['CUPBOARD'] == 0) {
           _objectLocations['CUPBOARD'] = _currentRoomId;
           revealed = true;
         } else if (_currentRoomId == 10 && _objectLocations['CORD'] == 0) {
           _objectLocations['CORD'] = _currentRoomId;
           revealed = true;
         }
         if (revealed) {
           // BASIC line 9008: R$="I can see something!!"
           addMessage('I can see something!');
         }
         describeCurrentRoom();
       } else if (!_isObjectPresent(nounString)) {
         addMessage("I don't see it here.");
       } else if (o == 51 && _currentRoomId == 3) { // EXAMINE SINK
         if (_objectLocations['WATER'] == 0) _objectLocations['WATER'] = 3;
         addMessage("I can see something!");
       } else if (o == 36) { // EXAMINE CUPBOARD — BASIC line 1295: reveals MATCHES
         if (_objectLocations['MATCHES'] == 0) _objectLocations['MATCHES'] = _currentRoomId;
         addMessage("I can see something!");
       } else if (o == 42) { // EXAMINE FIREPLACE
         if (_objectLocations['COAL'] == 0) _objectLocations['COAL'] = _currentRoomId;
         addMessage("I can see something!");
       } else if (o == 37) { // EXAMINE DESK — BASIC line 1300: reveals BIBLE only
         if (_objectLocations['BIBLE'] == 0) _objectLocations['BIBLE'] = _currentRoomId;
         addMessage("I can see something!");
       } else if (o == 11 && _gameFlags['chest_broken'] == true) { // EXAMINE CHEST (after KICK)
         if (_objectLocations['KEY'] == 0) _objectLocations['KEY'] = _currentRoomId;
         addMessage("I can see something!");
       } else if (o == 48 && _gameFlags['safe_open'] == true) { // EXAMINE open SAFE
         // BASIC line 1325: EXAMINE open safe reveals GATE KEY
         if (_objectLocations['GATE KEY'] == 0) _objectLocations['GATE KEY'] = _currentRoomId;
         addMessage("I can see something!");
       } else if (o == 50) { // EXAMINE SHELVES
         if (_objectLocations['BOOK'] == 0) _objectLocations['BOOK'] = _currentRoomId;
         addMessage("I can see something!");
       } else if (o == 5) { // EXAMINE BOOK
         addMessage("It falls open at the first page.");
       } else if (o == 6) { // EXAMINE WINE
         addMessage("French red. Maybe you should try it.");
       } else if (o == 24) { // EXAMINE PAINTING
         addMessage("It's an oil painting of two horses.");
       } else if (o == 32) { // EXAMINE CLOCK
         addMessage("It's getting terribly late!!");
       } else if (o == 4) { // EXAMINE BIBLE
         addMessage("THE EXORCIST - How apt.");
       } else if (o == 38) { // EXAMINE DOG
         addMessage("It has eyes like red embers.");
       } else if (o == 47) { // EXAMINE RAT
         addMessage("Looks pretty nasty!!");
       } else {
         addMessage("I don't notice anything in particular.");
       }
    } else if (v == 3) { // GET / TAKE
       // BASIC line 14: IF P(O)>C28 THEN POP:GOTO 9050 — can't pick up scenery
       if (o > 28) {
         addMessage("Not a very good idea.");
       } else if (_inventory.length >= maxInventory) {
         addMessage("You are carrying too much.");
       } else if (o == 28 && _currentRoomId == 3) { // GET WATER (from sink)
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
       } else if (_objectLocations[nounString] == _currentRoomId) {
         _objectLocations[nounString] = -1;
         _inventory.add(nounString);
         // BASIC line 1420: GET BIBLE reveals LETTER at same location
         if (o == 4 && _objectLocations['LETTER'] == 0) {
           _objectLocations['LETTER'] = _currentRoomId;
         }
         // BASIC line 1460: GET IRON triggers cord/annexe events
         if (o == 18) {
           _objectLocations['CORD'] = 10; // Cord appears at guest bedroom
           _objectLocations['ANNEXE'] = 0; // Annexe disappears
         }
         addMessage("Ok");
       } else {
         addMessage("I don't see it here.");
       }
    } else if (v == 4) { // DROP / LEAVE
       if (_inventory.contains(nounString)) {
         _inventory.remove(nounString);
         _objectLocations[nounString] = _currentRoomId;
         if (o == 11 || o == 12) { // CHEST or COAL — crash sound
           addMessage("CRASH!!!");
         } else if (o == 24) { // DROP PAINTING — reveals safe
           _gameFlags['painting_moved'] = true;
           _objectLocations['SAFE'] = _currentRoomId;
           addMessage("Ok");
         } else if (o == 18 && _currentRoomId == 10 && _gameFlags['cord_pulled'] == true) {
           // BASIC line 1750: DROP IRON at room 10 with cord pulled
           _objectLocations['CORD'] = 0;
           _objectLocations['ANNEXE'] = 13; // Annexe appears at master bedroom
           addMessage("Ok");
         } else {
           addMessage("Ok");
         }
       } else {
         addMessage("You aren't carrying it!!");
       }
    } else if (v == 5) { // OPEN
       // BASIC line 2010: GOSUB C15 — presence check before any OPEN action
       if (o != 0 && !_isObjectPresent(nounString)) {
         addMessage("I don't see it here.");
       } else if (o == 36) { // OPEN CUPBOARD
         _gameFlags['cupboard_open'] = true;
         addMessage("Ok");
       } else if (o == 48 && _objectLocations['SAFE'] == _currentRoomId) {
         addMessage("Enter the 4 digit combination");
       } else {
         addMessage("Sorry, but I can't do that.");
       }
    } else if (v == 6) { // UNLOCK
       if (o == 39 && _inventory.contains('KEY')) { // UNLOCK DOOR
         _gameFlags['door_unlocked'] = true;
         addMessage("Ok");
       } else if (o == 43 && _objectLocations['DOG'] == _currentRoomId) {
         // BASIC line 2080: dog in room blocks UNLOCK
         addMessage('The dog snarls, revealing bloodstained fangs!!');
       } else if (o == 43 && _inventory.contains('GATE KEY') && _currentRoomId == 26) { // UNLOCK GATES
         addMessage("CONGRATULATIONS!! You have escaped into an open courtyard. Evil forces try to");
         addMessage("force you back, but freedom is just a few steps away...");
         _gameFlags['gates_unlocked'] = true;
       } else {
         addMessage("The door is locked.");
       }
    } else if (v == 8) { // BURN / LIGHT
       if (o == 8 && _inventory.contains('MATCHES') && _inventory.contains('CANDLE')) { // LIGHT CANDLE (noun 8)
         _inventory.remove('CANDLE');
         _inventory.add('LIT CANDLE');
         _candleLife = 300;
         addMessage("Ok");
       } else if ((o == 12 || o == 25) && _objectLocations['COAL'] == _currentRoomId && _objectLocations['RAG'] == _currentRoomId) {
         // BASIC line 2440: BURN COAL/RAG with both in room → embers + optional dog scare
         _objectLocations['COAL'] = 0;
         _objectLocations['RAG'] = 0;
         _objectLocations['EMBERS'] = _currentRoomId;
         if (_currentRoomId == 26) {
           // BASIC line 2470: at room 26, dog runs away
           _objectLocations['DOG'] = 0;
           addMessage("The coals glow like the dog's eyes, and he runs away, terrified!!");
         } else {
           addMessage("Ok");
         }
       } else {
         addMessage("It's already lit!!");
       }
    } else if (v == 9) { // EXTINGUISH
       if (o == 8 && _inventory.contains('LIT CANDLE')) { // EXTINGUISH CANDLE (noun 8)
         _inventory.remove('LIT CANDLE');
         _inventory.add('CANDLE');
         addMessage("It went out!!");
       } else {
         addMessage("Ok. Nothing happens.");
       }
    } else if (v == 10) { // READ
       if (o == 22 && _inventory.contains('LETTER')) { // READ LETTER (noun 22)
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
    } else if (v == 13) { // BREAK / CHOP / CUT
       // BASIC lines 3400-3420: CUT BAR at room 25 with SAW
       if (o != 2 && o != 3) {
         addMessage("Vandal!!");
       } else if (_currentRoomId != 25 || !_inventory.contains('SAW')) {
         addMessage("Sorry, but I can't do that.");
       } else if (o == 2 && _inventory.contains('BAR')) {
         _inventory.remove('BAR');
         _inventory.add('BAR PIECES');
         _objectLocations['BAR PIECES'] = -1;
         addMessage("Ok");
       } else if (o == 3) {
         addMessage("The pieces were so small, I lost them.");
       } else {
         addMessage("Sorry, but I can't do that.");
       }
    } else if (v == 23) { // KICK
       if (o == 11 && _objectLocations['CHEST'] == _currentRoomId) { // KICK CHEST (noun 11)
         addMessage("The lid flew open!");
         _gameFlags['chest_broken'] = true;
         _objectLocations['KEY'] = _currentRoomId;
       } else {
         addMessage("Temper!!");
       }
    } else if (v == 24) { // PUSH / PULL
       if (o == 5 && _currentRoomId == 16) { // PUSH BOOK (noun 5) in Library
         addMessage("Something happened!");
         _gameFlags['bookshelf_moved'] = true;
         _objectLocations['PASSAGEWAY'] = 16;
       } else if (o == 33 && _currentRoomId == 10 && _gameFlags['cord_pulled'] != true) {
         // BASIC line 5620: PULL CORD at room 10 (guest bedroom)
         _gameFlags['cord_pulled'] = true;
         addMessage("A strange rumbling noise...");
       } else if (o == 52 && _objectLocations['TABLE'] == _currentRoomId) { // PUSH TABLE
         addMessage("Ok");
       } else {
         addMessage("Ok. Nothing happens.");
       }
    } else if (v == 25) { // CLIMB
       if (o == 10 && _objectLocations['CHAIR'] == _currentRoomId) { // CLIMB CHAIR (noun 10)
         addMessage("Ok, you're standing on the chair.");
       } else {
         addMessage("You must be joking!!");
       }
    } else if (v == 27) { // EXORCISE
       if (o == 29 && _inventory.contains('BIBLE') && _inventory.contains('CRUCIFIX') && _inventory.contains('HOLY WATER')) {
         // EXORCISE CLOAK (noun 29)
         addMessage("Something happened in a BLINDING flash of light!!");
         _gameFlags['cloak_exorcised'] = true;
       } else {
         addMessage("I don't understand you.");
       }
    } else if (v == 28) { // MAKE
       // BASIC line 6210: MAKE CRUCIFIX at room 25 with bar pieces + wire
       if (o == 13 && _currentRoomId == 25 && _inventory.contains('BAR PIECES') && _inventory.contains('WIRE')) {
         _inventory.remove('BAR PIECES');
         _inventory.remove('WIRE');
         _objectLocations['CRUCIFIX'] = _currentRoomId;
         addMessage("That should prove useful.");
       } else {
         addMessage("What with?");
       }
    } else if (v == 38) { // TIE
       addMessage("I don't understand you.");
    } else if (v == 100) { // Custom logic for USE/REMOVE
       if (verbString == 'REMOVE' && o == 82 && _inventory.contains('HAMMER') && _objectLocations['HATCH'] == _currentRoomId) {
         addMessage("Ok");
         _gameFlags['hatch_open'] = true;
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

    // BASIC line 1080 (K=5): Room 1 Up → Room 9, needs Bible
    if (_currentRoomId == 1 && dir == 'U' && !_inventory.contains('BIBLE')) {
      addMessage("I'm too scared. It looks very creepy!!");
      return false;
    }
    // BASIC line 1100 (K=94): Room 14 East → Room 15, needs Bible+Crucifix or cloak exorcised
    if (_currentRoomId == 14 && dir == 'E') {
      if (_gameFlags['cloak_exorcised'] != true &&
          (!_inventory.contains('BIBLE') || !_inventory.contains('CRUCIFIX'))) {
        addMessage("That's the haunted bedroom!!");
        return false;
      }
      // Conditional exit to room 15
      _currentRoomId = 15;
      _moveCount++;
      if (isTooDarkToSee) {
        addMessage("It's difficult, moving in the dark!!");
      }
      describeCurrentRoom();
      saveState();
      notifyListeners();
      return true;
    }
    // BASIC line 1110: dog at room 26 blocks east movement
    if (_currentRoomId == 26 && dir == 'E' && _objectLocations['DOG'] == 26) {
      addMessage('The dog snarls, revealing bloodstained fangs!!');
      return false;
    }
    // BASIC line 1115: gates must be unlocked to go east from room 26
    if (_currentRoomId == 26 && dir == 'E' && _gameFlags['gates_unlocked'] != true) {
      addMessage('The gates are locked.');
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
