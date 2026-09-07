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
      final hint = context.read<GameState>().nextHint;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.lightbulb_outline),
          title: const Text('A thought to follow'),
          content: SingleChildScrollView(child: Text(hint.text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep exploring'),
            ),
          ],
        ),
      );
    },
  );
}
