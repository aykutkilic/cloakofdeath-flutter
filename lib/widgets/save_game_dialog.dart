import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_state.dart';
import '../game/save_slot.dart';

class SaveGameDialog extends StatefulWidget {
  const SaveGameDialog({super.key});

  @override
  State<SaveGameDialog> createState() => _SaveGameDialogState();
}

class _SaveGameDialogState extends State<SaveGameDialog> {
  bool _busy = false;
  String? _message;

  Future<void> _act(GameState game, SaveSlot slot, {required bool load}) async {
    if (_busy) return;
    if (load || slot.occupied) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            load ? 'Load slot ${slot.number}?' : 'Replace slot ${slot.number}?',
          ),
          content: Text(
            load
                ? 'Your current journey will be replaced by this saved game.'
                : 'The previous save in this slot will be replaced by your current journey.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(load ? 'Load game' : 'Replace save'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (load) {
        await game.loadFromSlot(slot.number);
        if (mounted) Navigator.pop(context);
      } else {
        await game.saveToSlot(slot.number);
        if (mounted) setState(() => _message = 'Saved to slot ${slot.number}.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = load
              ? 'Could not load this slot. Your current journey is unchanged.'
              : 'Could not save the game. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _description(GameState game, SaveSlot slot) {
    if (slot.unreadable) return 'Save unreadable · choose Save to replace';
    if (!slot.occupied) return 'Empty slot';
    final date = slot.savedAt!.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final room = game.gameData!.getRoomById(slot.roomId)!.name;
    return '$room · Turn ${slot.moves}\n'
        '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Save / load game'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your journey autosaves. Keep up to eight checkpoints here.',
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_message!, semanticsLabel: _message),
                ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: game.saveSlots.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final slot = game.saveSlots[index];
                    return Column(
                      key: ValueKey('save-slot-${slot.number}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Slot ${slot.number}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          _description(game, slot),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            children: [
                              TextButton.icon(
                                key: ValueKey('save-${slot.number}'),
                                onPressed: _busy
                                    ? null
                                    : () => _act(game, slot, load: false),
                                icon: const Icon(Icons.save_outlined, size: 18),
                                label: const Text('Save'),
                              ),
                              TextButton.icon(
                                key: ValueKey('load-${slot.number}'),
                                onPressed: _busy || !slot.canLoad
                                    ? null
                                    : () => _act(game, slot, load: true),
                                icon: const Icon(Icons.restore, size: 18),
                                label: const Text('Load'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
