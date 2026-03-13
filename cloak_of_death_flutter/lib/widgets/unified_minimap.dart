import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/game_state.dart';

/// Unified minimap widget with integrated navigation controls
class UnifiedMinimap extends StatelessWidget {
  const UnifiedMinimap({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final exits = gameState.getAvailableExits();

        return Container(
          decoration: const BoxDecoration(color: AppTheme.background),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Title

              // Navigation grid
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: UP/DOWN stack
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildNavButton(
                              'U',
                              exits.containsKey('U'),
                              gameState,
                              context,
                            ),
                            const SizedBox(height: 4),
                            _buildNavButton(
                              'D',
                              exits.containsKey('D'),
                              gameState,
                              context,
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Right side: Compass cross
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildNavButton(
                              'N',
                              exits.containsKey('N'),
                              gameState,
                              context,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildNavButton(
                                  'W',
                                  exits.containsKey('W'),
                                  gameState,
                                  context,
                                ),
                                const SizedBox(width: 4),
                                _buildCenterIcon(),
                                const SizedBox(width: 4),
                                _buildNavButton(
                                  'E',
                                  exits.containsKey('E'),
                                  gameState,
                                  context,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _buildNavButton(
                              'S',
                              exits.containsKey('S'),
                              gameState,
                              context,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton(
    String direction,
    bool hasExit,
    GameState gameState,
    BuildContext context, {
    double? width,
  }) {
    final labels = {'N': 'N', 'S': 'S', 'E': 'E', 'W': 'W', 'U': 'U', 'D': 'D'};

    return SizedBox(
      width: width ?? 30,
      height: 30,
      child: ElevatedButton(
        onPressed: () => gameState.processCommand(direction),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasExit ? AppTheme.highlight : AppTheme.background,
          foregroundColor: hasExit ? AppTheme.text : AppTheme.panel,
          padding: const EdgeInsets.all(1),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide.none,
          elevation: 0,
        ),
        child: FittedBox(
          child: Text(
            labels[direction] ?? direction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasExit ? AppTheme.text : AppTheme.panel,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: AppTheme.highlight.withAlpha(77)),
      child: const Icon(Icons.person, color: AppTheme.text, size: 20),
    );
  }
}
