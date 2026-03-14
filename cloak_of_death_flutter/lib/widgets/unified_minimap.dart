import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/game_state.dart';

/// Unified minimap widget with integrated navigation controls.
/// Larger buttons for easy touch interaction.
class UnifiedMinimap extends StatelessWidget {
  const UnifiedMinimap({super.key});

  static const double _buttonSize = 48;
  static const double _spacing = 6;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final exits = gameState.getAvailableExits();

        return Container(
          decoration: const BoxDecoration(color: AppTheme.background),
          padding: const EdgeInsets.all(8),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: UP/DOWN stack
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavButton('U', exits.containsKey('U'), gameState, context),
                      SizedBox(height: _spacing),
                      _buildNavButton('D', exits.containsKey('D'), gameState, context),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Right side: Compass cross
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavButton('N', exits.containsKey('N'), gameState, context),
                      SizedBox(height: _spacing),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavButton('W', exits.containsKey('W'), gameState, context),
                          SizedBox(width: _spacing),
                          _buildCenterIcon(),
                          SizedBox(width: _spacing),
                          _buildNavButton('E', exits.containsKey('E'), gameState, context),
                        ],
                      ),
                      SizedBox(height: _spacing),
                      _buildNavButton('S', exits.containsKey('S'), gameState, context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton(
    String direction,
    bool hasExit,
    GameState gameState,
    BuildContext context,
  ) {
    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: ElevatedButton(
        onPressed: () => gameState.processCommand(direction),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasExit ? AppTheme.highlight : AppTheme.background,
          foregroundColor: hasExit ? AppTheme.text : AppTheme.panel,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide.none,
          elevation: 0,
        ),
        child: Text(
          direction,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: hasExit ? AppTheme.text : AppTheme.panel,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    return Container(
      width: _buttonSize,
      height: _buttonSize,
      decoration: BoxDecoration(color: AppTheme.highlight.withAlpha(77)),
      child: const Icon(Icons.person, color: AppTheme.text, size: 28),
    );
  }
}
