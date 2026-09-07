import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/game_state.dart';
import 'object_icon.dart';

class VerbPanel {
  static Future<void> showVerbPopup(
    BuildContext context,
    String objectName,
  ) async {
    final game = context.read<GameState>();
    if (game.isGameOver) return;
    game.selectObject(objectName);
    final actions = game.getAvailableActionsForObject(objectName);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            ObjectIcon(objectName, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(objectName, style: const TextStyle(fontSize: 18)),
            ),
            IconButton(
              tooltip: 'Close actions',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map(
                    (verb) => ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        game.executeObjectVerb(verb, objectName);
                      },
                      child: Text(
                        verb,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
    game.clearSelectedObject();
  }
}
