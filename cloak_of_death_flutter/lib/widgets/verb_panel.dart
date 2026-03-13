import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
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
        final selectedObject = gameState.selectedObject;

        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACTIONS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Verb buttons
              if (selectedObject == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Select an object or\ninventory item first.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.text.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: verbs.length,
                  itemBuilder: (context, index) {
                    final verb = verbs[index];

                    return ElevatedButton(
                      onPressed: () {
                        gameState.executeObjectVerb(verb, selectedObject);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.highlight,
                        foregroundColor: AppTheme.text,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        side: BorderSide.none,
                        elevation: 0,
                      ),
                      child: Text(
                        verb,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.text,
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                            ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
