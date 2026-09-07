import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'inventory_icon_painter.dart';

/// Shared item artwork; non-portable scenery uses familiar vector fallbacks.
class ObjectIcon extends StatelessWidget {
  final String object;
  final double size;
  const ObjectIcon(this.object, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (InventoryIconPainter.supportedObjects.contains(object)) {
      return ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: InventoryIconPainter(object),
        ),
      );
    }
    const assets = {'SAFE': 'safe'};
    final fallback = switch (object) {
      'DOOR' || 'GATE' || 'HATCH' => Icons.door_front_door_outlined,
      'CORRIDOR' || 'PASSAGEWAY' || 'ANNEXE' => Icons.meeting_room_outlined,
      'RAT' || 'DOG' => Icons.pets_outlined,
      'BOOK' || 'SHELVES' => Icons.menu_book_outlined,
      'SINK' => Icons.water_drop_outlined,
      'CLOCK' => Icons.schedule,
      'DESK' || 'TABLE' => Icons.table_restaurant_outlined,
      'FIREPLACE' || 'EMBERS' => Icons.local_fire_department_outlined,
      'WINE' => Icons.wine_bar_outlined,
      'CLOAK' => Icons.checkroom_outlined,
      _ => Icons.category_outlined,
    };
    final asset = assets[object];
    if (asset == null) {
      return Icon(fallback, size: size, color: AppTheme.accent);
    }
    return Image.asset(
      'assets/images/$asset.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      color: AppTheme.accent,
      errorBuilder: (_, error, stack) =>
          Icon(fallback, size: size, color: AppTheme.accent),
    );
  }
}
