import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../game/exploration_map.dart';

/// A house section keeps elevation visible while browsing the floor plan.
/// Selecting a level only changes the map view; travel remains a room action.
class MapFloorSelector extends StatelessWidget {
  final int selectedFloor, currentFloor;
  final Set<int> visitedFloors;
  final ValueChanged<int> onSelected;

  const MapFloorSelector({
    super.key,
    required this.selectedFloor,
    required this.currentFloor,
    required this.visitedFloors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 450 ? 104 : 140,
    child: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 22,
            width: double.infinity,
            child: CustomPaint(painter: _HouseRoof()),
          ),
          for (final floor in [2, 1, 0, -1])
            Semantics(
              selected: floor == selectedFloor,
              label: floor == currentFloor ? 'Your current floor' : null,
              child: Tooltip(
                message: !visitedFloors.contains(floor)
                    ? 'Not explored yet'
                    : floor == currentFloor
                    ? 'You are on this floor'
                    : 'View ${mapFloorNames[floor]}',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Material(
                    color: floor == selectedFloor
                        ? AppTheme.highlight
                        : AppTheme.background,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: floor == selectedFloor
                            ? AppTheme.accent
                            : AppTheme.border,
                      ),
                      borderRadius: BorderRadius.circular(floor == -1 ? 8 : 2),
                    ),
                    child: InkWell(
                      key: ValueKey('select-floor-$floor'),
                      onTap: visitedFloors.contains(floor)
                          ? () => onSelected(floor)
                          : null,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                floor == currentFloor
                                    ? Icons.my_location
                                    : floor == -1
                                    ? Icons.foundation
                                    : Icons.window_outlined,
                                size: 15,
                                color: floor == selectedFloor
                                    ? AppTheme.accent
                                    : AppTheme.mutedColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  mapFloorNames[floor]!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: floor == selectedFloor
                                        ? AppTheme.accent
                                        : visitedFloors.contains(floor)
                                        ? AppTheme.text
                                        : AppTheme.mutedColor,
                                    fontWeight: floor == selectedFloor
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _HouseRoof extends CustomPainter {
  const _HouseRoof();

  @override
  void paint(Canvas canvas, Size size) {
    final roof = Path()
      ..moveTo(0, size.height - 3)
      ..lineTo(size.width / 2, 2)
      ..lineTo(size.width, size.height - 3);
    canvas.drawPath(
      roof,
      Paint()
        ..color = AppTheme.mutedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HouseRoof oldDelegate) => false;
}
