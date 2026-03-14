import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/game_state.dart';

/// Shows a 4x4 action popup menu for the selected object.
/// Call [showVerbPopup] to display it.
class VerbPanel {
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

  /// Shows a 4x4 action grid popup for the given [objectName].
  static void showVerbPopup(BuildContext context, String objectName) {
    final gameState = context.read<GameState>();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.highlight, width: 2),
          ),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: object name + close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        objectName,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        gameState.clearSelectedObject();
                      },
                      child: const Icon(
                        Icons.close,
                        color: AppTheme.text,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 4x4 verb grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: verbs.length,
                  itemBuilder: (context, index) {
                    final verb = verbs[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        gameState.executeObjectVerb(verb, objectName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.highlight,
                        foregroundColor: AppTheme.text,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        side: BorderSide.none,
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          verb,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
