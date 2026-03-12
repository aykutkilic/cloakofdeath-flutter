import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'atari_bytecode_parser.dart';
import 'atari_pixel_renderer.dart';

/// Controller for progressive Atari rendering animation.
///
/// Pre-generates a [PlotQueue] from the room bytecode, then plays it back
/// at a configurable rate by advancing a cursor through the queue.
class AtariRenderController extends ChangeNotifier {
  final AtariRoomBytecode roomData;

  PlotQueue? _plotQueue;
  Uint32List? _pixelBuffer;
  int _cursor = 0; // Current position in the plot queue
  bool _isAnimating = false;
  double _pixelsPerSecond = 10000.0;
  DateTime? _lastFrameTime;

  AtariRenderController({
    required this.roomData,
    double pixelsPerSecond = 10000.0,
  }) : _pixelsPerSecond = pixelsPerSecond;

  bool get isAnimating => _isAnimating;
  double get pixelsPerSecond => _pixelsPerSecond;
  int get cursor => _cursor;
  int get totalPlots => _plotQueue?.length ?? 0;
  bool get isComplete => _plotQueue != null && _cursor >= _plotQueue!.length;

  /// Which bytecode command index the cursor is currently within.
  int get currentCommandIndex {
    final q = _plotQueue;
    if (q == null) return 0;
    // Binary search through command boundaries
    for (int i = q.commandBoundaries.length - 2; i >= 0; i--) {
      if (_cursor >= q.commandBoundaries[i]) return i;
    }
    return 0;
  }

  void setPixelsPerSecond(double pps) {
    _pixelsPerSecond = pps.clamp(100.0, 100000.0);
    notifyListeners();
  }

  void startAnimation() {
    if (_isAnimating) return;

    // Generate queue on first start (or after reset)
    _plotQueue ??= AtariPixelRenderer.generatePlotQueue(roomData);

    if (_pixelBuffer == null) {
      _pixelBuffer = _plotQueue!.createBuffer();
      _cursor = 0;
    }

    _isAnimating = true;
    _lastFrameTime = DateTime.now();
    notifyListeners();
    _animate();
  }

  void stopAnimation() {
    _isAnimating = false;
    notifyListeners();
  }

  void reset() {
    _isAnimating = false;
    _cursor = 0;
    _pixelBuffer = null;
    _lastFrameTime = null;
    notifyListeners();
  }

  /// Render everything instantly.
  void renderAll() {
    _plotQueue ??= AtariPixelRenderer.generatePlotQueue(roomData);
    _pixelBuffer = _plotQueue!.createBuffer();
    _plotQueue!.applyRange(_pixelBuffer!, 0, _plotQueue!.length);
    _cursor = _plotQueue!.length;
    _isAnimating = false;
    notifyListeners();
  }

  /// Advance one bytecode command.
  void stepToNextCommand() {
    _plotQueue ??= AtariPixelRenderer.generatePlotQueue(roomData);
    if (_pixelBuffer == null) {
      _pixelBuffer = _plotQueue!.createBuffer();
      _cursor = 0;
    }

    _isAnimating = false;
    final cmdIdx = currentCommandIndex;
    if (cmdIdx + 1 >= _plotQueue!.commandBoundaries.length - 1) return;

    final end = _plotQueue!.commandBoundaries[cmdIdx + 1];
    _plotQueue!.applyRange(_pixelBuffer!, _cursor, end);
    _cursor = end;
    notifyListeners();
  }

  /// Get the current command being rendered.
  AtariBytecodeCommand? getCurrentCommand() {
    final idx = currentCommandIndex;
    if (idx >= 0 && idx < roomData.commands.length) {
      return roomData.commands[idx];
    }
    return null;
  }

  void _animate() {
    if (!_isAnimating) return;
    final q = _plotQueue!;

    final now = DateTime.now();
    final elapsedMs = _lastFrameTime != null
        ? now.difference(_lastFrameTime!).inMilliseconds
        : 16;
    _lastFrameTime = now;

    int budget = (_pixelsPerSecond * elapsedMs / 1000.0).round().clamp(
      1,
      100000,
    );

    final end = (_cursor + budget).clamp(0, q.length);
    q.applyRange(_pixelBuffer!, _cursor, end);
    _cursor = end;

    notifyListeners();

    if (_cursor >= q.length) {
      _isAnimating = false;
    } else {
      Future.delayed(const Duration(milliseconds: 16), _animate);
    }
  }

  AtariPixelRenderer createPainter() {
    return AtariPixelRenderer(pixelBuffer: _pixelBuffer);
  }

  @override
  void dispose() {
    _isAnimating = false;
    super.dispose();
  }
}

/// Widget that displays animated Atari pixel rendering with debug info.
class AtariAnimatedRoomView extends StatefulWidget {
  final AtariRoomBytecode roomData;
  final bool autoStart;
  final double? pixelsPerSecond;

  const AtariAnimatedRoomView({
    super.key,
    required this.roomData,
    this.autoStart = true,
    this.pixelsPerSecond,
  });

  @override
  State<AtariAnimatedRoomView> createState() => _AtariAnimatedRoomViewState();
}

class _AtariAnimatedRoomViewState extends State<AtariAnimatedRoomView> {
  late AtariRenderController _controller;
  final bool _showCommands = false;
  Offset? _hoverAtariCoord;
  Offset? _hoverLocalPos;

  @override
  void initState() {
    super.initState();
    _controller = AtariRenderController(
      roomData: widget.roomData,
      pixelsPerSecond: widget.pixelsPerSecond ?? 10000.0,
    );

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.startAnimation();
      });
    }
  }

  @override
  void didUpdateWidget(AtariAnimatedRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.roomData != widget.roomData) {
      _controller.dispose();
      _controller = AtariRenderController(
        roomData: widget.roomData,
        pixelsPerSecond: widget.pixelsPerSecond ?? 10000.0,
      );

      if (widget.autoStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.startAnimation();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final pxW =
                          constraints.maxWidth / AtariPixelRenderer.canvasWidth;
                      final pxH =
                          constraints.maxHeight /
                          AtariPixelRenderer.canvasHeight;
                      return MouseRegion(
                        cursor: SystemMouseCursors.precise,
                        onHover: (event) {
                          final pixelX =
                              (event.localPosition.dx /
                                      constraints.maxWidth *
                                      AtariPixelRenderer.canvasWidth)
                                  .floorToDouble();
                          final pixelY =
                              (event.localPosition.dy /
                                      constraints.maxHeight *
                                      AtariPixelRenderer.canvasHeight)
                                  .floorToDouble();
                          setState(() {
                            _hoverAtariCoord = Offset(
                              pixelX.clamp(
                                0,
                                AtariPixelRenderer.canvasWidth - 1,
                              ),
                              pixelY.clamp(
                                0,
                                AtariPixelRenderer.canvasHeight - 1,
                              ),
                            );
                            _hoverLocalPos = event.localPosition;
                          });
                        },
                        onExit: (_) => setState(() {
                          _hoverAtariCoord = null;
                          _hoverLocalPos = null;
                        }),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox.expand(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                ),
                                child: CustomPaint(
                                  painter: _controller.createPainter(),
                                ),
                              ),
                            ),
                            if (_hoverAtariCoord != null) ...[
                              Positioned(
                                left: _hoverAtariCoord!.dx * pxW,
                                top: _hoverAtariCoord!.dy * pxH,
                                child: IgnorePointer(
                                  child: Container(
                                    width: pxW,
                                    height: pxH,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: (_hoverLocalPos!.dx + 12).clamp(
                                  0,
                                  constraints.maxWidth - 60,
                                ),
                                top: (_hoverLocalPos!.dy - 20).clamp(
                                  0,
                                  constraints.maxHeight - 16,
                                ),
                                child: IgnorePointer(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.8,
                                      ),
                                      border: Border.all(
                                        color: Colors.green.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '${_hoverAtariCoord!.dx.toInt()}, ${_hoverAtariCoord!.dy.toInt()}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Command ${_controller.currentCommandIndex + 1} / ${widget.roomData.commands.length}  |  Plot ${_controller.cursor} / ${_controller.totalPlots}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),
                    _buildCurrentCommandInfo(),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildSmallButton(
                          _controller.isAnimating ? 'Pause' : 'Play',
                          _controller.isAnimating
                              ? _controller.stopAnimation
                              : _controller.startAnimation,
                        ),
                        _buildSmallButton('Step', () {
                          _controller.stopAnimation();
                          _controller.stepToNextCommand();
                        }),
                        _buildSmallButton('Reset', _controller.reset),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Text(
                          'Speed:',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _controller.pixelsPerSecond,
                            min: 10,
                            max: 10000,
                            divisions: 99,
                            activeColor: Colors.green,
                            inactiveColor: Colors.green.withValues(alpha: 0.3),
                            onChanged: (value) {
                              _controller.setPixelsPerSecond(value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${_controller.pixelsPerSecond.toInt()} px/s',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),

                    if (_showCommands) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Colors.green),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.roomData.commands
                                .asMap()
                                .entries
                                .map((entry) {
                                  final idx = entry.key;
                                  final cmd = entry.value;
                                  final isCurrentCommand =
                                      idx == _controller.currentCommandIndex;
                                  return Container(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    color: isCurrentCommand
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                    child: Text(
                                      '${idx + 1}. ${_describeCommand(cmd)}',
                                      style: TextStyle(
                                        color: isCurrentCommand
                                            ? Colors.white
                                            : Colors.green,
                                        fontSize: 9,
                                        fontWeight: isCurrentCommand
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentCommandInfo() {
    final cmd = _controller.getCurrentCommand();
    if (cmd == null) {
      return const Text(
        'No command',
        style: TextStyle(
          color: Colors.green,
          fontSize: 9,
          fontFamily: 'monospace',
        ),
      );
    }

    final hexCode = cmd.hexBytes.isNotEmpty ? cmd.hexBytes : 'N/A';
    final description = _describeCommand(cmd);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEX: $hexCode',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 24,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          backgroundColor: Colors.green.shade900,
          foregroundColor: Colors.green,
          textStyle: const TextStyle(fontSize: 10),
        ),
        child: Text(label),
      ),
    );
  }

  String _describeCommand(AtariBytecodeCommand cmd) {
    switch (cmd.type) {
      case BytecodeCommandType.polyline:
        return 'POLY color=${cmd.colorIndex} pts=${cmd.points.length}';
      case BytecodeCommandType.closedPolyline:
        return 'CLOSED_POLY color=${cmd.colorIndex} pts=${cmd.points.length}';
      case BytecodeCommandType.floodFill:
        return 'FILL color=${cmd.colorIndex}';
      case BytecodeCommandType.floodFillAt:
        final pat = cmd.fillPattern ?? 0;
        if (pat <= 3) {
          return 'FILL_AT solid=$pat @${cmd.fillSeed}';
        } else {
          final cols = [
            (pat >> 6) & 0x03,
            (pat >> 4) & 0x03,
            (pat >> 2) & 0x03,
            pat & 0x03,
          ];
          return 'FILL_AT pattern=$cols @${cmd.fillSeed}';
        }
    }
  }
}
