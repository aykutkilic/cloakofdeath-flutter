import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../app_theme.dart';

/// Interactive inventory widget with clickable items
class InteractiveInventory extends StatelessWidget {
  const InteractiveInventory({super.key});

  String _getIconFor(String item) {
    switch (item.toUpperCase()) {
      case 'BIBLE':
        return 'assets/images/bible.png';
      case 'CANDLE':
        return 'assets/images/candle.png';
      case 'LIT CANDLE':
        return 'assets/images/lit_candle.png';
      case 'MATCHES':
        return 'assets/images/matches.png';
      case 'KEY':
        return 'assets/images/key.png';
      case 'GATE KEY':
        return 'assets/images/gate_key.png';
      case 'HAMMER':
        return 'assets/images/hammer.png';
      case 'SAW':
        return 'assets/images/saw.png';
      case 'BAR':
        return 'assets/images/bar.png';
      case 'CRUCIFIX':
        return 'assets/images/crucifix.png';
      case 'IRON':
        return 'assets/images/iron.png';
      case 'HOLY WATER':
        return 'assets/images/holy_water.png';
      case 'WATER':
        return 'assets/images/water.png';
      case 'GOBLET':
        return 'assets/images/goblet.png';
      case 'BREAD':
        return 'assets/images/bread.png';
      case 'LETTER':
        return 'assets/images/letter.png';
      case 'PAINTING':
        return 'assets/images/painting.png';
      case 'RAG':
        return 'assets/images/rag.png';
      case 'WIRE':
        return 'assets/images/wire.png';
      case 'COAL':
        return 'assets/images/coal.png';
      case 'SAFE':
        return 'assets/images/safe.png';
      case 'CHAIR':
        return 'assets/images/chair.png';
      case 'CHEST':
        return 'assets/images/chest.png';
      case 'KNIFE':
        return 'assets/images/knife.png';
      default:
        return 'assets/images/chest.png'; // default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final inventory = gameState.inventory;
        final selectedVerb = gameState.selectedVerb;
        final inventoryCount = gameState.inventoryCount;
        final maxInventory = GameState.maxInventory;

        return Container(
          decoration: BoxDecoration(color: AppTheme.background),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INVENTORY',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: inventoryCount >= maxInventory
                          ? AppTheme.warningColor.withValues(alpha: 0.5)
                          : AppTheme.highlight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '$inventoryCount/$maxInventory',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.text,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Inventory items
              Expanded(
                child: inventory.isEmpty
                    ? Center(
                        child: Text(
                          'Empty',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.text.withValues(alpha: 0.5),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.0,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: inventory.length,
                        itemBuilder: (context, index) {
                          final item = inventory[index];
                          return ElevatedButton(
                            onPressed: () {
                              if (selectedVerb != null) {
                                gameState.executeVerbObject(selectedVerb, item);
                              } else {
                                gameState.addMessage(
                                  'Select a verb first, then click the item.',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.panel,
                              foregroundColor: AppTheme.text,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              alignment: Alignment.center,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              side: BorderSide.none,
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  _getIconFor(item),
                                  width: 16,
                                  height: 16,
                                  color: AppTheme.text,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.inventory,
                                        size: 16,
                                        color: AppTheme.text,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.toUpperCase(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 9,
                                          color: AppTheme.text,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
