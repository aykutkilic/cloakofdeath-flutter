import 'dart:convert';

import 'adventure_engine.dart';
import 'exploration_map.dart';

/// A manual checkpoint is independent of the rolling autosave.
class SaveSlot {
  final int number;
  final DateTime? savedAt;
  final String? snapshot;
  final bool unreadable;

  const SaveSlot(
    this.number, {
    this.savedAt,
    this.snapshot,
    this.unreadable = false,
  });

  bool get canLoad => snapshot != null && !unreadable;
  bool get occupied => snapshot != null || unreadable;

  Map<String, dynamic> get data =>
      jsonDecode(snapshot!) as Map<String, dynamic>;
  int get roomId => data['currentRoomId'] as int;
  int get moves => data['moveCount'] as int;

  String encode() => jsonEncode({
    'version': 1,
    'savedAt': savedAt!.toUtc().toIso8601String(),
    'state': data,
  });

  factory SaveSlot.decode(int number, String? value) {
    if (value == null) return SaveSlot(number);
    try {
      final envelope = jsonDecode(value) as Map<String, dynamic>;
      if (envelope['version'] != 1) {
        throw const FormatException('Unknown save version');
      }
      final state = envelope['state'] as Map<String, dynamic>;
      if (state['schemaVersion'] != 2 ||
          state['currentRoomId'] is! int ||
          state['moveCount'] is! int ||
          state['objectLocations'] is! Map ||
          state['gameFlags'] is! Map ||
          state['exploration'] is! Map ||
          state['outputMessages'] is! List) {
        throw const FormatException('Incomplete checkpoint');
      }
      // Validate every component before offering Load. A damaged slot must
      // never partially replace the current journey.
      AdventureEngine.fromJson(state);
      ExplorationMap.fromJson(Map<String, dynamic>.from(state['exploration']));
      List<String>.from(state['outputMessages']);
      return SaveSlot(
        number,
        savedAt: DateTime.parse(envelope['savedAt'] as String),
        snapshot: jsonEncode(state),
      );
    } catch (_) {
      return SaveSlot(number, unreadable: true);
    }
  }
}
