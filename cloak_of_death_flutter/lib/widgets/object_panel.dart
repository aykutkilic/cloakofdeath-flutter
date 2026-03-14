import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../app_theme.dart';
import 'verb_panel.dart';

/// Panel displaying clickable objects in current room.
/// Tapping an object opens the 4x4 action popup.
class ObjectPanel extends StatelessWidget {
  const ObjectPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final objects = gameState.getVisibleObjects();

        return Container(
          decoration: const BoxDecoration(color: AppTheme.background),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'OBJECTS HERE',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Object count
              Text(
                '${objects.length} item${objects.length != 1 ? 's' : ''} visible',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.text.withValues(alpha: 0.7),
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 4),

              // Objects list
              if (objects.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No objects here',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.text.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: objects.length,
                  itemBuilder: (context, index) {
                    final object = objects[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          gameState.selectObject(object);
                          VerbPanel.showVerbPopup(context, object);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.panel,
                          foregroundColor: AppTheme.text,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          alignment: Alignment.centerLeft,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          side: BorderSide.none,
                          elevation: 0,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: AppTheme.text,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                object.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: AppTheme.text,
                                    ),
                              ),
                            ),
                          ],
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
