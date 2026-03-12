import 'package:flutter/material.dart';
import 'room_bytecode_loader.dart';
import 'atari_bytecode_parser.dart';
import 'atari_render_controller.dart';

/// Test application for room bytecode data
///
/// Run with: flutter run lib/rendering/test_room_bytecode.dart
void main() {
  runApp(const RoomBytecodeTestApp());
}

class RoomBytecodeTestApp extends StatelessWidget {
  const RoomBytecodeTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Bytecode Test',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const RoomBytecodeTestHome(),
    );
  }
}

class RoomBytecodeTestHome extends StatefulWidget {
  const RoomBytecodeTestHome({super.key});

  @override
  State<RoomBytecodeTestHome> createState() => _RoomBytecodeTestHomeState();
}

class _RoomBytecodeTestHomeState extends State<RoomBytecodeTestHome> {
  bool _initialized = false;
  List<int> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    await RoomBytecodeLoader.initialize();
    setState(() {
      _initialized = true;
      _availableRooms = RoomBytecodeLoader.availableRooms;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cloak of Death - Room Bytecode'),
          backgroundColor: Colors.green.shade900,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    final availableRooms = _availableRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloak of Death - Room Bytecode'),
        backgroundColor: Colors.green.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Rooms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${availableRooms.length} rooms',
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                  ),
                  Text(
                    'IDs: ${availableRooms.join(", ")}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Missing rooms 9 and 17 (not in original data)',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Room cards
          ...availableRooms.map((roomId) => _buildRoomCard(context, roomId)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, int roomId) {
    final buffer = RoomBytecodeLoader.getRoomBuffer(roomId);
    if (buffer == null) {
      return const SizedBox.shrink();
    }

    final roomData = AtariBytecodeParser.parseRoom(buffer, roomId);
    if (roomData == null) {
      return Card(
        color: Colors.red.shade900,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text('Room $roomId'),
          subtitle: const Text('Failed to parse'),
        ),
      );
    }

    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomBytecodeViewer(
                roomId: roomId,
                roomData: roomData,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Room number badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$roomId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Room info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room $roomId',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${roomData.commands.length} commands, ${buffer.length} bytes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Palette colors
                    Row(
                      children: roomData.palette
                          .asMap()
                          .entries
                          .map((e) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: e.value,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 0.5,
                                  ),
                                ),
                              ))
                          .toList(),
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

/// Detailed view for a single room
class RoomBytecodeViewer extends StatelessWidget {
  final int roomId;
  final AtariRoomBytecode roomData;

  const RoomBytecodeViewer({
    super.key,
    required this.roomId,
    required this.roomData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room $roomId'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Column(
        children: [
          // Rendering area (2/3 of screen)
          Expanded(
            flex: 2,
            child: AtariAnimatedRoomView(
              roomData: roomData,
              autoStart: true,
            ),
          ),

          // Info panel (1/3 of screen)
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room $roomId Information',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Palette
                    const Text(
                      'Palette:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...roomData.palette.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: entry.value,
                                border: Border.all(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Color ${entry.key}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Commands summary
                    Text(
                      'Commands (${roomData.commands.length} total):',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...roomData.commands.asMap().entries.map((entry) {
                      final cmd = entry.value;
                      String desc = '';

                      switch (cmd.type) {
                        case BytecodeCommandType.polyline:
                          desc =
                              'Polyline (color ${cmd.colorIndex}, ${cmd.points.length} pts)';
                          break;
                        case BytecodeCommandType.closedPolyline:
                          desc =
                              'Closed Polyline (color ${cmd.colorIndex}, ${cmd.points.length} pts)';
                          break;
                        case BytecodeCommandType.floodFill:
                          desc = 'Flood fill (color ${cmd.colorIndex})';
                          break;
                        case BytecodeCommandType.floodFillAt:
                          if (cmd.fillPattern != null &&
                              cmd.fillPattern! <= 3) {
                            desc = 'Fill at (solid color ${cmd.fillPattern})';
                          } else {
                            desc = 'Fill at (pattern 0x${cmd.fillPattern?.toRadixString(16).toUpperCase()})';
                          }
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${entry.key + 1}. $desc',
                          style: TextStyle(
                            color: Colors.green.shade300,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
