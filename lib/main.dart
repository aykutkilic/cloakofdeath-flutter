import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'game/game_state.dart';
import 'widgets/room_view.dart';
import 'widgets/unified_minimap.dart';
import 'widgets/object_panel.dart';
import 'widgets/interactive_inventory.dart';
import 'rendering/room_bytecode_loader.dart';
import 'app_theme.dart';
import 'models/room.dart';

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
  final FocusNode _commandFocusNode = FocusNode();
  final GlobalKey _roomViewKey = GlobalKey();
  bool _isFullScreen = false;

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    _commandFocusNode.dispose();
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
                            max: 5000,
                            divisions: 100,
                            activeColor: AppTheme.text,
                            inactiveColor: AppTheme.panel,
                            label:
                                '${gameState.pixelRenderSpeed.toStringAsFixed(0)} px/s',
                            onChanged: (value) {                              gameState.setPixelRenderSpeed(value);
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
                    const SizedBox(height: 16),
                    const Text(
                      'Aspect Ratio',
                      style: TextStyle(color: AppTheme.text, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: gameState.aspectRatio,
                            min: 1.0,
                            max: 3.0,
                            divisions: 40,
                            activeColor: AppTheme.text,
                            inactiveColor: AppTheme.panel,
                            label: gameState.aspectRatio.toStringAsFixed(2),
                            onChanged: (value) {
                              gameState.setAspectRatio(value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            gameState.aspectRatio.toStringAsFixed(2),
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        _aspectPresetButton(gameState, 'Atari', 160.0 / 96.0),
                        _aspectPresetButton(gameState, '4:3', 4.0 / 3.0),
                        _aspectPresetButton(gameState, '16:9', 16.0 / 9.0),
                      ],
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

  Widget _aspectPresetButton(GameState gameState, String label, double ratio) {
    final isActive = (gameState.aspectRatio - ratio).abs() < 0.01;
    return TextButton(
      onPressed: () => gameState.setAspectRatio(ratio),
      style: TextButton.styleFrom(
        backgroundColor: isActive ? AppTheme.highlight : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.text,
          fontSize: 11,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMenuButtons(BuildContext context, GameState gameState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.settings, color: AppTheme.text, size: 20),
          onPressed: () => _showSettingsDialog(context),
          tooltip: 'Settings',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: AppTheme.text, size: 20),
          color: AppTheme.panel,
          padding: EdgeInsets.zero,
          onSelected: (value) {
            if (value == 'restart') {
              context.read<GameState>().reset();
            } else if (value == 'about') {
              _showAboutDialog(context);
            } else if (value == 'stats') {
              _showStatsDialog(context, gameState);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'restart',
              child: Text('Restart', style: TextStyle(color: AppTheme.text, fontFamily: 'Atari')),
            ),
            const PopupMenuItem<String>(
              value: 'about',
              child: Text('About', style: TextStyle(color: AppTheme.text, fontFamily: 'Atari')),
            ),
            const PopupMenuItem<String>(
              value: 'stats',
              child: Text('Stats', style: TextStyle(color: AppTheme.text, fontFamily: 'Atari')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommandInput(GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(color: AppTheme.panel),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _commandController,
              builder: (context, value, child) {
                final isEmpty = value.text.isEmpty;
                return TextField(
                  controller: _commandController,
                  focusNode: _commandFocusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UppercaseTextFormatter()],
                  style: TextStyle(
                    color: isEmpty ? AppTheme.panel : AppTheme.text,
                    fontSize: 16,
                    backgroundColor: isEmpty ? AppTheme.text : Colors.transparent,
                  ),
                  cursorColor: isEmpty ? AppTheme.panel : AppTheme.text,
                  cursorWidth: 10,
                  cursorRadius: const Radius.circular(0),
                  decoration: InputDecoration(
                    fillColor: isEmpty ? AppTheme.text : Colors.transparent,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'What shall I do?',
                    hintStyle: TextStyle(
                      color: AppTheme.panel.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                      backgroundColor: AppTheme.text,
                    ),
                  ),
                  onSubmitted: (submitValue) {
                    if (submitValue.trim().isNotEmpty) {
                      gameState.processCommand(submitValue.toUpperCase());
                      _commandController.clear();
                      _commandFocusNode.requestFocus();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextOutput(GameState gameState) {
    return Container(
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
              style: const TextStyle(color: AppTheme.text, fontSize: 14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullScreenView(Room room) {
    return Expanded(
      flex: 11,
      child: Stack(
        children: [
          SizedBox.expand(child: RoomView(key: _roomViewKey, room: room)),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit, color: AppTheme.text),
              onPressed: () => setState(() => _isFullScreen = false),
            ),
          ),
        ],
      ),
    );
  }

  /// Landscape layout: nav left, room center, objects right
  Widget _buildLandscapeLayout(BuildContext context, GameState gameState, Room room) {
    return Expanded(
      flex: 11,
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Navigation + settings
            SizedBox(
              width: 160,
              child: Column(
                children: [
                  _buildMenuButtons(context, gameState),
                  const SizedBox(height: 4),
                  const Expanded(child: UnifiedMinimap()),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Center: Room visualization + Inventory
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: gameState.aspectRatio,
                        child: Stack(
                          children: [
                            SizedBox.expand(child: RoomView(key: _roomViewKey, room: room)),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen, color: AppTheme.text, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() => _isFullScreen = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Expanded(flex: 1, child: InteractiveInventory()),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: Objects panel
            SizedBox(
              width: 150,
              child: SingleChildScrollView(child: const ObjectPanel()),
            ),
          ],
        ),
      ),
    );
  }

  /// Portrait layout: room with floating nav, then inventory+objects row
  Widget _buildPortraitLayout(BuildContext context, GameState gameState, Room room) {
    return Expanded(
      flex: 11,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar: settings
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildMenuButtons(context, gameState)],
            ),
            const SizedBox(height: 4),

            // Room view with floating navigation overlay
            Expanded(
              flex: 5,
              child: Center(
                child: AspectRatio(
                  aspectRatio: gameState.aspectRatio,
                  child: Stack(
                    children: [
                      SizedBox.expand(child: RoomView(key: _roomViewKey, room: room)),
                      // Floating navigation — bottom left
                      const Positioned(
                        left: 4,
                        bottom: 4,
                        child: UnifiedMinimap(floating: true),
                      ),
                      // Fullscreen button — top right
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen, color: AppTheme.text, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _isFullScreen = true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Inventory + Objects side by side, each 3 rows tall and scrollable
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  // Inventory: 4 columns, scrollable
                  Expanded(child: InteractiveInventory(crossAxisCount: 4)),
                  SizedBox(width: 4),
                  // Objects: scrollable list
                  Expanded(child: ObjectPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
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

            _scrollToBottom();

            final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

            return Column(
              children: [
                // Main game area
                if (_isFullScreen)
                  _buildFullScreenView(room)
                else if (isPortrait)
                  _buildPortraitLayout(context, gameState, room)
                else
                  _buildLandscapeLayout(context, gameState, room),

                // Game output text
                Expanded(flex: 5, child: _buildTextOutput(gameState)),

                // Command input
                _buildCommandInput(gameState),
              ],
            );
          },
        ),
      ),
    );
  }
}

class UppercaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
