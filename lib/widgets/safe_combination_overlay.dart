import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../game/game_state.dart';
import 'hint_button.dart';

/// Follows the engine's pending input, including restored saves and typed OPEN.
/// The overlay shields normal controls: movement is not a combination attempt.
class SafeCombinationOverlay extends StatelessWidget {
  final Widget child;
  const SafeCombinationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<GameState, bool>(
      (g) => g.awaitingCombination,
    );
    return Stack(
      children: [
        ExcludeFocus(
          excluding: pending,
          child: ExcludeSemantics(excluding: pending, child: child),
        ),
        if (pending) ...[
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Colors.black54),
          ),
          const Positioned.fill(
            child: SafeArea(child: Center(child: _CombinationPanel())),
          ),
        ],
      ],
    );
  }
}

class _CombinationPanel extends StatefulWidget {
  const _CombinationPanel();
  @override
  State<_CombinationPanel> createState() => _CombinationPanelState();
}

class _CombinationPanelState extends State<_CombinationPanel> {
  String _digits = '';
  bool _submitted = false;

  void _digit(String digit) {
    if (_digits.length < 4) setState(() => _digits += digit);
  }

  void _backspace() {
    if (_digits.isNotEmpty) {
      setState(() => _digits = _digits.substring(0, _digits.length - 1));
    }
  }

  void _submit() {
    if (_digits.length != 4 || _submitted) return;
    _submitted = true;
    context.read<GameState>().processCommand(_digits);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('safe-combination'),
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final character = event.character;
          if (character != null && RegExp(r'^[0-9]$').hasMatch(character)) {
            _digit(character);
          } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _backspace();
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            _submit();
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppTheme.accent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Wall safe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const HintButton(),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Four digits. One hidden way out.',
                style: TextStyle(color: AppTheme.mutedColor),
              ),
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                label:
                    'Combination: ${_digits.isEmpty ? 'empty' : _digits.split('').join(' ')}. '
                    '${_digits.length} of 4 digits.',
                child: ExcludeSemantics(
                  child: Row(
                    children: List.generate(
                      4,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: index == _digits.length
                                  ? AppTheme.accent
                                  : AppTheme.border,
                            ),
                          ),
                          child: Text(
                            index < _digits.length ? _digits[index] : '·',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final row in ['123', '456', '789', 'C0⌫'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: row
                        .split('')
                        .map(
                          (key) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  if (key == 'C') {
                                    setState(() => _digits = '');
                                  } else if (key == '⌫') {
                                    _backspace();
                                  } else {
                                    _digit(key);
                                  }
                                },
                                child: key == '⌫'
                                    ? const Icon(
                                        Icons.backspace_outlined,
                                        semanticLabel: 'Delete last digit',
                                        size: 20,
                                      )
                                    : Text(
                                        key,
                                        semanticsLabel: key == 'C'
                                            ? 'Clear digits'
                                            : key,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'The lock is wired. A wrong combination is fatal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.warningColor, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _digits.length == 4 ? _submit : null,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Try combination'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
