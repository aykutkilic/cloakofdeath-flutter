import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

/// Widget that displays a minimap showing current room and connected rooms
class MinimapWidget extends StatelessWidget {
  const MinimapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final currentRoomId = gameState.currentRoomId;
        final exits = gameState.getAvailableExits();

        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.green, width: 2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'MINIMAP',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Current room display
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003300),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ROOM',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          color: Colors.green,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        currentRoomId.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          color: Colors.green,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Connections grid
              const Text(
                'EXITS:',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 6),

              // Grid showing N, S, E, W exits
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // North
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildExitIndicator('N', exits['N']),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // West, Center, East
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildExitIndicator('W', exits['W']),
                        const SizedBox(width: 4),
                        _buildCenterIndicator(),
                        const SizedBox(width: 4),
                        _buildExitIndicator('E', exits['E']),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // South
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildExitIndicator('S', exits['S']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Up/Down
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildExitIndicator('U', exits['U']),
                        const SizedBox(width: 4),
                        _buildExitIndicator('D', exits['D']),
                      ],
                    ),
                  ],
                ),
              ),

              // Legend
              const Text(
                'Green: Exit available',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 7,
                ),
              ),
              const Text(
                'Dark: No exit',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 7,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExitIndicator(String direction, int? roomId) {
    final hasExit = roomId != null;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: hasExit ? const Color(0xFF003300) : Colors.black,
        border: Border.all(
          color: hasExit ? Colors.green : const Color(0xFF002200),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            direction,
            style: TextStyle(
              fontFamily: 'Courier',
              color: hasExit ? Colors.green : const Color(0xFF002200),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasExit)
            Text(
              roomId.toString(),
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Colors.green,
                fontSize: 7,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterIndicator() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0x4D00FF00),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.green,
          size: 18,
        ),
      ),
    );
  }
}
