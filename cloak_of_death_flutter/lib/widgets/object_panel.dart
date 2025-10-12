import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

/// Panel displaying clickable objects in current room
class ObjectPanel extends StatelessWidget {
  const ObjectPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final objects = gameState.getVisibleObjects();
        final selectedVerb = gameState.selectedVerb;

        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.green, width: 2),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'OBJECTS HERE',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Object count
              Text(
                '${objects.length} item${objects.length != 1 ? 's' : ''} visible',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 4),

              // Objects list
              Expanded(
                child: objects.isEmpty
                    ? const Center(
                        child: Text(
                          'No objects here',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            color: Color(0xFF005500),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: objects.length,
                        itemBuilder: (context, index) {
                          final object = objects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                if (selectedVerb != null) {
                                  gameState.executeVerbObject(
                                      selectedVerb, object);
                                } else {
                                  gameState.addMessage(
                                      'Select a verb first, then click the object.');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003300),
                                foregroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  side: const BorderSide(
                                      color: Colors.green, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle,
                                      size: 6, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      object.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  if (selectedVerb != null)
                                    const Icon(Icons.arrow_forward,
                                        size: 12, color: Colors.green),
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
