import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

/// Interactive inventory widget with clickable items
class InteractiveInventory extends StatelessWidget {
  const InteractiveInventory({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final inventory = gameState.inventory;
        final selectedVerb = gameState.selectedVerb;
        final inventoryCount = gameState.inventoryCount;
        final maxInventory = GameState.maxInventory;

        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.green, width: 2),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INVENTORY',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.green,
                      fontSize: 10,
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
                          ? const Color(0xFF330000)
                          : const Color(0xFF003300),
                      border: Border.all(
                        color: inventoryCount >= maxInventory
                            ? Colors.red
                            : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '$inventoryCount/$maxInventory',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: inventoryCount >= maxInventory
                            ? Colors.red
                            : Colors.green,
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
                    ? const Center(
                        child: Text(
                          'Empty',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            color: Color(0xFF005500),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: inventory.length,
                        itemBuilder: (context, index) {
                          final item = inventory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                if (selectedVerb != null) {
                                  gameState.executeVerbObject(
                                    selectedVerb,
                                    item,
                                  );
                                } else {
                                  gameState.addMessage(
                                    'Select a verb first, then click the item.',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004400),
                                foregroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  side: const BorderSide(
                                    color: Colors.green,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.inventory,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  if (selectedVerb != null)
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                ],
                              ),
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
