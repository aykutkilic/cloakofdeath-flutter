import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';
import 'game/game_state.dart';
import 'widgets/room_view.dart';
import 'widgets/unified_minimap.dart';
import 'widgets/object_panel.dart';
import 'widgets/interactive_inventory.dart';
import 'widgets/game_settings_dialog.dart';
import 'widgets/save_game_dialog.dart';
import 'widgets/hint_button.dart';
import 'widgets/exploration_map_dialog.dart';
import 'widgets/safe_combination_overlay.dart';
import 'rendering/room_bytecode_loader.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RoomBytecodeLoader.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState()..initialize(),
      child: const CloakOfDeathApp(),
    ),
  );
}

class CloakOfDeathApp extends StatelessWidget {
  const CloakOfDeathApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cloak of Death',
    theme: AppTheme.themeData,
    home: const SafeCombinationOverlay(child: GameScreen()),
    debugShowCheckedModeBanner: false,
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _commandController = TextEditingController();
  final _journalScroll = ScrollController();
  String _lastTranscript = '';

  @override
  void dispose() {
    _commandController.dispose();
    _journalScroll.dispose();
    super.dispose();
  }

  void _submit(GameState game) {
    final command = _commandController.text.trim();
    if (command.isEmpty || game.isGameOver) return;
    game.processCommand(command);
    _commandController.clear();
  }

  Future<void> _restart(GameState game) async {
    if (!game.isGameOver) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start again?'),
          content: const Text(
            'Your current journey will be replaced by a new game.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('New game'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await game.reset();
    _commandController.clear();
  }

  Widget _header(
    GameState game,
    bool narrow, {
    bool compact = false,
  }) => Padding(
    padding: EdgeInsets.fromLTRB(
      narrow ? 16 : 24,
      compact ? 4 : 12,
      narrow ? 8 : 16,
      compact ? 4 : 12,
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.08),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_fire_department_outlined,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLOAK OF DEATH',
                style: TextStyle(
                  fontFamily: 'Atari',
                  fontSize: narrow ? 12 : 16,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'AN ATARI ADVENTURE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2.2,
                  color: AppTheme.mutedColor,
                ),
              ),
            ],
          ),
        ),
        if (!narrow)
          IconButton(
            tooltip: 'Display settings',
            icon: const Icon(Icons.tune),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const GameSettingsDialog(),
            ),
          ),
        const HintButton(),
        const ExplorationMapButton(),
        PopupMenuButton<String>(
          tooltip: 'Game menu',
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) {
            if (value == 'settings') {
              showDialog<void>(
                context: context,
                builder: (_) => const GameSettingsDialog(),
              );
            }
            if (value == 'saves') {
              showDialog<void>(
                context: context,
                builder: (_) => const SaveGameDialog(),
              );
            }
            if (value == 'restart') _restart(game);
            if (value == 'about') {
              showAboutDialog(
                context: context,
                applicationName: 'Cloak of Death',
                applicationVersion: 'An Atari adventure, reimagined for touch.',
                children: [
                  const Text(
                    'Original game by David Cockram, 1984.\nExplore the house, unravel its secrets, and escape.',
                  ),
                  const SizedBox(height: 16),
                  Link(
                    uri: Uri.parse(
                      'https://github.com/aykutkilic/cloakofdeath-flutter',
                    ),
                    target: LinkTarget.blank,
                    builder: (context, followLink) => TextButton.icon(
                      onPressed: followLink,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View on GitHub'),
                    ),
                  ),
                ],
              );
            }
          },
          itemBuilder: (_) => [
            if (narrow)
              const PopupMenuItem(
                value: 'settings',
                child: Text('Display settings'),
              ),
            const PopupMenuItem(
              value: 'saves',
              child: Text('Save / load game'),
            ),
            const PopupMenuItem(value: 'restart', child: Text('New game')),
            const PopupMenuItem(value: 'about', child: Text('About the game')),
          ],
        ),
      ],
    ),
  );

  Widget _status(GameState game) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _statusItem(Icons.explore_outlined, 'Turn ${game.moveCount}'),
      if (game.inventory.contains('CANDLE') ||
          game.inventory.contains('LIT CANDLE') ||
          game.candleLife < 199)
        Tooltip(
          message:
              'Burning turns remaining. Extinguishing the candle preserves its fuel.',
          child: _statusItem(
            Icons.local_fire_department_outlined,
            game.candleLife == 0 ? 'Candle spent' : 'Candle ${game.candleLife}',
            warning: game.candleLife <= 10,
          ),
        ),
      _statusItem(Icons.backpack_outlined, '${game.inventoryLoad}/6 carried'),
    ],
  );

  Widget _statusItem(IconData icon, String value, {bool warning = false}) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: warning ? AppTheme.warningColor : AppTheme.accent,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: warning ? AppTheme.warningColor : AppTheme.mutedColor,
            ),
          ),
        ],
      );

  Widget _scene(GameState game, {double maxImageHeight = 320}) => Container(
    decoration: AppTheme.panelDecoration,
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE HOUSE  /  ${game.currentRoomId.toString().padLeft(2, '0')}',
                      style: AppTheme.label,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      game.isTooDarkToSee
                          ? 'In the dark'
                          : game.currentRoom!.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Enlarge scene',
                icon: const Icon(Icons.open_in_full, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: game.aspectRatio,
                          child: RoomView(room: game.currentRoom!),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filledTonal(
                            tooltip: 'Close scene',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth = (constraints.maxWidth - 118).clamp(
                0.0,
                maxImageHeight * game.aspectRatio,
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    key: const ValueKey('room-artwork-frame'),
                    width: imageWidth,
                    height: imageWidth / game.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: RoomView(room: game.currentRoom!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 106,
                    child: Container(
                      key: const ValueKey('room-navigation-rail'),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Look around',
                            onPressed: game.isGameOver
                                ? null
                                : () => game.processCommand('LOOK'),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: AppTheme.accent,
                            ),
                          ),
                          const Divider(indent: 12, endIndent: 12),
                          const UnifiedMinimap(vertical: true),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const ObjectPanel(),
      ],
    ),
  );

  Widget _exploration(GameState game, {required bool compact}) =>
      SingleChildScrollView(
        key: const ValueKey('exploration-scroll'),
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 24,
          0,
          compact ? 12 : 20,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _status(game),
            ),
            _scene(
              game,
              maxImageHeight: compact && MediaQuery.sizeOf(context).height < 650
                  ? 120
                  : 320,
            ),
            const SizedBox(height: 12),
            const InteractiveInventory(),
          ],
        ),
      );

  Widget _journal(GameState game, {bool showHeading = true}) {
    final transcript = game.outputMessages.join('\n');
    if (_lastTranscript != transcript) {
      _lastTranscript = transcript;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _journalScroll.hasClients) {
          _journalScroll.jumpTo(_journalScroll.position.maxScrollExtent);
        }
      });
    }
    return Container(
      decoration: AppTheme.panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.subject, size: 18, color: AppTheme.accent),
                  SizedBox(width: 8),
                  Text('YOUR JOURNEY', style: AppTheme.label),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              key: const ValueKey('journey-scroll'),
              controller: _journalScroll,
              padding: const EdgeInsets.all(16),
              itemCount: game.outputMessages.length,
              itemBuilder: (context, index) {
                final message = game.outputMessages[index];
                if (message.isEmpty) return const SizedBox(height: 10);
                final command = message.startsWith('What shall I do?');
                return Padding(
                  padding: EdgeInsets.only(top: command ? 14 : 0, bottom: 3),
                  child: Text(
                    command
                        ? '› ${message.substring('What shall I do?'.length)}'
                        : message,
                    style: TextStyle(
                      color: command ? AppTheme.accent : AppTheme.text,
                      fontSize: command ? 13 : 14,
                      height: 1.55,
                      fontWeight: command ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer(GameState game) => Padding(
    padding: const EdgeInsets.all(12),
    child: game.isGameOver
        ? Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.panelDecoration,
            child: Row(
              children: [
                Icon(
                  game.hasWon ? Icons.wb_twilight : Icons.nightlight_outlined,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    game.hasWon ? 'You escaped.' : 'Your journey ends here.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => _restart(game),
                  child: const Text('Play again'),
                ),
              ],
            ),
          )
        : Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('command-input'),
                  controller: _commandController,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(fontSize: 16, color: AppTheme.text),
                  decoration: InputDecoration(
                    hintText: game.awaitingCombination
                        ? 'Enter the combination'
                        : 'What shall I do?',
                    hintStyle: const TextStyle(color: AppTheme.mutedColor),
                    prefixIcon: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.accent,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (_) => _submit(game),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send command',
                onPressed: () => _submit(game),
                style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF20322B), AppTheme.background, Color(0xFF141C1B)],
        ),
      ),
      child: SafeArea(
        child: Consumer<GameState>(
          builder: (context, game, child) {
            if (game.currentRoom == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final short = constraints.maxHeight < 500;
                final split = wide || (short && constraints.maxWidth > 580);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Column(
                      children: [
                        _header(
                          game,
                          constraints.maxWidth < 600,
                          compact: constraints.maxHeight < 650,
                        ),
                        Expanded(
                          child: split
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: short
                                          ? Column(
                                              children: [
                                                Expanded(
                                                  child: _exploration(
                                                    game,
                                                    compact: true,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : _exploration(game, compact: false),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(child: _journal(game)),
                                            _composer(game),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: _exploration(game, compact: true),
                                    ),
                                    SizedBox(
                                      height: (constraints.maxHeight * 0.2)
                                          .clamp(96.0, 160.0),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: _journal(
                                          game,
                                          showHeading: !short,
                                        ),
                                      ),
                                    ),
                                    _composer(game),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}
