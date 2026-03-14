import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/game_state.dart';

/// Unified minimap widget with integrated navigation controls.
/// Set [floating] to true for transparent overlay mode (portrait).
/// In floating mode, the widget starts collapsed as a single player icon
/// and expands on tap, auto-collapsing after 5 seconds of inactivity.
class UnifiedMinimap extends StatefulWidget {
  final bool floating;

  const UnifiedMinimap({super.key, this.floating = false});

  @override
  State<UnifiedMinimap> createState() => _UnifiedMinimapState();
}

class _UnifiedMinimapState extends State<UnifiedMinimap> {
  bool _expanded = false;
  Timer? _collapseTimer;

  double get _buttonSize => widget.floating ? 44 : 48;
  double get _spacing => 6.0;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    _resetCollapseTimer();
  }

  void _collapse() {
    _collapseTimer?.cancel();
    setState(() => _expanded = false);
  }

  void _resetCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 5), _collapse);
  }

  void _onNavPressed(GameState gameState, String direction) {
    gameState.processCommand(direction);
    _resetCollapseTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final exits = gameState.getAvailableExits();

        // Floating mode: collapsed = just the player icon; expanded = full nav
        if (widget.floating && !_expanded) {
          return GestureDetector(
            onTap: _expand,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: _buildCenterIcon(),
            ),
          );
        }

        final content = FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: UP/DOWN stack
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavButton('U', exits.containsKey('U'), gameState),
                  SizedBox(height: _spacing),
                  _buildNavButton('D', exits.containsKey('D'), gameState),
                ],
              ),
              const SizedBox(width: 20),
              // Right side: Compass cross
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavButton('N', exits.containsKey('N'), gameState),
                  SizedBox(height: _spacing),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavButton('W', exits.containsKey('W'), gameState),
                      SizedBox(width: _spacing),
                      widget.floating
                          ? GestureDetector(
                              onTap: _collapse,
                              child: _buildCenterIcon(),
                            )
                          : _buildCenterIcon(),
                      SizedBox(width: _spacing),
                      _buildNavButton('E', exits.containsKey('E'), gameState),
                    ],
                  ),
                  SizedBox(height: _spacing),
                  _buildNavButton('S', exits.containsKey('S'), gameState),
                ],
              ),
            ],
          ),
        );

        if (widget.floating) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.background.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: content,
          );
        }

        return Container(
          decoration: const BoxDecoration(color: AppTheme.background),
          padding: const EdgeInsets.all(8),
          child: Center(child: content),
        );
      },
    );
  }

  Widget _buildNavButton(
    String direction,
    bool hasExit,
    GameState gameState,
  ) {
    final bgColor = widget.floating
        ? (hasExit ? AppTheme.highlight.withAlpha(200) : Colors.transparent)
        : (hasExit ? AppTheme.highlight : AppTheme.background);

    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: ElevatedButton(
        onPressed: () => _onNavPressed(gameState, direction),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: hasExit ? AppTheme.text : AppTheme.panel,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide.none,
          elevation: 0,
        ),
        child: Text(
          direction,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: hasExit
                ? AppTheme.text
                : (widget.floating ? AppTheme.text.withAlpha(60) : AppTheme.panel),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    return Container(
      width: _buttonSize,
      height: _buttonSize,
      decoration: BoxDecoration(
        color: widget.floating
            ? AppTheme.highlight.withAlpha(60)
            : AppTheme.highlight.withAlpha(77),
      ),
      child: const Icon(Icons.person, color: AppTheme.text, size: 28),
    );
  }
}
