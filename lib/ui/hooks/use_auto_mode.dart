import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../src/models/auto_mode.dart';
import 'use_player.dart';

class AutoModeState {
  final bool isActive;
  final String? displayLabel;
  final VoidCallback toggle;

  const AutoModeState({
    required this.isActive,
    required this.displayLabel,
    required this.toggle,
  });
}

AutoModeState useAutoMode({required PianoPlayer player}) {
  final isActive = useState(false);
  final displayLabel = useState<String?>(null);
  final playerRef = useRef(player);
  playerRef.value = player;

  final toggle = useCallback(() {
    isActive.value = !isActive.value;
    if (!isActive.value) {
      displayLabel.value = null;
    }
  }, []);

  useEffect(() {
    if (!isActive.value) return null;

    final random = Random();
    var beat = 0;
    Timer? clickStopTimer;
    Timer? noteStopTimer;

    Future<void> playClick({required bool accent}) async {
      final midi = accent ? AutoModeNote.accentMidi : AutoModeNote.clickMidi;
      clickStopTimer?.cancel();
      await playerRef.value.play(midi);
      clickStopTimer = Timer(AutoModeNote.clickDuration, () {
        playerRef.value.stop(midi);
      });
    }

    Future<void> playRandomNote() async {
      final midi = AutoModeNote.randomMidi(random);
      displayLabel.value = AutoModeNote.displayLabel(midi);
      noteStopTimer?.cancel();
      await playerRef.value.play(midi);
      noteStopTimer = Timer(AutoModeNote.noteDuration, () {
        playerRef.value.stop(midi);
      });
    }

    void onBeat() {
      switch (AutoModeNote.actionAtBeat(beat)) {
        case AutoModeBeatAction.accentAndNote:
          playClick(accent: true);
          playRandomNote();
        case AutoModeBeatAction.click:
          playClick(accent: false);
        case AutoModeBeatAction.rest:
          break;
      }
      beat++;
    }

    onBeat();
    final timer = Timer.periodic(AutoModeNote.beatDuration, (_) => onBeat());

    return () {
      timer.cancel();
      clickStopTimer?.cancel();
      noteStopTimer?.cancel();
    };
  }, [isActive.value]);

  return AutoModeState(
    isActive: isActive.value,
    displayLabel: displayLabel.value,
    toggle: toggle,
  );
}
