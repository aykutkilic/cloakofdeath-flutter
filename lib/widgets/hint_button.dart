import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

class HintButton extends StatelessWidget {
  const HintButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'A gentle hint',
    icon: const Icon(Icons.lightbulb_outline),
    onPressed: () {
      final game = context.read<GameState>();
      var hint = game.takeHint();
      showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            icon: const Icon(Icons.lightbulb_outline),
            title: const Text('A thought to follow'),
            content: SingleChildScrollView(child: Text(hint.text)),
            actions: [
              TextButton(
                onPressed: () => setState(() => hint = game.takeHint()),
                child: const Text('Another hint'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep exploring'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
