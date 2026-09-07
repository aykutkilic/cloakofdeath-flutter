import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_data.dart';
import '../models/room.dart';
import 'adventure_engine.dart';
import 'adventure_hints.dart';

/// Flutter adapter: transcript/settings stay outside the deterministic rules.
class GameState extends ChangeNotifier {
  GameData? _gameData;
  AdventureEngine _engine = AdventureEngine();
  List<String> _outputMessages = [];
  String? _selectedObject;
  double _pixelRenderSpeed = 2000;
  bool _autoAnimateRooms = true;
  bool _showDebugInfo = false;
  double _aspectRatio = 160 / 96;
  Future<void> _pendingSave = Future.value();

  static const int maxInventory = AdventureEngine.capacity;
  GameData? get gameData => _gameData;
  Room? get currentRoom => _gameData?.getRoomById(currentRoomId);
  List<String> get inventory => List.unmodifiable(_engine.inventory);
  int get inventoryCount => inventory.length;
  int get inventoryLoad => _engine.inventoryLoad;
  List<String> get outputMessages => List.unmodifiable(_outputMessages);
  int get moveCount => _engine.moves;
  int get currentRoomId => _engine.room;
  String? get selectedObject => _selectedObject;
  double get pixelRenderSpeed => _pixelRenderSpeed;
  bool get autoAnimateRooms => _autoAnimateRooms;
  bool get showDebugInfo => _showDebugInfo;
  double get aspectRatio => _aspectRatio;
  bool get isDark => currentRoomId > 14 && currentRoomId != 27;
  bool get hasLitCandle => _engine.hasLight;
  bool get isTooDarkToSee => _engine.isDark;
  int get candleLife => _engine.candleLife;
  bool get isGameOver => !_engine.isPlaying;
  bool get hasWon => _engine.outcome == 'won';
  bool get awaitingCombination => _engine.awaitingCombination;
  AdventureHint get nextHint => AdventureHints.next(
    _engine,
    (id) => _gameData?.getRoomById(id)?.name ?? 'room $id',
  );

  String? get darknessGuidance {
    if (!isTooDarkToSee) return null;
    if ((currentRoomId == 22 || currentRoomId == 23) &&
        !_engine.flag('door_propped')) {
      return 'The cellar door has slammed shut. Its broken latch prevents '
          'escape upstairs. The chest must be left by the open door before '
          'entering to keep it propped open.';
    }
    return 'You can try the direction buttons by touch. Light your candle '
        'from the inventory to see your surroundings.';
  }

  Future<void> initialize() async {
    _gameData = await GameData.loadFromAssets();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cloak_save_state');
    if (saved == null) {
      _initNewGame();
    } else {
      try {
        final data = Map<String, dynamic>.from(json.decode(saved));
        _engine = AdventureEngine.fromJson(data);
        _outputMessages = List<String>.from(data['outputMessages'] ?? []);
        for (final message in _engine.messages) {
          addMessage(message);
        }
      } catch (_) {
        _initNewGame();
        addMessage('The saved game could not be read. A new game has started.');
      }
    }
    notifyListeners();
  }

  Future<void> saveState() {
    // Capture now and serialize writes so rapid commands cannot reorder saves.
    final snapshot = json.encode({
      ..._engine.toJson(),
      'outputMessages': List<String>.of(_outputMessages),
    });
    _pendingSave = _pendingSave
        .catchError((Object error) {
          debugPrint('Previous game save failed: $error');
        })
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cloak_save_state', snapshot);
        });
    return _pendingSave;
  }

  void _initNewGame() {
    _engine = AdventureEngine();
    _selectedObject = null;
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

  void setAspectRatio(double ratio) {
    _aspectRatio = ratio.clamp(1.0, 4.0);
    notifyListeners();
  }

  Map<String, int> getAvailableExits() =>
      _engine.exits(currentRoom?.connections ?? {});
  List<String> getVisibleObjects() => List.unmodifiable(_engine.visible);
  void selectObject(String object) {
    _selectedObject = object;
    notifyListeners();
  }

  void clearSelectedObject() {
    _selectedObject = null;
    notifyListeners();
  }

  List<String> getAvailableActionsForObject(String object) {
    final actions = <String>['LOOK'];
    if (_engine.held(object)) {
      actions.add('DROP');
    } else if (AdventureEngine.portable.contains(object)) {
      actions.add('GET');
    }
    switch (object) {
      case 'CORRIDOR':
      case 'PASSAGEWAY':
      case 'ANNEXE':
        actions.add('GO');
      case 'DOOR':
      case 'GATE':
      case 'HATCH':
        actions.addAll(['OPEN', 'GO']);
        if (object == 'HATCH') actions.add('REMOVE NAILS');
      case 'SAFE':
        actions.add('OPEN');
      case 'CANDLE':
        actions.add('LIGHT');
      case 'LIT CANDLE':
        actions.add('EXTINGUISH');
      case 'MATCHES':
      case 'COAL':
      case 'RAG':
        actions.add('BURN');
      case 'BIBLE':
      case 'BOOK':
      case 'LETTER':
        actions.add('READ');
        if (object == 'BOOK') actions.add('PUSH');
      case 'CHAIR':
        actions.add('CLIMB');
      case 'CHEST':
        actions.addAll(['OPEN', 'KICK']);
      case 'TABLE':
        actions.add('PUSH');
      case 'CORD':
        actions.add('PULL');
      case 'BAR':
        actions.add('CUT');
      case 'BAR PIECES':
      case 'WIRE':
        actions.add('MAKE CROSS');
      case 'HAMMER':
        if (currentRoomId == 21) actions.add('REMOVE NAILS');
      case 'CLOAK':
        actions.add('EXORCISE');
      case 'SINK':
        actions.add('GET');
      case 'GOBLET OF WATER':
      case 'HOLY WATER':
        actions.add('POUR');
      case 'WINE':
        actions.add('DRINK');
      case 'BREAD':
        actions.add('EAT');
      case 'RAT':
      case 'DOG':
        actions.add('FEED');
    }
    return actions;
  }

  void executeObjectVerb(String verb, String object) {
    _selectedObject = null;
    // Puzzle actions name their actual target, which may not be a selectable
    // object yet (the cross) or a separate object at all (the hatch's nails).
    if (verb == 'MAKE CROSS' || verb == 'REMOVE NAILS') {
      processCommand(verb);
      return;
    }
    final target = verb == 'MAKE'
        ? 'CRUCIFIX'
        : verb == 'GET' && object == 'SINK'
        ? 'WATER'
        : object;
    processCommand('$verb $target');
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
      final description = room.description.replaceFirst(RegExp(r'\.+$'), '');
      addMessage('You are $description.');
      final exits = getAvailableExits();
      if (exits.isNotEmpty) {
        final mappedExits = exits.keys
            .map((e) {
              switch (e) {
                case 'N':
                  return 'North';
                case 'S':
                  return 'South';
                case 'E':
                  return 'East';
                case 'W':
                  return 'West';
                case 'U':
                  return 'Up';
                case 'D':
                  return 'Down';
                default:
                  return e;
              }
            })
            .join(",");
        addMessage('Exits are $mappedExits.');
      }

      final visible = getVisibleObjects();
      if (visible.isNotEmpty) {
        final mappedItems = visible
            .map((obj) {
              switch (obj) {
                case 'RAT':
                  return 'Hungry looking rat.';
                case 'CHAIR':
                  return 'Wicker chair.';
                case 'BREAD':
                  return 'Half eaten loaf of bread.';
                case 'KNIFE':
                  return 'Carving knife.';
                case 'CUPBOARD':
                  return 'Tall cupboard.';
                case 'SINK':
                  return 'Sink.';
                case 'FIREPLACE':
                  return 'Fireplace.';
                case 'COAL':
                  return 'Lumps of coal.';
                case 'CLOCK':
                  return 'Grandfather clock.';
                case 'DESK':
                  return 'Writing desk.';
                case 'BIBLE':
                  return 'Leather bound BIBLE.';
                case 'LETTER':
                  return 'Letter.';
                case 'CHEST':
                  return 'Old wooden chest.';
                case 'DOOR':
                  return 'Cellar door.';
                case 'KEY':
                  return 'Small key.';
                case 'CANDLE':
                  return 'Candle.';
                case 'IRON':
                  return 'Huge lump of iron.';
                case 'SAW':
                  return 'Rusty saw.';
                case 'HAMMER':
                  return 'Claw hammer.';
                case 'BAR':
                  return 'SILVER BAR.';
                case 'RAG':
                  return 'Oil soaked rag.';
                case 'DOG':
                  return 'Ferocious dog.';
                case 'GATE':
                  return 'Heavy iron gates.';
                case 'EMBERS':
                  return 'Burning embers.';
                case 'BOOK':
                  return 'Book.';
                case 'SHELVES':
                  return 'Shelves full of books.';
                case 'PASSAGEWAY':
                  return 'Secret passageway.';
                case 'WATER':
                  return 'Water.';
                case 'WINE':
                  return 'Bottle of wine.';
                default:
                  return '${obj[0]}${obj.substring(1).toLowerCase()}.';
              }
            })
            .join(" ");
        addMessage('Visible items: $mappedItems');
      }
    }
    addMessage('');
  }

  void processCommand(String command) {
    if (command.trim().isEmpty || isGameOver) return;
    addMessage('What shall I do?${command.toUpperCase()}');
    _engine.execute(command, currentRoom?.connections ?? {});
    if (_engine.describeRoom && !isGameOver) describeCurrentRoom();
    for (final message in _engine.messages) {
      addMessage(message);
    }
    saveState().catchError((Object error) {
      debugPrint('Game save failed: $error');
    });
    notifyListeners();
  }

  bool moveInDirection(String direction) {
    final before = currentRoomId;
    processCommand(direction);
    return before != currentRoomId;
  }

  Future<void> reset() async {
    await _pendingSave;
    _initNewGame();
    await saveState();
    notifyListeners();
  }
}
