import 'package:flutter/foundation.dart';
import '../models/game_data.dart';
import '../models/room.dart';

/// Manages the current game state
class GameState extends ChangeNotifier {
  GameData? _gameData;
  int _currentRoomId = 1;
  final List<String> _inventory = [];
  final Map<String, bool> _gameFlags = {};
  final List<String> _outputMessages = [];
  int _moveCount = 0;
  String? _selectedVerb;

  // Pixel renderer configuration
  double _pixelRenderSpeed = 2000.0; // pixels per second
  bool _autoAnimateRooms = true;

  // Game constants
  static const int maxInventory = 6;

  // Basic room connectivity map (temporary - will be replaced with extracted data)
  // Maps room_id -> direction -> destination_room_id
  static const Map<int, Map<String, int>> _roomConnections = {
    1: {'N': 2, 'W': 3, 'E': 4},
    2: {'S': 1, 'N': 5, 'E': 6},
    3: {'E': 1, 'N': 7, 'W': 8},
    4: {'W': 1, 'N': 9, 'E': 10},
    5: {'S': 2, 'N': 11, 'E': 12},
    6: {'W': 2, 'S': 4, 'N': 13},
    7: {'S': 3, 'E': 8, 'N': 14},
    8: {'E': 3, 'W': 7, 'N': 15},
    9: {'S': 4, 'E': 10, 'N': 16},
    10: {'W': 9, 'S': 4, 'N': 17},
    11: {'S': 5, 'N': 18, 'E': 19},
    12: {'W': 5, 'S': 6, 'N': 20},
    13: {'S': 6, 'E': 14, 'N': 21},
    14: {'W': 13, 'S': 7, 'N': 22},
    15: {'S': 8, 'E': 16, 'N': 23},
    16: {'W': 15, 'S': 9, 'N': 24},
    17: {'S': 10, 'E': 18, 'N': 25},
    18: {'W': 17, 'S': 11, 'N': 26},
    19: {'W': 11, 'E': 20, 'N': 27},
    20: {'E': 19, 'S': 12, 'W': 21},
    21: {'S': 13, 'E': 20, 'W': 22},
    22: {'E': 21, 'S': 14, 'W': 23},
    23: {'E': 22, 'S': 15, 'W': 24},
    24: {'E': 23, 'S': 16, 'W': 25},
    25: {'E': 24, 'S': 17, 'W': 26},
    26: {'E': 25, 'S': 18, 'W': 27},
    27: {'E': 26, 'S': 19},
  };

  // Getters
  GameData? get gameData => _gameData;
  Room? get currentRoom => _gameData?.getRoomById(_currentRoomId);
  List<String> get inventory => List.unmodifiable(_inventory);
  int get inventoryCount => _inventory.length;
  List<String> get outputMessages => List.unmodifiable(_outputMessages);
  int get moveCount => _moveCount;
  int get currentRoomId => _currentRoomId;
  String? get selectedVerb => _selectedVerb;
  double get pixelRenderSpeed => _pixelRenderSpeed;
  bool get autoAnimateRooms => _autoAnimateRooms;

  /// Get available exits from current room
  Map<String, int> getAvailableExits() {
    return _roomConnections[_currentRoomId] ?? {};
  }

  /// Get all rooms connected to the current room
  List<int> getConnectedRooms() {
    final exits = getAvailableExits();
    return exits.values.toList();
  }

  /// Check if a direction is available from current room
  bool canMove(String direction) {
    final exits = getAvailableExits();
    return exits.containsKey(direction.toUpperCase());
  }

  /// Get visible objects in current room
  List<String> getVisibleObjects() {
    final room = currentRoom;
    if (room == null) return [];
    return List.from(room.objects);
  }

  /// Select a verb for the next action
  void selectVerb(String verb) {
    _selectedVerb = verb;
    addMessage('[$verb] selected. Click an object or inventory item.');
    notifyListeners();
  }

  /// Clear the selected verb
  void clearSelectedVerb() {
    _selectedVerb = null;
    notifyListeners();
  }

  /// Execute a verb-object command
  void executeVerbObject(String verb, String object) {
    final command = '$verb $object';
    _selectedVerb = null; // Clear selection after use
    processCommand(command);
  }

  /// Set pixel render speed (pixels per second)
  void setPixelRenderSpeed(double speed) {
    _pixelRenderSpeed = speed.clamp(1.0, 500.0);
    notifyListeners();
  }

  /// Toggle auto-animation of rooms
  void setAutoAnimateRooms(bool value) {
    _autoAnimateRooms = value;
    notifyListeners();
  }

  /// Initialize game data
  Future<void> initialize() async {
    _gameData = await GameData.loadFromAssets();
    _currentRoomId = 1; // Start in room 1
    addMessage('Welcome to CLOAK OF DEATH');
    addMessage('by David Cockram. Remember, in the dead of night,');
    addMessage('no-one will hear your SCREAMS!!!');
    addMessage('');
    describeCurrentRoom();
    notifyListeners();
  }

  /// Move to a different room
  void moveToRoom(int roomId) {
    final room = _gameData?.getRoomById(roomId);
    if (room != null) {
      _currentRoomId = roomId;
      _moveCount++;
      describeCurrentRoom();
      notifyListeners();
    }
  }

  /// Move in a specific direction (N, S, E, W, U, D)
  bool moveInDirection(String direction) {
    final dir = direction.toUpperCase();
    final exits = getAvailableExits();

    if (exits.containsKey(dir)) {
      final destRoom = exits[dir]!;
      moveToRoom(destRoom);
      return true;
    } else {
      addMessage("You can't go that way.");
      return false;
    }
  }

  /// Add an item to inventory
  bool addToInventory(String item) {
    if (_inventory.length >= maxInventory) {
      addMessage('You are carrying too much.');
      return false;
    }
    _inventory.add(item);
    notifyListeners();
    return true;
  }

  /// Remove an item from inventory
  bool removeFromInventory(String item) {
    if (_inventory.remove(item)) {
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Check if player has an item
  bool hasItem(String item) {
    return _inventory.contains(item);
  }

  /// Set a game flag
  void setFlag(String flag, bool value) {
    _gameFlags[flag] = value;
    notifyListeners();
  }

  /// Get a game flag value
  bool getFlag(String flag) {
    return _gameFlags[flag] ?? false;
  }

  /// Add a message to the output
  void addMessage(String message) {
    _outputMessages.add(message);
    // Keep only last 100 messages to avoid memory issues
    if (_outputMessages.length > 100) {
      _outputMessages.removeAt(0);
    }
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _outputMessages.clear();
    notifyListeners();
  }

  /// Describe the current room
  void describeCurrentRoom() {
    final room = currentRoom;
    if (room == null) return;

    addMessage('');
    addMessage('You are ${room.description}');
    if (room.exits.isNotEmpty) {
      addMessage('Exits are ${room.exits.join(", ")}.');
    }
    addMessage('');
  }

  /// Process a command (to be expanded)
  void processCommand(String command) {
    if (command.trim().isEmpty) return;

    addMessage('> $command');
    _moveCount++;

    // Simple command processing (to be expanded)
    final words = command.trim().toUpperCase().split(' ');
    if (words.isEmpty) return;

    final verb = words[0];

    // Basic commands for testing
    switch (verb) {
      case 'LOOK':
      case 'L':
        describeCurrentRoom();
        break;

      case 'INVENTORY':
      case 'I':
        if (_inventory.isEmpty) {
          addMessage('You are carrying nothing whatsoever.');
        } else {
          addMessage('You are carrying: ${_inventory.join(", ")}');
        }
        break;

      case 'HELP':
        addMessage(
          'Available commands: LOOK, INVENTORY, NORTH, SOUTH, EAST, WEST, UP, DOWN',
        );
        addMessage('More commands to be implemented...');
        break;

      case 'NORTH':
      case 'N':
        moveInDirection('N');
        break;

      case 'SOUTH':
      case 'S':
        moveInDirection('S');
        break;

      case 'EAST':
      case 'E':
        moveInDirection('E');
        break;

      case 'WEST':
      case 'W':
        moveInDirection('W');
        break;

      case 'UP':
      case 'U':
        moveInDirection('U');
        break;

      case 'DOWN':
      case 'D':
        moveInDirection('D');
        break;

      default:
        addMessage("I don't understand you.");
    }

    notifyListeners();
  }

  /// Reset the game
  void reset() {
    _currentRoomId = 1;
    _inventory.clear();
    _gameFlags.clear();
    _outputMessages.clear();
    _moveCount = 0;
    _selectedVerb = null;
    addMessage('Game reset.');
    describeCurrentRoom();
    notifyListeners();
  }
}
