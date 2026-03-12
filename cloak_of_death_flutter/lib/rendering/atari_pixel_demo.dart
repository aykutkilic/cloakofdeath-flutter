import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'atari_bytecode_parser.dart';
import 'atari_render_controller.dart';

/// Demo widget for testing the Atari pixel rendering engine
///
/// This demonstrates how to:
/// 1. Load raw FIND bytecode data
/// 2. Parse it with AtariBytecodeParser
/// 3. Render it with AtariAnimatedRoomView
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AtariPixelDemo(bytecodeBuffer: findData),
///   ),
/// );
/// ```
class AtariPixelDemo extends StatelessWidget {
  final Uint8List bytecodeBuffer;
  final int roomId;
  final double? pixelsPerSecond;

  const AtariPixelDemo({
    super.key,
    required this.bytecodeBuffer,
    this.roomId = 1,
    this.pixelsPerSecond,
  });

  @override
  Widget build(BuildContext context) {
    // Parse room data from bytecode
    final roomData = AtariBytecodeParser.parseRoom(bytecodeBuffer, roomId);

    if (roomData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Atari Pixel Renderer')),
        body: Center(
          child: Text(
            'Room $roomId not found in bytecode buffer',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Atari Pixel Renderer - Room ${roomData.roomId}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Info panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${roomData.roomId}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commands: ${roomData.commands.length}',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
                Text(
                  'Palette: ${roomData.palette.length} colors',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Colors: ',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                    ...roomData.palette.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: entry.value,
                          border: Border.all(color: Colors.white),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Rendering area
          Expanded(
            child: AtariAnimatedRoomView(
              roomData: roomData,
              autoStart: true,
              pixelsPerSecond: pixelsPerSecond,
            ),
          ),
        ],
      ),
    );
  }
}

/// Creates sample bytecode data for testing
///
/// This creates a minimal room with:
/// - Room ID: 1 (marker 0xA1)
/// - Palette: 4 colors
/// - Simple rectangle polyline
/// - Flood fill
Uint8List createSampleBytecode() {
  final buffer = <int>[];

  // Room 1 marker (0xA1 = 161)
  buffer.add(0xA1);

  // Palette (4 colors)
  buffer.add(0x00); // Color 0: Black
  buffer.add(0x0F); // Color 1: White
  buffer.add(0x48); // Color 2: Red
  buffer.add(0x98); // Color 3: Blue

  // Command: CD (polyline with color 0) - draw rectangle outline
  buffer.add(0xCD);
  buffer.add(20); // X1
  buffer.add(20); // Y1
  buffer.add(140); // X2
  buffer.add(20); // Y2
  buffer.add(140); // X3
  buffer.add(76); // Y3
  buffer.add(20); // X4
  buffer.add(76); // Y4
  buffer.add(20); // X5 (close)
  buffer.add(20); // Y5

  // Command: CC (flood fill at point with color)
  buffer.add(0xCC);
  buffer.add(0x01); // Pattern: solid color 1 (white)
  buffer.add(80); // Seed X
  buffer.add(48); // Seed Y

  // Command: CE (polyline with color 1) - draw inner line
  buffer.add(0xCE);
  buffer.add(40); // X1
  buffer.add(40); // Y1
  buffer.add(120); // X2
  buffer.add(56); // Y2

  // End marker
  buffer.add(0xFF);

  return Uint8List.fromList(buffer);
}

/// Example widget showing how to integrate with existing room system
class AtariPixelToggleDemo extends StatefulWidget {
  final Uint8List? bytecodeData;
  final int roomId;

  const AtariPixelToggleDemo({
    super.key,
    this.bytecodeData,
    this.roomId = 1,
  });

  @override
  State<AtariPixelToggleDemo> createState() => _AtariPixelToggleDemoState();
}

class _AtariPixelToggleDemoState extends State<AtariPixelToggleDemo> {
  bool _usePixelEngine = false;
  final double _pixelsPerSecond = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atari Renderer Demo'),
        actions: [
          // Toggle between renderers
          Switch(
            value: _usePixelEngine,
            onChanged: (value) {
              setState(() {
                _usePixelEngine = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _usePixelEngine ? 'Pixel Engine' : 'Vector Renderer',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!_usePixelEngine) {
      return const Center(
        child: Text(
          'Vector renderer mode\n(Toggle switch to enable pixel engine)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Use pixel engine
    final bytecode = widget.bytecodeData ?? createSampleBytecode();
    final roomData = AtariBytecodeParser.parseRoom(bytecode, widget.roomId);

    if (roomData == null) {
      return const Center(
        child: Text('Failed to parse bytecode'),
      );
    }

    return AtariAnimatedRoomView(
      roomData: roomData,
      pixelsPerSecond: _pixelsPerSecond,
      autoStart: true,
    );
  }
}
