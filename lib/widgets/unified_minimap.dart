import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/game_state.dart';

/// Always-visible direction controls, laid out without covering the artwork.
class UnifiedMinimap extends StatelessWidget {
  const UnifiedMinimap({super.key, this.vertical = false});

  final bool vertical;

  static const directions = <String, (String, IconData)>{
    'N': ('North', Icons.north),
    'S': ('South', Icons.south),
    'E': ('East', Icons.east),
    'W': ('West', Icons.west),
    'U': ('Up', Icons.stairs_outlined),
    'D': ('Down', Icons.stairs_outlined),
  };

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, game, child) {
      final exits = game.getAvailableExits();
      return LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 330;
          return Wrap(
            // Keep movement with the exploration action at the trailing edge.
            // Wrap maintains that intent when a narrow phone needs two rows.
            alignment: WrapAlignment.end,
            spacing: vertical ? 4 : (narrow ? 1 : 6),
            runSpacing: 8,
            children: directions.entries.map((entry) {
              final available =
                  (game.isTooDarkToSee || exits.containsKey(entry.key)) &&
                  !game.isGameOver;
              return Tooltip(
                message: entry.value.$1,
                child: Semantics(
                  label: 'Go ${entry.value.$1.toLowerCase()}',
                  child: OutlinedButton(
                    onPressed: available
                        ? () => game.processCommand(entry.key)
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.text,
                      backgroundColor: available
                          ? AppTheme.highlight
                          : Colors.transparent,
                      disabledForegroundColor: AppTheme.mutedColor.withValues(
                        alpha: 0.35,
                      ),
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      side: BorderSide(
                        color: available
                            ? AppTheme.border
                            : AppTheme.border.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!narrow) Icon(entry.value.$2, size: 16),
                        if (!narrow) const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
    },
  );
}
