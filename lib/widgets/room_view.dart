import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../rendering/atari_bytecode_parser.dart';
import '../rendering/atari_render_controller.dart';
import '../rendering/room_bytecode_loader.dart';
import '../game/game_state.dart';
import '../app_theme.dart';

/// Widget that displays a room using Atari pixel rendering
class RoomView extends StatefulWidget {
  final Room room;

  const RoomView({super.key, required this.room});

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  AtariRoomBytecode? _cachedRoomData;
  int? _cachedRoomId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndParseRoom();
  }

  @override
  void didUpdateWidget(RoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id) {
      _checkAndParseRoom();
    }
  }

  void _checkAndParseRoom() {
    if (_cachedRoomId != widget.room.id) {
      final bytecode = RoomBytecodeLoader.getRoomBuffer(widget.room.id);
      if (bytecode != null) {
        _cachedRoomData = AtariBytecodeParser.parseRoom(
          bytecode,
          widget.room.id,
          enableLogging: false,
        );
      } else {
        _cachedRoomData = null;
      }
      _cachedRoomId = widget.room.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only watch specific fields to avoid full rebuilds if possible,
    // but AtariAnimatedRoomView already prevents internal restart.
    final autoAnimateRooms = context.select<GameState, bool>(
      (s) => s.autoAnimateRooms,
    );
    final showDebugInfo = context.select<GameState, bool>(
      (s) => s.showDebugInfo,
    );
    final isTooDarkToSee = context.select<GameState, bool>(
      (s) => s.isTooDarkToSee,
    );
    final pixelRenderSpeed = context.select<GameState, double>(
      (s) => s.pixelRenderSpeed,
    );

    if (isTooDarkToSee) {
      return Container(
        decoration: const BoxDecoration(color: AppTheme.panel),
        child: const Center(child: Text('► IT\'S TOO DARK TO SEE')),
      );
    }

    if (_cachedRoomData == null) {
      return _buildErrorView('Room ${widget.room.id} has no graphics data');
    }

    // Render with pixel engine
    return AtariAnimatedRoomView(
      roomData: _cachedRoomData!,
      autoStart: autoAnimateRooms,
      showDebugInfo: showDebugInfo,
      pixelsPerSecond: pixelRenderSpeed,
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppTheme.warningColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
