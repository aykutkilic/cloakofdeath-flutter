import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'atari_pixel_demo.dart';

/// Test application for Atari pixel rendering engine
///
/// Run with: flutter run lib/rendering/pixel_engine_test.dart
void main() {
  runApp(const PixelEngineTestApp());
}

class PixelEngineTestApp extends StatelessWidget {
  const PixelEngineTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atari Pixel Engine Test',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PixelEngineTestHome(),
    );
  }
}

class PixelEngineTestHome extends StatelessWidget {
  const PixelEngineTestHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atari Pixel Engine Tests'),
        backgroundColor: Colors.green.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestCard(
            context,
            'Test 1: Sample Rectangle',
            'Simple rectangle with flood fill',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AtariPixelDemo(
                  bytecodeBuffer: createSampleBytecode(),
                  roomId: 1,
                  pixelsPerSecond: 20.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            context,
            'Test 2: Fast Rendering',
            'Same scene at 200 pixels/second',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AtariPixelDemo(
                  bytecodeBuffer: createSampleBytecode(),
                  roomId: 1,
                  pixelsPerSecond: 200.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            context,
            'Test 3: Complex Scene',
            'Multiple polylines and fills',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AtariPixelDemo(
                  bytecodeBuffer: _createComplexBytecode(),
                  roomId: 1,
                  pixelsPerSecond: 50.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            context,
            'Test 4: Pattern Fill',
            'Test 4-column pattern fills',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AtariPixelDemo(
                  bytecodeBuffer: _createPatternBytecode(),
                  roomId: 1,
                  pixelsPerSecond: 30.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'About the Pixel Engine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This pixel rendering engine emulates the Atari 65XE FIND graphics routine.\n\n'
            'Features:\n'
            '• Bytecode parser for FIND format\n'
            '• Bresenham line algorithm\n'
            '• Scanline flood fill\n'
            '• 4-column pattern fills\n'
            '• Progressive rendering animation\n'
            '• Configurable render speed (pixels/second)\n\n'
            'Command Types:\n'
            '• C8: Polyline (current color)\n'
            '• C9: Flood fill last polyline\n'
            '• CC: Flood fill at point\n'
            '• CD-D0: Polylines with colors 0-3',
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.grey.shade900,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.play_arrow, color: Colors.green, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create complex test scene with multiple shapes
Uint8List _createComplexBytecode() {
  final buffer = <int>[];

  // Room marker
  buffer.add(0xA1);

  // Palette
  buffer.add(0x00); // 0: Black
  buffer.add(0x0F); // 1: White
  buffer.add(0x44); // 2: Red
  buffer.add(0x94); // 3: Blue

  // Draw outer rectangle (color 1 = white)
  buffer.add(0xCE); // Polyline with color 1
  buffer.addAll([20, 10, 140, 10, 140, 86, 20, 86, 20, 10]);

  // Draw inner rectangle (color 2 = red)
  buffer.add(0xCF); // Polyline with color 2
  buffer.addAll([40, 30, 120, 30, 120, 66, 40, 66, 40, 30]);

  // Fill inner rectangle with red
  buffer.add(0xCC);
  buffer.add(0x02); // Solid color 2 (red)
  buffer.add(80); // Seed X
  buffer.add(48); // Seed Y

  // Draw diagonal line (color 3 = blue)
  buffer.add(0xD0); // Polyline with color 3
  buffer.addAll([30, 20, 130, 76]);

  // Draw circle approximation (color 1 = white)
  buffer.add(0xCE); // Polyline with color 1
  buffer.addAll([
    80, 48, // Center point
    95, 48, // Right
    90, 58, // Bottom-right
    80, 63, // Bottom
    70, 58, // Bottom-left
    65, 48, // Left
    70, 38, // Top-left
    80, 33, // Top
    90, 38, // Top-right
    95, 48, // Back to right
  ]);

  buffer.add(0xFF); // End
  return Uint8List.fromList(buffer);
}

/// Create pattern fill test scene
Uint8List _createPatternBytecode() {
  final buffer = <int>[];

  // Room marker
  buffer.add(0xA1);

  // Palette with distinct colors
  buffer.add(0x00); // 0: Black
  buffer.add(0x4C); // 1: Bright red
  buffer.add(0x9C); // 2: Bright blue
  buffer.add(0xBE); // 3: Bright green

  // Create rectangles with different patterns

  // Rectangle 1: Pattern 0b11100100 (colors 3,2,1,0)
  buffer.add(0xCE); // White outline
  buffer.addAll([10, 10, 70, 10, 70, 40, 10, 40, 10, 10]);
  buffer.add(0xCC);
  buffer.add(0xE4); // Pattern: 11 10 01 00
  buffer.add(40);
  buffer.add(25);

  // Rectangle 2: Pattern 0b00011011 (colors 0,1,2,3)
  buffer.add(0xCE);
  buffer.addAll([80, 10, 150, 10, 150, 40, 80, 40, 80, 10]);
  buffer.add(0xCC);
  buffer.add(0x1B); // Pattern: 00 01 10 11
  buffer.add(115);
  buffer.add(25);

  // Rectangle 3: Solid color 1 (red)
  buffer.add(0xCE);
  buffer.addAll([10, 50, 70, 50, 70, 86, 10, 86, 10, 50]);
  buffer.add(0xCC);
  buffer.add(0x01); // Solid color 1
  buffer.add(40);
  buffer.add(68);

  // Rectangle 4: Pattern 0b10101010 (alternating colors 2,1,2,2)
  buffer.add(0xCE);
  buffer.addAll([80, 50, 150, 50, 150, 86, 80, 86, 80, 50]);
  buffer.add(0xCC);
  buffer.add(0xAA); // Pattern: 10 10 10 10
  buffer.add(115);
  buffer.add(68);

  buffer.add(0xFF); // End
  return Uint8List.fromList(buffer);
}
