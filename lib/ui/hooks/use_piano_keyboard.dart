import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'use_velocity.dart';
import 'use_sustain.dart';
import 'use_player.dart';

typedef PianoKeyHandler = KeyEventResult Function(
    FocusNode node, KeyEvent event);

PianoKeyHandler usePianoKeyboard({
  required VelocityState velocity,
  required SustainState sustain,
  required PianoPlayer player,
  void Function(int midi)? onNoteOn,
  void Function(int midi)? onNoteOff,
}) {
  final activeNotes = useRef<Set<int>>({});
  final isSpaceHeld = useRef<bool>(false);

  final midiNotes = useMemoized(() => {
    LogicalKeyboardKey.keyA: 60,
    LogicalKeyboardKey.keyW: 61,
    LogicalKeyboardKey.keyS: 62,
    LogicalKeyboardKey.keyE: 63,
    LogicalKeyboardKey.keyD: 64,
    LogicalKeyboardKey.keyF: 65,
    LogicalKeyboardKey.keyT: 66,
    LogicalKeyboardKey.keyG: 67,
    LogicalKeyboardKey.keyY: 68,
    LogicalKeyboardKey.keyH: 69,
    LogicalKeyboardKey.keyU: 70,
    LogicalKeyboardKey.keyJ: 71,
    LogicalKeyboardKey.keyK: 72,
    LogicalKeyboardKey.keyO: 73,
    LogicalKeyboardKey.keyL: 74,
    LogicalKeyboardKey.keyP: 75,
    LogicalKeyboardKey.semicolon: 76,
    LogicalKeyboardKey.quoteSingle: 77,
  }, []);

  return useCallback<PianoKeyHandler>((FocusNode node, KeyEvent event) {
    KeyEventResult result = KeyEventResult.ignored;

    final key = event.logicalKey;
    // final isCapsLockOn = HardwareKeyboard.instance.lockModesEnabled
    //     .contains(KeyboardLockMode.capsLock);

    if (event is KeyDownEvent) {
      if (midiNotes.containsKey(key)) {
        final midi = midiNotes[key]!;
        if (!activeNotes.value.contains(midi)) {
          activeNotes.value.add(midi);
          onNoteOn?.call(midi);
          player.play(midi);
        }
        result = KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyC) {
        velocity.adjust(-1);
        result = KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyV) {
        velocity.adjust(1);
        result = KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.space) {
        isSpaceHeld.value = true;
        sustain.setSustain(true);
        result = KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      if (midiNotes.containsKey(key)) {
        final midi = midiNotes[key]!;
        if (activeNotes.value.contains(midi)) {
          activeNotes.value.remove(midi);
          onNoteOff?.call(midi);
          player.stop(midi);
        }
        result = KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.space) {
        isSpaceHeld.value = false;
        sustain.setSustain(false);
        result = KeyEventResult.handled;
      }
    }

    // // Sync sustain with Caps Lock state on any key event
    // if (key == LogicalKeyboardKey.capsLock) {
    //   sustain.setSustain(isCapsLockOn || isSpaceHeld.value);
    // }

    return result;
  }, [velocity, sustain, player, onNoteOn, onNoteOff]);
}
