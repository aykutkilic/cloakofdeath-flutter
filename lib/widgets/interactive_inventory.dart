import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../app_theme.dart';
import 'verb_panel.dart';
import 'object_icon.dart';

class InteractiveInventory extends StatelessWidget {
  final int crossAxisCount;
  const InteractiveInventory({super.key, this.crossAxisCount = 6});

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, game, child) => Container(
      decoration: AppTheme.panelDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('INVENTORY', style: AppTheme.label)),
              Tooltip(
                message: 'Six carrying units. The iron weighs four units.',
                child: Text(
                  '${game.inventoryLoad} / ${GameState.maxInventory} units',
                  style: TextStyle(
                    color: game.inventoryLoad == GameState.maxInventory
                        ? AppTheme.accent
                        : AppTheme.mutedColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (game.inventory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.backpack_outlined, color: AppTheme.mutedColor),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your hands are empty.',
                      style: TextStyle(color: AppTheme.mutedColor),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 105).floor().clamp(
                  1,
                  crossAxisCount,
                );
                final width =
                    (constraints.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: game.inventory
                      .map(
                        (item) => SizedBox(
                          width: width,
                          child: OutlinedButton(
                            onPressed: game.isGameOver
                                ? null
                                : () => VerbPanel.showVerbPopup(context, item),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.text,
                              backgroundColor: AppTheme.background,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              side: const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Column(
                              children: [
                                ObjectIcon(item, size: 26),
                                const SizedBox(height: 8),
                                Text(
                                  item,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (item == 'IRON')
                                  const Text(
                                    '4 units',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    ),
  );
}
