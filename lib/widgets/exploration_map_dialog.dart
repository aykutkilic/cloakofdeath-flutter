import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/exploration_map.dart';
import '../game/game_state.dart';

// Compact labels are presentation-only; hover details retain the full names.
const _shortRoomNames = {
  1: 'Hall',
  2: 'Dining',
  3: 'Kitchen',
  4: 'Pantry',
  5: 'Corridor',
  6: 'Conserv.',
  7: 'Study',
  8: 'Sitting',
  9: 'Landing',
  10: 'Guest',
  11: 'Dressing',
  12: 'Annexe',
  13: 'Master',
  14: 'Icy hall',
  15: 'Haunted',
  16: 'Library',
  17: 'Passage',
  18: 'Sewing',
  19: 'Attic',
  20: 'Store',
  21: 'Pool',
  22: 'Wine',
  23: 'Cellar',
  24: 'Garage',
  25: 'Workshop',
  26: 'Tunnel',
  27: 'Exit',
};

class ExplorationMapButton extends StatelessWidget {
  const ExplorationMapButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Exploration map',
    icon: const Icon(Icons.map_outlined),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => const ExplorationMapDialog(),
    ),
  );
}

class ExplorationMapDialog extends StatefulWidget {
  const ExplorationMapDialog({super.key});
  @override
  State<ExplorationMapDialog> createState() => _ExplorationMapDialogState();
}

class _ExplorationMapDialogState extends State<ExplorationMapDialog> {
  int? _floor;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final currentFloor = roomPositions[game.currentRoomId]!.floor;
    final floor = _floor ?? currentFloor;
    final floors =
        game.visitedRooms.map((id) => roomPositions[id]!.floor).toSet().toList()
          ..sort();
    final routes = game.mapRoutes;
    final rooms =
        game.visitedRooms
            .where((id) => roomPositions[id]!.floor == floor)
            .toList()
          ..sort();
    String details(int id) {
      final contents = game.mapRoomContents(id);
      final route = routes[id];
      return '${game.mapRoomName(id)}\n'
          '${!game.isRoomRevealed(id)
              ? 'Too dark when visited; contents unknown.'
              : contents.isEmpty
              ? 'No known objects here.'
              : contents.join(', ')}\n'
          '${id == game.currentRoomId
              ? 'You are here.'
              : route == null
              ? 'No traversable route with your current equipment and puzzle state.'
              : 'Travel here · ${route.length} ${route.length == 1 ? 'turn' : 'turns'}'}';
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 640,
        height: math.min(480, MediaQuery.sizeOf(context).height * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.map_outlined, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Exploration map',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close map',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(
                height: 48,
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: floor,
                  items: [
                    for (final value in floors)
                      DropdownMenuItem(
                        value: value,
                        child: Text(mapFloorNames[value]!),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _floor = value;
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _FloorCanvas(
                  key: ValueKey('map-floor-$floor-${rooms.join(',')}'),
                  rooms: rooms,
                  game: game,
                  routes: routes,
                  details: details,
                  onTravel: (id) {
                    if (!game.travelToRoom(id)) return;
                    Navigator.pop(context);
                  },
                  onFloor: (value) => setState(() {
                    _floor = value;
                  }),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap for details; double-tap or hold to travel. Mouse: hover for details, click to travel.',
                style: TextStyle(fontSize: 11, color: AppTheme.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloorCanvas extends StatefulWidget {
  final List<int> rooms;
  final GameState game;
  final Map<int, List<String>> routes;
  final String Function(int) details;
  final ValueChanged<int> onTravel, onFloor;
  const _FloorCanvas({
    super.key,
    required this.rooms,
    required this.game,
    required this.routes,
    required this.details,
    required this.onTravel,
    required this.onFloor,
  });
  @override
  State<_FloorCanvas> createState() => _FloorCanvasState();
}

class _FloorCanvasState extends State<_FloorCanvas> {
  final _transform = TransformationController();
  bool _fitted = false;
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Collapse unused rows/columns while preserving compass order. The fixed
    // 48px nodes remain easy to tap; detail text never expands the layout.
    final columns =
        widget.rooms.map((id) => roomPositions[id]!.x).toSet().toList()..sort();
    final rows = widget.rooms.map((id) => roomPositions[id]!.y).toSet().toList()
      ..sort();
    final size = Size(columns.length * 88 + 72, rows.length * 96 + 64);
    final rects = {
      for (final id in widget.rooms)
        id: Rect.fromLTWH(
          columns.indexOf(roomPositions[id]!.x) * 88 + 40,
          rows.indexOf(roomPositions[id]!.y) * 96 + 40,
          48,
          48,
        ),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        void fit({bool overview = false}) {
          final fitted = math.min(
            1.0,
            math.min(
              constraints.maxWidth / size.width,
              constraints.maxHeight / size.height,
            ),
          );
          final scale = overview ? fitted : math.max(0.7, fitted);
          final center = overview || scale == fitted
              ? size.center(Offset.zero)
              : rects[widget.game.currentRoomId]?.center ??
                    size.center(Offset.zero);
          _transform.value = Matrix4.identity()
            ..translateByDouble(
              constraints.maxWidth / 2 - center.dx * scale,
              constraints.maxHeight / 2 - center.dy * scale,
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
        }

        void zoom(double factor) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          final scene = _transform.toScene(center);
          final scale = (_transform.value.getMaxScaleOnAxis() * factor).clamp(
            0.1,
            2.5,
          );
          _transform.value = Matrix4.identity()
            ..translateByDouble(
              center.dx - scene.dx * scale,
              center.dy - scene.dy * scale,
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
        }

        if (!_fitted) {
          _fitted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) fit();
          });
        }
        return ClipRect(
          child: Stack(
            children: [
              ColoredBox(
                color: AppTheme.background,
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  minScale: 0.1,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(400),
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MapLines(
                              rects,
                              widget.game.exploredLinks,
                            ),
                          ),
                        ),
                        for (final id in widget.rooms)
                          Positioned.fromRect(
                            rect: rects[id]!,
                            child: _RoomGestureTarget(
                              message: widget.details(id),
                              onTravel:
                                  widget.routes.containsKey(id) &&
                                      id != widget.game.currentRoomId
                                  ? () => widget.onTravel(id)
                                  : null,
                              child: Material(
                                color: id == widget.game.currentRoomId
                                    ? AppTheme.highlight
                                    : AppTheme.panel,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: id == widget.game.currentRoomId
                                        ? AppTheme.accent
                                        : AppTheme.border,
                                    width: 2,
                                  ),
                                ),
                                child: SizedBox(
                                  key: ValueKey('map-room-$id'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        widget.game.isRoomRevealed(id)
                                            ? _shortRoomNames[id]!
                                            : 'Unlit',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: id == widget.game.currentRoomId
                                              ? AppTheme.accent
                                              : widget.routes.containsKey(id)
                                              ? AppTheme.text
                                              : AppTheme.mutedColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        for (final id in widget.rooms)
                          if (_stairs(id).isNotEmpty)
                            Positioned(
                              left: rects[id]!.left,
                              top: rects[id]!.bottom + 4,
                              width: rects[id]!.width,
                              child: Wrap(
                                spacing: 4,
                                children: [
                                  for (final target in _stairs(id))
                                    Tooltip(
                                      message: widget.game.mapRoomName(target),
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(48, 32),
                                        ),
                                        onPressed: () => widget.onFloor(
                                          roomPositions[target]!.floor,
                                        ),
                                        child: Text(
                                          roomPositions[target]!.floor >
                                                  roomPositions[id]!.floor
                                              ? 'U'
                                              : 'D',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 8,
                top: 8,
                child: Text(
                  '    N\nW  +  E\n    S',
                  style: TextStyle(fontSize: 11, color: AppTheme.mutedColor),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Column(
                  children: [
                    IconButton(
                      tooltip: 'Fit floor',
                      onPressed: () => fit(overview: true),
                      icon: const Icon(Icons.fit_screen),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () => zoom(1.35),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () => zoom(1 / 1.35),
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Set<int> _stairs(int id) => {
    for (final link in widget.game.exploredLinks)
      if ((link.from == id || link.to == id) &&
          roomPositions[link.from]!.floor != roomPositions[link.to]!.floor)
        link.from == id ? link.to : link.from,
  };
}

/// Use actual pointer input so touch browsers/tablets behave like phones while
/// a mouse still supports desktop inspection and single-click travel.
class _RoomGestureTarget extends StatefulWidget {
  final String message;
  final VoidCallback? onTravel;
  final Widget child;
  const _RoomGestureTarget({
    required this.message,
    required this.onTravel,
    required this.child,
  });

  @override
  State<_RoomGestureTarget> createState() => _RoomGestureTargetState();
}

class _RoomGestureTargetState extends State<_RoomGestureTarget> {
  final _tooltip = GlobalKey<TooltipState>();
  PointerDeviceKind _pointer = PointerDeviceKind.touch;

  void _inspect() => _tooltip.currentState?.ensureTooltipVisible();

  void _travel() {
    if (widget.onTravel == null) {
      _inspect();
      return;
    }
    Tooltip.dismissAllToolTips();
    widget.onTravel!();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    key: _tooltip,
    message: widget.message,
    triggerMode: TooltipTriggerMode.manual,
    waitDuration: const Duration(milliseconds: 150),
    showDuration: const Duration(seconds: 6),
    constraints: const BoxConstraints(maxWidth: 280),
    textAlign: TextAlign.left,
    child: Listener(
      onPointerDown: (event) => _pointer = event.kind,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            _pointer == PointerDeviceKind.mouse ? _travel() : _inspect(),
        onDoubleTap: _travel,
        onLongPress: () =>
            _pointer == PointerDeviceKind.mouse ? _inspect() : _travel(),
        child: widget.child,
      ),
    ),
  );
}

class _MapLines extends CustomPainter {
  final Map<int, Rect> rects;
  final List<ExploredLink> links;
  _MapLines(this.rects, this.links);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.mutedColor
      ..strokeWidth = 2;
    for (final link in links) {
      final from = rects[link.from], to = rects[link.to];
      if (from == null || to == null) continue;
      final delta = to.center - from.center;
      final horizontal = delta.dx.abs() > delta.dy.abs();
      var start = horizontal
          ? Offset(delta.dx > 0 ? from.right : from.left, from.center.dy)
          : Offset(from.center.dx, delta.dy > 0 ? from.bottom : from.top);
      var end = horizontal
          ? Offset(delta.dx > 0 ? to.left : to.right, to.center.dy)
          : Offset(to.center.dx, delta.dy > 0 ? to.top : to.bottom);
      final blocked = rects.entries.any(
        (entry) =>
            entry.key != link.from &&
            entry.key != link.to &&
            Rect.fromPoints(start, end).inflate(2).overlaps(entry.value),
      );
      var approach = start;
      if (blocked) {
        // For example, hall -> conservatory must pass beside the corridor
        // card, not through it; the corridor is a separate northern branch.
        start = horizontal ? from.topCenter : from.centerRight;
        end = horizontal ? to.topCenter : to.centerRight;
        final bend1 = horizontal
            ? Offset(start.dx, from.top - 24)
            : Offset(from.right + 24, start.dy);
        final bend2 = horizontal
            ? Offset(end.dx, from.top - 24)
            : Offset(from.right + 24, end.dy);
        canvas.drawLine(start, bend1, paint);
        canvas.drawLine(bend1, bend2, paint);
        canvas.drawLine(bend2, end, paint);
        approach = bend2;
      } else {
        canvas.drawLine(start, end, paint);
      }
      final unit = (end - approach) / (end - approach).distance;
      final perpendicular = Offset(-unit.dy, unit.dx);
      canvas.drawLine(end, end - unit * 9 + perpendicular * 4, paint);
      canvas.drawLine(end, end - unit * 9 - perpendicular * 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapLines oldDelegate) => true;
}
