import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

class GameSettingsDialog extends StatelessWidget {
  const GameSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, game, child) => AlertDialog(
      title: const Text('Display settings'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Draw rooms gradually'),
                subtitle: const Text(
                  'Turn off to show the complete scene instantly.',
                ),
                value: game.autoAnimateRooms,
                onChanged: game.setAutoAnimateRooms,
              ),
              const SizedBox(height: 16),
              const Text('Drawing speed'),
              Slider(
                value: game.pixelRenderSpeed.clamp(100, 5000),
                min: 100,
                max: 5000,
                divisions: 49,
                label: '${game.pixelRenderSpeed.round()} pixels/s',
                onChanged: game.autoAnimateRooms
                    ? game.setPixelRenderSpeed
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Picture proportions'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in {
                    'Atari': 160 / 96,
                    '4:3': 4 / 3,
                    '16:9': 16 / 9,
                  }.entries)
                    ChoiceChip(
                      label: Text(preset.key),
                      selected: (game.aspectRatio - preset.value).abs() < 0.01,
                      onSelected: (_) => game.setAspectRatio(preset.value),
                    ),
                ],
              ),
              Slider(
                value: game.aspectRatio,
                min: 1,
                max: 4,
                divisions: 60,
                label: game.aspectRatio.toStringAsFixed(2),
                onChanged: game.setAspectRatio,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}
