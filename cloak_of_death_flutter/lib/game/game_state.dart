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
      'PAINTING': 13,
      'SAFE': 0,
      'GATE KEY': 0,
      'RAT': 1,
    };
    _moveCount = 0;
    _candleLife = 0;
    _outputMessages = [
      'Welcome to CLOAK OF DEATH',
      'by David Cockram. Remember,in the dead',
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

    if (_currentRoomId == 3) {
      visible.add('CUPBOARD');
    }
    if (_currentRoomId == 3) {
      visible.add('SINK');
    }
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
    // Default actions available for almost everything
    final List<String> actions = ['LOOK', 'EXAMINE'];

    // Actions depending on whether we hold it or it's in the room
    final bool inInventory = _inventory.contains(object);
    
    if (inInventory) {
      actions.add('DROP');
    } else if (_objectLocations[object] == _currentRoomId || 
               (object == 'SAFE' && _currentRoomId == 4) ||
               (object == 'DOOR' && (_currentRoomId == 2 || _currentRoomId == 6)) ||
               (object == 'GATE' && _currentRoomId == 7)) {
      actions.add('GET'); // Note: You can't GET doors/safes normally, but GET is a standard action attempt
    }

    // Specific object actions based on game logic
    switch (object) {
      case 'DOOR':
      case 'GATE':
      case 'SAFE':
        actions.addAll(['OPEN', 'UNLOCK', 'PUSH', 'PULL']);
        break;
      case 'CANDLE':
      case 'LIT CANDLE':
        actions.addAll(['LIGHT', 'EXTINGUISH']);
        break;
      case 'MATCHES':
        actions.add('LIGHT');
        break;
      case 'LETTER':
      case 'BIBLE':
        actions.add('READ');
        break;
      case 'KEY':
      case 'GATE KEY':
      case 'HAMMER':
      case 'SAW':
      case 'BAR':
      case 'WIRE':
      case 'KNIFE':
      case 'HOLY WATER':
      case 'WATER':
      case 'CRUCIFIX':
        actions.add('USE');
        break;
      case 'CHAIR':
        actions.add('CLIMB');
        break;
      case 'BREAD':
        // No specific verb explicitly handled by logic other than USE or DROP, maybe EAT but it isn't a standard verb. Add USE.
        actions.add('USE');
        break;
    }

    return actions.toSet().toList(); // Ensure uniqueness
  }

  void executeObjectVerb(String verb, String object) {
    final command = '$verb $object';
    _selectedObject = null;
    processCommand(command);
  }

  void addMessage(String message) {
    _outputMessages.add(message);
    if (_outputMessages.length > 50) {
      _outputMessages.removeAt(0);
    }
  }

  void describeCurrentRoom() {
    final room = currentRoom;
    if (room == null) return;

    addMessage('');
    if (isTooDarkToSee) {
      addMessage('► IT\'S TOO DARK TO SEE');
    } else {
      addMessage('You are ${room.description}');
      final exits = getAvailableExits();
      if (exits.isNotEmpty) {
        addMessage('Exits are ${exits.keys.join(", ")}.');
      }

      final visible = getVisibleObjects();
      if (visible.isNotEmpty) {
        addMessage('Visible items: ${visible.join(", ")}');
      }
    }
    addMessage('');
  }

  void processCommand(String command) {
    if (command.trim().isEmpty) return;

    addMessage('> $command');
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

    final words = command.trim().toUpperCase().split(' ');
    final verb = words[0];
    final noun = words.length > 1 ? words.skip(1).join(' ') : '';

    bool handled = false;

    if ([
      'N',
      'S',
      'E',
      'W',
      'U',
      'D',
      'NORTH',
      'SOUTH',
      'EAST',
      'WEST',
      'UP',
      'DOWN',
    ].contains(verb)) {
      moveInDirection(verb[0]);
      handled = true;
    } else if (verb == 'LOOK' || verb == 'L') {
      describeCurrentRoom();
      handled = true;
    } else if (verb == 'INVENTORY' || verb == 'I') {
      if (_inventory.isEmpty) {
        addMessage('You are carrying nothing whatsoever.');
      } else {
        addMessage('You are carrying: ${_inventory.join(", ")}');
      }
      handled = true;
    } else if (verb == 'GET' || verb == 'TAKE') {
      if (noun.isNotEmpty) {
        handled = _handleGet(noun);
      }
    } else if (verb == 'DROP' || verb == 'LEAVE') {
      if (noun.isNotEmpty) {
        handled = _handleDrop(noun);
      }
    } else if (verb == 'OPEN') {
      handled = _handleOpen(noun);
    } else if (verb == 'EXAMINE' || verb == 'X') {
      handled = _handleExamine(noun);
    } else if (verb == 'CLIMB') {
      handled = _handleClimb(noun);
    } else if (verb == 'LIGHT') {
      handled = _handleLight(noun);
    } else if (verb == 'EXTINGUISH') {
      handled = _handleExtinguish(noun);
    } else if (verb == 'BURN') {
      handled = _handleBurn(noun);
    } else if (verb == 'READ') {
      if (noun == 'LETTER' && _inventory.contains('LETTER')) {
        addMessage("3 CEMETARY WAY, GOOLE....One free through heaven.....?");
        handled = true;
      }
    } else if (verb == 'KICK') {
      if (noun == 'CHEST' && _currentRoomId == _objectLocations['CHEST']) {
        addMessage("The lid flew open!");
        _gameFlags['chest_broken'] = true;
        _objectLocations['KEY'] = _currentRoomId;
        handled = true;
      }
    } else if (verb == 'UNLOCK') {
      if (noun == 'DOOR' && _inventory.contains('KEY')) {
        _gameFlags['door_unlocked'] = true;
        addMessage("Ok");
        handled = true;
      } else if (noun == 'GATES' &&
          _inventory.contains('GATE KEY') &&
          _currentRoomId == 26) {
        addMessage(
          "CONGRATULATIONS!! You have escaped into an open courtyard. Evil forces try to",
        );
        addMessage("force you back, but freedom is just a few steps away...");
        _gameFlags['gates_unlocked'] = true;
        handled = true;
      }
    } else if (verb == 'GO') {
      if (noun == 'DOOR' &&
          _gameFlags['door_unlocked'] == true &&
          _currentRoomId == 5) {
        _currentRoomId = 20; // Move to Cellar
        _moveCount++;
        describeCurrentRoom();
        handled = true;
      } else if (noun == 'CORRIDOR' || noun == 'CORR') {
        moveInDirection('N');
        handled = true;
      } else if (noun == 'PASSAGEWAY' &&
          _gameFlags['bookshelf_moved'] == true) {
        moveInDirection('U');
        handled = true;
      } else if (noun == 'HATCH' &&
          _gameFlags['hatch_open'] == true &&
          _currentRoomId == 19) {
        _currentRoomId = 22; // Move to Store Room (Hatch destination)
        _moveCount++;
        describeCurrentRoom();
        handled = true;
      } else if (noun == 'ANNEXE' && _gameFlags['annexe_open'] == true) {
        _currentRoomId = 12;
        _moveCount++;
        describeCurrentRoom();
        handled = true;
      }
    } else if (verb == 'PUSH') {
      if (noun == 'BOOK' && _currentRoomId == 16) {
        addMessage("Something happened!");
        _gameFlags['bookshelf_moved'] = true;
        handled = true;
      } else if (noun == 'TABLE' && _currentRoomId == 18) {
        addMessage("Ok");
        handled = true;
      }
    } else if (verb == 'REMOVE') {
      if (noun == 'NAILS' &&
          _inventory.contains('HAMMER') &&
          _currentRoomId == 19) {
        addMessage("Ok");
        _gameFlags['hatch_open'] = true;
        handled = true;
      }
    } else if (verb == 'CUT') {
      if (noun == 'BAR' &&
          _inventory.contains('SAW') &&
          _inventory.contains('BAR')) {
        addMessage("Ok");
        handled = true;
      }
    } else if (verb == 'MAKE') {
      if (noun == 'CRUCIFIX' &&
          _inventory.contains('SAW') &&
          _inventory.contains('BAR')) {
        _inventory.remove('BAR');
        _inventory.add('CRUCIFIX');
        addMessage("That should prove useful.");
        handled = true;
      }
    } else if (verb == 'PULL') {
      if (noun == 'CORD' &&
          _currentRoomId == 10 &&
          _inventory.contains('IRON')) {
        addMessage("Ok");
        _gameFlags['annexe_open'] = true;
        handled = true;
      }
    } else if (verb == 'EXORCISE') {
      if (noun == 'CLOAK' &&
          _inventory.contains('BIBLE') &&
          _inventory.contains('CRUCIFIX') &&
          _inventory.contains('HOLY WATER')) {
        addMessage("Something happened in a BLINDING flash of light!!");
        _gameFlags['cloak_exorcised'] = true;
        handled = true;
      }
    } else if (verb == '1327') {
      if (_currentRoomId == 13 && _gameFlags['painting_moved'] == true) {
        addMessage("You've cracked it!");
        _gameFlags['safe_open'] = true;
        _objectLocations['GATE KEY'] = 13;
        handled = true;
      }
    }

    if (!handled) {
      if (noun.isEmpty && verb.length > 1) {
        addMessage("I don't understand you.");
      } else if (!handled) {
        addMessage("Ok. Nothing happens.");
      }
    }

    saveState();
    notifyListeners();
  }

  bool _handleGet(String noun) {
    if (isTooDarkToSee) {
      addMessage("I can't see anything significant.");
      return true;
    }

    if (_inventory.length >= maxInventory) {
      addMessage('You are carrying too much.');
      return true;
    }

    if (noun == 'WATER' && _currentRoomId == 3) {
      if (_inventory.contains('GOBLET')) {
        _inventory.remove('GOBLET');
        if (_inventory.contains('BIBLE') && _inventory.contains('CRUCIFIX')) {
          _inventory.add('HOLY WATER');
          addMessage('HOLY WATER!!');
        } else {
          _inventory.add('WATER');
          addMessage('Ok');
        }
      } else {
        addMessage("You don't have anything to put it in.");
      }
      return true;
    }

    if (noun == 'KEY') {
      if (getVisibleObjects().contains('KEY')) {
        _objectLocations['KEY'] = -1;
        _inventory.add('KEY');
        addMessage('Ok');
        return true;
      } else if (getVisibleObjects().contains('GATE KEY')) {
        _objectLocations['GATE KEY'] = -1;
        _inventory.add('GATE KEY');
        addMessage('Ok');
        return true;
      }
    }

    if (getVisibleObjects().contains(noun)) {
      _objectLocations[noun] = -1;
      _inventory.add(noun);
      addMessage('Ok');
      return true;
    }
    addMessage("I don't see it here.");
    return true;
  }

  bool _handleDrop(String noun) {
    if (noun == 'PAINTING' && _inventory.contains('PAINTING')) {
      _inventory.remove('PAINTING');
      _gameFlags['painting_moved'] = true;
      addMessage("Ok");
      return true;
    }
    if (_inventory.contains(noun)) {
      _inventory.remove(noun);
      _objectLocations[noun] = _currentRoomId;
      if (noun == 'CHAIR' || noun == 'CHEST') {
        addMessage('CRASH!!!');
      } else {
        addMessage('Ok');
      }
      return true;
    }
    addMessage("You aren't carrying it!!");
    return true;
  }

  bool _handleOpen(String noun) {
    if (noun == 'CUPBOARD' && _currentRoomId == 3) {
      _gameFlags['cupboard_open'] = true;
      addMessage("Ok");
      return true;
    }
    if (noun == 'SAFE' &&
        _currentRoomId == 13 &&
        _gameFlags['painting_moved'] == true) {
      addMessage("Enter the 4 digit combination");
      return true;
    }
    return false;
  }

  bool _handleExamine(String noun) {
    if (noun == 'CUPBOARD' &&
        _currentRoomId == 3 &&
        _gameFlags['cupboard_open'] == true) {
      if (_objectLocations['MATCHES'] == 0) _objectLocations['MATCHES'] = 3;
      if (_objectLocations['KNIFE'] == 0) _objectLocations['KNIFE'] = 3;
      addMessage("I can see something!");
      return true;
    }
    if (noun == 'SINK' && _currentRoomId == 3) {
      if (_objectLocations['WATER'] == 0) _objectLocations['WATER'] = 3;
      addMessage("I can see something!");
      return true;
    }
    if (noun == 'FIREPLACE' && _currentRoomId == 8) {
      if (_objectLocations['COAL'] == 0) _objectLocations['COAL'] = 8;
      addMessage("I can see something!");
      return true;
    }
    if (noun == 'DESK' && _currentRoomId == 7) {
      if (_objectLocations['BIBLE'] == 0) _objectLocations['BIBLE'] = 7;
      if (_objectLocations['LETTER'] == 0) _objectLocations['LETTER'] = 7;
      addMessage("I can see something!");
      return true;
    }
    if (noun == 'CHEST' &&
        _currentRoomId == _objectLocations['CHEST'] &&
        _gameFlags['chest_broken'] == true) {
      if (_objectLocations['KEY'] == 0) {
        _objectLocations['KEY'] = _currentRoomId;
      }
      addMessage("I can see something!");
      return true;
    }
    if (noun == 'SAFE' &&
        _currentRoomId == 13 &&
        _gameFlags['safe_open'] == true) {
      addMessage("I can see something!");
      return true;
    }
    if (noun == 'DOG') {
      addMessage("It has eyes like red embers.");
      return true;
    }
    if (noun == 'RAT' && _currentRoomId == 1) {
      addMessage("Looks pretty nasty!!");
      return true;
    }
    if (noun == 'SHELVES' && _currentRoomId == 16) {
      if (_objectLocations['BOOK'] == null || _objectLocations['BOOK'] == 0) _objectLocations['BOOK'] = 16;
      addMessage("I can see something!");
      return true;
    }
    if (noun == 'BIBLE') {
      addMessage("It falls open at the first page.");
      return true;
    }
    if (noun == 'WINE') {
      addMessage("French red. Maybe you should try it.");
      return true;
    }
    if (noun == 'PAINTING') {
      addMessage("It's an oil painting of two horses.");
      return true;
    }
    if (noun == 'CLOCK' || noun == 'GRANDFATHER CLOCK') {
      addMessage("It's getting terribly late!!");
      return true;
    }
    if (noun == 'BOOK') {
      addMessage("THE EXORCIST - How apt.");
      return true;
    }
    return false;
  }

  bool _handleClimb(String noun) {
    if (noun == 'CHAIR') {
      if (_currentRoomId == 3 && _objectLocations['CHAIR'] == 3) {
        addMessage("Ok, you're standing on the chair.");
        return true;
      }
    }
    return false;
  }

  bool _handleLight(String noun) {
    if (noun == 'CANDLE' &&
        _inventory.contains('CANDLE') &&
        _inventory.contains('MATCHES')) {
      _inventory.remove('CANDLE');
      _inventory.add('LIT CANDLE');
      _candleLife = 100;
      addMessage("Ok");
      return true;
    }
    return false;
  }

  bool _handleExtinguish(String noun) {
    if (noun == 'CANDLE' && _inventory.contains('LIT CANDLE')) {
      _inventory.remove('LIT CANDLE');
      _inventory.add('CANDLE');
      addMessage("It went out!!");
      return true;
    }
    return false;
  }

  bool _handleBurn(String noun) {
    if (noun == 'COAL' &&
        _currentRoomId == 26 &&
        _objectLocations['COAL'] == 26 &&
        _objectLocations['RAG'] == 26) {
      _gameFlags['dog_terrified'] = true;
      _objectLocations['COAL'] = 0;
      _objectLocations['RAG'] = 0;
      addMessage(
        "The coals glow like the dog's eyes, and he runs away, terrified!",
      );
      return true;
    }
    return false;
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
