import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

/// Unified minimap widget with integrated navigation controls
class UnifiedMinimap extends StatelessWidget {
  const UnifiedMinimap({super.key});

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
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Title
              const Text(
                'NAVIGATION',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Navigation grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Top row: UP, (empty), (room number)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNavButton('U', exits['U'], gameState),
                            const SizedBox(width: 4),
                            _buildRoomDisplay(currentRoomId),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // North button (centered)
                        Center(
                          child: _buildNavButton('N', exits['N'], gameState,
                              width: 60),
                        ),

                        const SizedBox(height: 4),

                        // Middle row: WEST, (center icon), EAST
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildNavButton('W', exits['W'], gameState),
                            const SizedBox(width: 2),
                            _buildCenterIcon(),
                            const SizedBox(width: 2),
                            _buildNavButton('E', exits['E'], gameState),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // South button (centered)
                        Center(
                          child: _buildNavButton('S', exits['S'], gameState,
                              width: 60),
                        ),

                        const SizedBox(height: 8),

                        // Bottom row: DOWN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildNavButton('D', exits['D'], gameState),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton(String direction, int? destRoom, GameState gameState,
      {double? width}) {
    final hasExit = destRoom != null;
    final labels = {
      'N': 'N',
      'S': 'S',
      'E': 'E',
      'W': 'W',
      'U': 'U',
      'D': 'D',
    };

    return SizedBox(
      width: width ?? 30,
      height: 30,
      child: ElevatedButton(
        onPressed:
            hasExit ? () => gameState.moveInDirection(direction) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasExit ? const Color(0xFF003300) : Colors.black,
          foregroundColor: Colors.green,
          disabledBackgroundColor: Colors.black,
          disabledForegroundColor: const Color(0xFF002200),
          padding: const EdgeInsets.all(1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: BorderSide(
              color: hasExit ? Colors.green : const Color(0xFF002200),
              width: 1,
            ),
          ),
        ),
        child: FittedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                labels[direction] ?? direction,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasExit)
                Text(
                  destRoom.toString(),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 6,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomDisplay(int roomId) {
    return Container(
      width: 42,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF003300),
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'RM',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 7,
                ),
              ),
              Text(
                roomId.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0x4D00FF00),
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.green,
        size: 20,
      ),
    );
  }
}
