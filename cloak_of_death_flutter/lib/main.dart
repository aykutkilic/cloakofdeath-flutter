import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game/game_state.dart';
import 'widgets/room_view.dart';
import 'widgets/unified_minimap.dart';
import 'widgets/verb_panel.dart';
import 'widgets/object_panel.dart';
import 'widgets/interactive_inventory.dart';
import 'rendering/room_bytecode_loader.dart';

void main() async {
  // Ensure Flutter is initialized before loading assets
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize room bytecode loader
  await RoomBytecodeLoader.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState()..initialize(),
      child: const CloakOfDeathApp(),
    ),
  );
}

class CloakOfDeathApp extends StatelessWidget {
  const CloakOfDeathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloak of Death',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Courier',
            color: Colors.green,
            fontSize: 14,
          ),
        ),
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Consumer<GameState>(
          builder: (context, gameState, child) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              title: const Text(
                'PIXEL RENDERER SETTINGS',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Render Speed',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: gameState.pixelRenderSpeed,
                            min: 1,
                            max: 500,
                            divisions: 100,
                            activeColor: Colors.green,
                            inactiveColor: Colors.green.shade900,
                            label: '${gameState.pixelRenderSpeed.toStringAsFixed(0)} px/s',
                            onChanged: (value) {
                              gameState.setPixelRenderSpeed(value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            '${gameState.pixelRenderSpeed.toStringAsFixed(0)} px/s',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              color: Colors.green,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Auto-animate rooms',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                      value: gameState.autoAnimateRooms,
                      activeThumbColor: Colors.green,
                      onChanged: (value) {
                        gameState.setAutoAnimateRooms(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Authentic Atari speed: 20 px/s\nFast rendering: 200+ px/s',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.green,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CLOAK OF DEATH',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.green),
            onPressed: () {
              _showSettingsDialog(context);
            },
            tooltip: 'Render Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: () {
              context.read<GameState>().reset();
            },
            tooltip: 'Reset Game',
          ),
        ],
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          final room = gameState.currentRoom;

          if (room == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          // Scroll to bottom when messages update
          _scrollToBottom();

          return Column(
            children: [
              // Main game area: Unified Minimap, Room view, and Interactive panels
              Container(
                height: 400,
                margin: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Unified minimap (navigation integrated)
                    const SizedBox(
                      width: 120,
                      child: UnifiedMinimap(),
                    ),
                    const SizedBox(width: 8),

                    // Center: Room name and vector view
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Room name
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF001100),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: Text(
                              room.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Room visualization
                          Expanded(
                            child: RoomView(room: room),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right: Interactive panels (verbs, objects, inventory)
                    SizedBox(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Verb panel
                          const Expanded(
                            flex: 3,
                            child: VerbPanel(),
                          ),
                          const SizedBox(height: 4),
                          // Object panel
                          const Expanded(
                            flex: 2,
                            child: ObjectPanel(),
                          ),
                          const SizedBox(height: 4),
                          // Interactive inventory
                          const Expanded(
                            flex: 2,
                            child: InteractiveInventory(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Game output text
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: gameState.outputMessages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          gameState.outputMessages[index],
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Command input
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Text(
                      '>',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commandController,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          color: Colors.green,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.green, width: 2),
                          ),
                          hintText: 'Enter command...',
                          hintStyle: TextStyle(
                            color: Colors.green,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            gameState.processCommand(value);
                            _commandController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Status bar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF001100),
                  border: Border(top: BorderSide(color: Colors.green)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room ${room.id}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Inventory: ${gameState.inventoryCount}/${GameState.maxInventory}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Moves: ${gameState.moveCount}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
