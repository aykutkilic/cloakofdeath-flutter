import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

/// Panel with clickable verb buttons
class VerbPanel extends StatelessWidget {
  const VerbPanel({super.key});

  static const List<String> verbs = [
    'LOOK',
    'GET',
    'DROP',
    'EXAMINE',
    'OPEN',
    'UNLOCK',
    'LIGHT',
    'EXTINGUISH',
    'READ',
    'USE',
    'PUSH',
    'PULL',
    'KICK',
    'CLIMB',
    'BURN',
    'CUT',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'VERBS',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedVerb != null)
                    TextButton(
                      onPressed: () => gameState.clearSelectedVerb(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'CLEAR',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          color: Colors.green,
                          fontSize: 8,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Selected verb display
              if (selectedVerb != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003300),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    '▶ $selectedVerb',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (selectedVerb != null) const SizedBox(height: 4),

              // Verb buttons
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: verbs.length,
                  itemBuilder: (context, index) {
                    final verb = verbs[index];
                    final isSelected = selectedVerb == verb;

                    return ElevatedButton(
                      onPressed: () => gameState.selectVerb(verb),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF00AA00)
                            : const Color(0xFF003300),
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(
                            color: isSelected ? Colors.greenAccent : Colors.green,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        verb,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
