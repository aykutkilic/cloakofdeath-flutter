import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Existing pixel icons stay crisp; scenery has meaningful vector fallbacks.
class ObjectIcon extends StatelessWidget {
  final String object;
  final double size;
  const ObjectIcon(this.object, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    const assets = {
      'BIBLE': 'bible',
      'CANDLE': 'candle',
      'LIT CANDLE': 'lit_candle',
      'MATCHES': 'matches',
      'KEY': 'key',
      'GATE KEY': 'gate_key',
      'HAMMER': 'hammer',
      'SAW': 'saw',
      'BAR': 'bar',
      'BAR PIECES': 'bar',
      'CRUCIFIX': 'crucifix',
      'IRON': 'iron',
      'HOLY WATER': 'holy_water',
      'GOBLET OF WATER': 'water',
      'WATER': 'water',
      'GOBLET': 'goblet',
      'BREAD': 'bread',
      'LETTER': 'letter',
      'PAINTING': 'painting',
      'RAG': 'rag',
      'WIRE': 'wire',
      'COAL': 'coal',
      'SAFE': 'safe',
      'CHAIR': 'chair',
      'CHEST': 'chest',
      'KNIFE': 'knife',
    };
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
