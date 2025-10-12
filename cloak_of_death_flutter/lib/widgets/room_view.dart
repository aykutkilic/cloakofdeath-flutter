import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../rendering/atari_bytecode_parser.dart';
import '../rendering/atari_render_controller_v2.dart';
import '../rendering/room_bytecode_loader.dart';
import '../game/game_state.dart';

/// Widget that displays a room using Atari pixel rendering
class RoomView extends StatelessWidget {
  final Room room;

  const RoomView({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    // Load bytecode for this room (includes next room marker for proper stop logging)
    final bytecode = RoomBytecodeLoader.getRoomBuffer(room.id);

    if (bytecode == null) {
      return _buildErrorView('Room ${room.id} has no graphics data');
    }

    // Parse bytecode with logging enabled
    final roomData = AtariBytecodeParser.parseRoom(bytecode, room.id, enableLogging: true);

    if (roomData == null) {
      return _buildErrorView('Failed to parse room ${room.id} bytecode');
    }

    // Render with pixel engine (V2 - Fixed)
    return AtariAnimatedRoomViewV2(
      roomData: roomData,
      autoStart: gameState.autoAnimateRooms,
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
