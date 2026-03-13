import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game/game_state.dart';
import 'widgets/room_view.dart';
import 'widgets/unified_minimap.dart';
import 'widgets/verb_panel.dart';
import 'widgets/object_panel.dart';
import 'widgets/interactive_inventory.dart';
import 'rendering/room_bytecode_loader.dart';
import 'app_theme.dart';

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
      theme: AppTheme.themeData,
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
              backgroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppTheme.highlight, width: 2),
              ),
              title: const Text(
                'PIXEL RENDERER SETTINGS',
                style: TextStyle(
                  color: AppTheme.text,
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
                      style: TextStyle(color: AppTheme.text, fontSize: 14),
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
                            activeColor: AppTheme.text,
                            inactiveColor: AppTheme.panel,
                            label:
                                '${gameState.pixelRenderSpeed.toStringAsFixed(0)} px/s',
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
                              color: AppTheme.text,
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
                        style: TextStyle(color: AppTheme.text, fontSize: 14),
                      ),
                      value: gameState.autoAnimateRooms,
                      activeThumbColor: AppTheme.text,
                      activeTrackColor: AppTheme.highlight,
                      inactiveThumbColor: AppTheme.mutedColor,
                      inactiveTrackColor: AppTheme.panel,
                      onChanged: (value) {
                        gameState.setAutoAnimateRooms(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Authentic Atari speed: 20 px/s\nFast rendering: 200+ px/s',
                      style: TextStyle(
                        color: AppTheme.text.withValues(alpha: 0.7),
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
                      color: AppTheme.text,
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.highlight, width: 2),
          ),
          title: const Text(
            'ABOUT',
            style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Cloak of Death\n\nOriginally written for 8-bit Atari computers by David Cockram.\n\nFlutter Implementation.',
            style: TextStyle(color: AppTheme.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: AppTheme.text),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStatsDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.highlight, width: 2),
          ),
          title: const Text(
            'STATS',
            style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Moves: ${gameState.moveCount}\nInventory Items: ${gameState.inventoryCount}/${GameState.maxInventory}',
            style: const TextStyle(color: AppTheme.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CLOSE',
                style: TextStyle(color: AppTheme.text),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            final room = gameState.currentRoom;

            if (room == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.text),
              );
            }

            // Scroll to bottom when messages update
            _scrollToBottom();

            return Column(
              children: [
                // Main game area: Unified Minimap, Room view, and Interactive panels
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Unified minimap (navigation integrated)
                        const SizedBox(width: 120, child: UnifiedMinimap()),
                        const SizedBox(width: 8),

                        // Center: Room name, Room visualization, Inventory
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Room visualization
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                      color: AppTheme.highlight,
                                      width: 2,
                                    ),
                                  ),
                                  child: RoomView(room: room),
                                ),
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
                        const SizedBox(width: 8),

                        // Right: Interactive panels (verbs, objects)
                        SizedBox(
                          width: 180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Right Menus
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.settings,
                                      color: AppTheme.text,
                                    ),
                                    onPressed: () {
                                      _showSettingsDialog(context);
                                    },
                                    tooltip: 'Settings',
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.menu,
                                      color: AppTheme.text,
                                    ),
                                    color: AppTheme.panel,
                                    onSelected: (value) {
                                      if (value == 'restart') {
                                        context.read<GameState>().reset();
                                      } else if (value == 'about') {
                                        _showAboutDialog(context);
                                      } else if (value == 'stats') {
                                        _showStatsDialog(context, gameState);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'restart',
                                            child: Text(
                                              'Restart',
                                              style: TextStyle(
                                                color: AppTheme.text,
                                                fontFamily: 'Atari',
                                              ),
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'about',
                                            child: Text(
                                              'About',
                                              style: TextStyle(
                                                color: AppTheme.text,
                                                fontFamily: 'Atari',
                                              ),
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'stats',
                                            child: Text(
                                              'Stats',
                                              style: TextStyle(
                                                color: AppTheme.text,
                                                fontFamily: 'Atari',
                                              ),
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Verb panel
                              const Expanded(flex: 3, child: VerbPanel()),
                              const SizedBox(height: 4),
                              // Object panel
                              const Expanded(flex: 2, child: ObjectPanel()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Game output text
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.panel,
                      border: Border.all(color: AppTheme.highlight, width: 2),
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
                              color: AppTheme.text,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.panel,
                    border: Border.all(color: AppTheme.highlight, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '>',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commandController,
                          autofocus: true,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 16,
                          ),
                          cursorColor: AppTheme.text,
                          cursorWidth: 10,
                          cursorRadius: const Radius.circular(0),
                          decoration: InputDecoration(
                            fillColor: AppTheme.panel,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Enter command...',
                            hintStyle: TextStyle(
                              color: AppTheme.text.withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            if (value != value.toUpperCase()) {
                              _commandController.value = _commandController.value.copyWith(
                                text: value.toUpperCase(),
                                selection: TextSelection.collapsed(offset: value.length),
                              );
                            }
                          },
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              gameState.processCommand(value.toUpperCase());
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
                    color: AppTheme.panel,
                    border: Border(top: BorderSide(color: AppTheme.highlight)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Room ${room.id}',
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Inventory: ${gameState.inventoryCount}/${GameState.maxInventory}',
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Moves: ${gameState.moveCount}',
                        style: const TextStyle(
                          color: AppTheme.text,
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
      ),
    );
  }
}
