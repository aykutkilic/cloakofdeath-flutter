import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../app_theme.dart';

/// Panel displaying clickable objects in current room
class ObjectPanel extends StatelessWidget {
  const ObjectPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final objects = gameState.getVisibleObjects();
        final selectedObject = gameState.selectedObject;

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
                    'OBJECTS HERE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedObject != null && objects.contains(selectedObject))
                    TextButton(
                      onPressed: () => gameState.clearSelectedObject(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
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
              Expanded(
                child: objects.isEmpty
                    ? Center(
                        child: Text(
                          'No objects here',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.text.withValues(alpha: 0.5),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: objects.length,
                        itemBuilder: (context, index) {
                          final object = objects[index];
                          final isSelected = selectedObject == object;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ElevatedButton(
                              onPressed: () => gameState.selectObject(object),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? AppTheme.text : AppTheme.panel,
                                foregroundColor: isSelected ? AppTheme.background : AppTheme.text,
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
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: isSelected ? AppTheme.background : AppTheme.text,
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
                                            color: isSelected ? AppTheme.background : AppTheme.text,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                    ),
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
