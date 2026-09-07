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
            title: const Text('Hints for your next step'),
            content: SingleChildScrollView(child: Text(hint.text)),
            actions: [
              TextButton(
                onPressed: game.hasMoreHints
                    ? () => setState(() => hint = game.takeHint())
                    : null,
                child: Text(
                  game.hasMoreHints ? 'Another hint' : 'All hints shown',
                ),
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
