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
        final selectedVerb = gameState.selectedVerb;

        return Container(
          decoration: const BoxDecoration(color: AppTheme.background),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VERBS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedVerb != null)
                    TextButton(
                      onPressed: () => gameState.clearSelectedVerb(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        'CLEAR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.text,
                          fontSize: 10,
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
                  decoration: const BoxDecoration(color: AppTheme.highlight),
                  child: Text(
                    '▶ $selectedVerb',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.text,
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
                            ? AppTheme.text
                            : AppTheme.highlight,
                        foregroundColor: isSelected
                            ? AppTheme.background
                            : AppTheme.text,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        side: BorderSide.none,
                        elevation: 0,
                      ),
                      child: Text(
                        verb,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppTheme.background
                              : AppTheme.text,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
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
