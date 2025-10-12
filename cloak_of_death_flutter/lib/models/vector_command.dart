import 'dart:ui';

/// Represents a single vector drawing command
class VectorCommand {
  final String type; // line, move, moveTo, poly_start, poly_end, arc, curve, fill, fill_rect
  final List<Offset>? points; // For line commands
  final int? mode; // For move commands
  final List<int>? params; // For poly_end, arc, curve
  final int? x; // For fill seed point
  final int? y; // For fill seed point
  final int? pattern; // For fill command (4-column pattern byte)
  final int? color; // For fill_rect command
  final List<Offset>? vertices; // For fill_rect command

  VectorCommand({
    required this.type,
    this.points,
    this.mode,
    this.params,
    this.x,
    this.y,
    this.pattern,
    this.color,
    this.vertices,
  });

  factory VectorCommand.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    List<Offset>? points;
    if (json['points'] != null) {
      points = (json['points'] as List)
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList();
    } else if (json['point'] != null) {
      // moveTo command has a single point
      final p = json['point'];
      points = [Offset(
        (p['x'] as num).toDouble(),
        (p['y'] as num).toDouble(),
      )];
    }

    // Parse vertices for fill_rect command
    List<Offset>? vertices;
    if (json['vertices'] != null) {
      vertices = (json['vertices'] as List)
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList();
    }

    return VectorCommand(
      type: type,
      points: points,
      mode: json['mode'] as int?,
      params: json['params'] != null
          ? (json['params'] as List).map((e) => e as int).toList()
          : null,
      x: json['x'] as int?,
      y: json['y'] as int?,
      pattern: json['pattern'] as int?,
      color: json['color'] as int?,
      vertices: vertices,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type};
    if (points != null) {
      map['points'] = points!.map((p) => {'x': p.dx, 'y': p.dy}).toList();
    }
    if (mode != null) map['mode'] = mode;
    if (params != null) map['params'] = params;
    if (x != null) map['x'] = x;
    if (y != null) map['y'] = y;
    if (pattern != null) map['pattern'] = pattern;
    if (color != null) map['color'] = color;
    if (vertices != null) {
      map['vertices'] = vertices!.map((p) => {'x': p.dx, 'y': p.dy}).toList();
    }
    return map;
  }

  /// Decode pattern byte into 4 column color indices (2 bits each)
  /// Pattern byte format: 0bAABBCCDD where each 2-bit value is a palette index
  /// Returns [column0_index, column1_index, column2_index, column3_index]
  List<int> getPatternColumns() {
    if (pattern == null) return [0, 0, 0, 0];
    return [
      (pattern! >> 6) & 0x03, // bits 7-6: column 0 (leftmost)
      (pattern! >> 4) & 0x03, // bits 5-4: column 1
      (pattern! >> 2) & 0x03, // bits 3-2: column 2
      pattern! & 0x03,         // bits 1-0: column 3 (rightmost)
    ];
  }

  @override
  String toString() => 'VectorCommand($type, points: $points, mode: $mode, pattern: $pattern)';
}
