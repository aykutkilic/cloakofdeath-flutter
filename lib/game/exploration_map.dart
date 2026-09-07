import 'dart:collection';
import 'dart:convert';

import '../models/game_data.dart';
import 'adventure_engine.dart';

/// Hand-laid floor coordinates encode geography, not discovery or travel rules.
/// Unequal corridor lengths keep the two northern branches of the hall distinct.
class MapPosition {
  final int x, y, floor;
  const MapPosition(this.x, this.y, this.floor);
}

const roomPositions = <int, MapPosition>{
  1: MapPosition(0, 0, 0),
  2: MapPosition(-1, 0, 0),
  3: MapPosition(-1, -2, 0),
  4: MapPosition(-1, -1, 0),
  5: MapPosition(0, -1, 0),
  6: MapPosition(0, -2, 0),
  7: MapPosition(1, -2, 0),
  8: MapPosition(1, 0, 0),
  9: MapPosition(0, 0, 1),
  10: MapPosition(-1, 0, 1),
  11: MapPosition(1, 0, 1),
  12: MapPosition(-2, -1, 1),
  13: MapPosition(-1, -1, 1),
  14: MapPosition(0, -1, 1),
  15: MapPosition(1, -1, 1),
  16: MapPosition(0, -2, 1),
  17: MapPosition(1, -2, 1),
  18: MapPosition(0, -2, 2),
  19: MapPosition(1, -2, 2),
  20: MapPosition(2, -3, 2),
  21: MapPosition(2, -2, 2),
  22: MapPosition(-1, -1, -1),
  23: MapPosition(0, -1, -1),
  24: MapPosition(1, -1, -1),
  25: MapPosition(1, 0, -1),
  26: MapPosition(2, -1, -1),
  27: MapPosition(3, -1, -1),
};

const mapFloorNames = {
  -1: 'Cellar & courtyard',
  0: 'Ground floor',
  1: 'First floor',
  2: 'Attic',
};

class ExploredLink {
  final int from, to;
  final String command;
  const ExploredLink(this.from, this.to, this.command);
  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'command': command};
}

/// Knowledge is saved separately from physical state. Legacy saves reveal only
/// their current room; nothing infers a visit from solved puzzles or item data.
class ExplorationMap {
  final Set<int> visited = {};
  final Set<int> revealed = {};
  final Set<String> knownObjects = {};
  final List<ExploredLink> links = [];

  void observe(AdventureEngine engine) {
    visited.add(engine.room);
    knownObjects.addAll(engine.inventory);
    if (!engine.isDark) {
      revealed.add(engine.room);
      knownObjects.addAll(engine.visible);
    }
  }

  void recordMove(int from, int to, String command) {
    if (from == to) return;
    if (!links.any((link) => link.from == from && link.to == to)) {
      links.add(ExploredLink(from, to, command));
    }
  }

  Map<String, dynamic> toJson() => {
    'visited': visited.toList()..sort(),
    'revealed': revealed.toList()..sort(),
    'knownObjects': knownObjects.toList()..sort(),
    'links': links.map((link) => link.toJson()).toList(),
  };

  ExplorationMap();
  factory ExplorationMap.fromJson(Map<String, dynamic> json) {
    final map = ExplorationMap();
    map.visited.addAll(
      List<int>.from(json['visited'] ?? []).where(roomPositions.containsKey),
    );
    map.revealed.addAll(
      List<int>.from(json['revealed'] ?? []).where(map.visited.contains),
    );
    map.knownObjects.addAll(
      List<String>.from(
        json['knownObjects'] ?? [],
      ).where(AdventureEngine.initialLocations.containsKey),
    );
    for (final value in json['links'] ?? []) {
      final link = Map<String, dynamic>.from(value);
      if (map.visited.contains(link['from']) &&
          map.visited.contains(link['to'])) {
        map.recordMove(
          link['from'] as int,
          link['to'] as int,
          link['command'] as String,
        );
      }
    }
    return map;
  }

  /// One search produces all reachable destinations. Every edge executes on a
  /// cloned engine, so locks, entry effects, fuel and cloak timing have one owner.
  Map<int, List<String>> routes(AdventureEngine source, GameData data) {
    if (!source.isPlaying || source.awaitingCombination) return {};
    final routes = <int, List<String>>{source.room: []};
    final queue = Queue<(AdventureEngine, List<String>)>()
      ..add((AdventureEngine.fromJson(source.toJson()), []));
    final seen = <String>{};
    while (queue.isNotEmpty) {
      final (engine, path) = queue.removeFirst();
      if (path.length >= visited.length) continue;
      final exits =
          data.getRoomById(engine.room)?.connections ?? <String, int>{};
      final commands = <String>{
        ...engine.exits(exits).keys,
        'GO CORRIDOR',
        'GO DOOR',
        'GO PASSAGEWAY',
        'GO ANNEXE',
        'GO HATCH',
        'GO GATE',
      };
      for (final command in commands) {
        final next = AdventureEngine.fromJson(engine.toJson());
        next.execute(command, exits);
        if (next.room == engine.room ||
            !visited.contains(next.room) ||
            next.outcome == 'dead') {
          continue;
        }
        final steps = [...path, command];
        routes.putIfAbsent(next.room, () => List.unmodifiable(steps));
        // Shorter paths with the same physical state dominate longer paths.
        final key = jsonEncode([
          next.room,
          next.flags,
          next.locations,
          next.cloakTurns,
        ]);
        if (next.isPlaying && seen.add(key)) queue.add((next, steps));
      }
    }
    return routes;
  }
}
