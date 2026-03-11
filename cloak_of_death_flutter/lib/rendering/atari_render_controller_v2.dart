import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'atari_bytecode_parser.dart';
import 'atari_pixel_renderer_fixed.dart';

/// Controller for progressive Atari rendering animation (V2 - Fixed)
class AtariRenderControllerV2 extends ChangeNotifier {
  final AtariRoomBytecode roomData;

  bool _isAnimating = false;
  int _currentCommandIndex = 0;
  int _currentPixelCount = 0;
  ui.Image? _cachedImage;
  Uint32List? _pixelBuffer;
  double _pixelsPerSecond = 10000.0; // Default: 10K pixels per second
  DateTime? _lastFrameTime;

  AtariRenderControllerV2({
    required this.roomData,
    double pixelsPerSecond = 10000.0,
  }) : _pixelsPerSecond = pixelsPerSecond;

  bool get isAnimating => _isAnimating;
  int get currentCommandIndex => _currentCommandIndex;
  int get currentPixelCount => _currentPixelCount;
  double get pixelsPerSecond => _pixelsPerSecond;
  ui.Image? get cachedImage => _cachedImage;

  void setPixelsPerSecond(double pps) {
    _pixelsPerSecond = pps.clamp(100.0, 10000.0);
    notifyListeners();
  }

  void startAnimation() {
    if (_isAnimating) return;
    _isAnimating = true;
    _currentCommandIndex = 0;
    _currentPixelCount = 0;
    _lastFrameTime = DateTime.now();
    notifyListeners();
    _animate();
  }

  void stopAnimation() {
    _isAnimating = false;
    notifyListeners();
  }

  void reset() {
    _currentCommandIndex = 0;
    _currentPixelCount = 0;
    _isAnimating = false;
    _cachedImage = null;
    _pixelBuffer = null;
    _lastFrameTime = null;
    notifyListeners();
  }

  void renderAll() async {
    _isAnimating = false;

    // Render full image
    final result = await AtariPixelRendererFixed.renderToImage(
      roomData,
      maxCommandIndex: null,
    );
    _cachedImage = result.image;
    _currentCommandIndex = result.lastCommandIndex;

    notifyListeners();
  }

  /// Step to the next command (one command at a time)
  void stepToNextCommand() {
    if (_currentCommandIndex >= roomData.commands.length - 1) return;

    _isAnimating = false;
    _currentCommandIndex++;

    // Render up to the next command
    final result = AtariPixelRendererFixed.renderToPixelBuffer(
      roomData,
      maxCommandIndex: _currentCommandIndex,
    );
    _pixelBuffer = result.pixelBuffer;

    notifyListeners();
  }

  /// Get the current command being rendered
  AtariBytecodeCommand? getCurrentCommand() {
    if (_currentCommandIndex >= 0 && _currentCommandIndex < roomData.commands.length) {
      return roomData.commands[_currentCommandIndex];
    }
    return null;
  }

  void _animate() {
    if (!_isAnimating) return;

    // Calculate pixels to render this frame based on elapsed time
    final now = DateTime.now();
    final elapsedMs = _lastFrameTime != null
        ? now.difference(_lastFrameTime!).inMilliseconds
        : 16;
    _lastFrameTime = now;

    // Calculate base pixels per frame (assuming ~60fps = 16ms per frame)
    final pixelsThisFrame = (_pixelsPerSecond * elapsedMs / 1000.0).round().clamp(1, 10000);

    // Apply speed multiplier for flood fill commands
    int adjustedPixelLimit = _currentPixelCount + pixelsThisFrame;

    // Check if current or next command is a flood fill, apply 2x speed
    if (_currentCommandIndex < roomData.commands.length) {
      final currentCmd = roomData.commands[_currentCommandIndex];
      if (currentCmd.type == BytecodeCommandType.floodFill ||
          currentCmd.type == BytecodeCommandType.floodFillAt) {
        // 2x speed for flood fills
        adjustedPixelLimit = _currentPixelCount + (pixelsThisFrame * 2);
      }
    }

    // Render with pixel limit
    final result = AtariPixelRendererFixed.renderToPixelBuffer(
      roomData,
      maxPixelCount: adjustedPixelLimit,
    );
    _pixelBuffer = result.pixelBuffer;
    _currentCommandIndex = result.lastCommandIndex;

    // Update pixel count based on what was actually rendered
    _currentPixelCount = adjustedPixelLimit;

    notifyListeners();

    // Check if we've rendered all commands AND the last command has finished drawing
    if (_currentCommandIndex >= roomData.commands.length - 1 && result.isComplete) {
      _isAnimating = false;
    } else {
      // Schedule next frame (target 60fps)
      Future.delayed(const Duration(milliseconds: 16), _animate);
    }
  }

  AtariPixelRendererFixed createPainter() {
    return AtariPixelRendererFixed(
      roomData: roomData,
      cachedImage: _cachedImage,
      pixelBuffer: _pixelBuffer,
    );
  }

  @override
  void dispose() {
    _isAnimating = false;
    _cachedImage?.dispose();
    super.dispose();
  }
}

/// Widget that displays animated Atari pixel rendering with debug info
class AtariAnimatedRoomViewV2 extends StatefulWidget {
  final AtariRoomBytecode roomData;
  final bool autoStart;
  final double? pixelsPerSecond;

  const AtariAnimatedRoomViewV2({
    super.key,
    required this.roomData,
    this.autoStart = true,
    this.pixelsPerSecond,
  });

  @override
  State<AtariAnimatedRoomViewV2> createState() =>
      _AtariAnimatedRoomViewV2State();
}

class _AtariAnimatedRoomViewV2State extends State<AtariAnimatedRoomViewV2> {
  late AtariRenderControllerV2 _controller;
  bool _showCommands = false;

  @override
  void initState() {
    super.initState();
    _controller = AtariRenderControllerV2(
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
  void didUpdateWidget(AtariAnimatedRoomViewV2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If room data changed, recreate the controller
    if (oldWidget.roomData != widget.roomData) {
      _controller.dispose();
      _controller = AtariRenderControllerV2(
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
            // Render area - 320x160 aspect ratio (2.0), matching the emulator width
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 5 / 3, // Atari GR.7: 160x96 pixels, 192 scan lines on 4:3 NTSC = 4/2.4
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    child: CustomPaint(
                      painter: _controller.createPainter(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Controls below render area
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
                    // Status text
                    Text(
                      'Command ${_controller.currentCommandIndex + 1} / ${widget.roomData.commands.length}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Current command details
                    _buildCurrentCommandInfo(),

                    const SizedBox(height: 8),

                    // Control buttons
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

                    // Pixels per second slider
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
                            min: 100,
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
                          width: 60,
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

                    // Command list (expandable)
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
                              final isCurrentCommand = idx == _controller.currentCommandIndex;
                              return Container(
                                padding: const EdgeInsets.only(bottom: 2),
                                color: isCurrentCommand
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                child: Text(
                                  '${idx + 1}. ${_describeCommand(cmd)}',
                                  style: TextStyle(
                                    color: isCurrentCommand ? Colors.white : Colors.green,
                                    fontSize: 9,
                                    fontWeight: isCurrentCommand ? FontWeight.bold : FontWeight.normal,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            }).toList(),
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

    final hexCode = _getCommandHexCode(cmd);
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

  String _getCommandHexCode(AtariBytecodeCommand cmd) {
    // Return the original hex bytes stored during parsing
    return cmd.hexBytes.isNotEmpty ? cmd.hexBytes : 'N/A';
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
            pat & 0x03
          ];
          return 'FILL_AT pattern=$cols @${cmd.fillSeed}';
        }
    }
  }
}
