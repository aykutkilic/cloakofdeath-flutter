import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../app_theme.dart';
import 'verb_panel.dart';
import 'object_icon.dart';

/// Objects flow naturally instead of overflowing a fixed-height side panel.
class ObjectPanel extends StatelessWidget {
  const ObjectPanel({super.key});

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, game, child) {
      final objects = game.getVisibleObjects();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('OBJECTS HERE', style: AppTheme.label),
            const SizedBox(height: 10),
            if (objects.isEmpty)
              Text(
                game.isTooDarkToSee
                    ? 'Too dark to make anything out.'
                    : 'Nothing in sight. Try looking around.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedColor),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: objects
                  .map(
                    (object) => OutlinedButton.icon(
                      onPressed: game.isGameOver
                          ? null
                          : () => VerbPanel.showVerbPopup(context, object),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.text,
                        minimumSize: const Size(48, 48),
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: ObjectIcon(object, size: 20),
                      label: Text(
                        object,
                        style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    },
  );
}
