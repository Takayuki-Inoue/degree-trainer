import 'dart:math';

/// What happens on each beat of the auto mode loop.
enum AutoModeBeatAction {
  note,
  click,
}

/// Auto mode: metronome at 120 BPM with random single notes (C2–C6).
class AutoModeNote {
  AutoModeNote._();

  static const minMidi = 36; // C2 (default)
  static const maxMidi = 72; // C5 (default)
  static const bpm = 120;
  static const beatDuration = Duration(milliseconds: 60000 ~/ bpm);
  static const noteDuration = Duration(milliseconds: 350);

  /// 4/4 bar (note, click, click, click) → 4/4 bar (4 clicks) → repeat.
  static const List<AutoModeBeatAction> cyclePattern = [
    AutoModeBeatAction.note,  // bar 1 beat 1 (4/4) - plays click and random note
    AutoModeBeatAction.click, // bar 1 beat 2
    AutoModeBeatAction.click, // bar 1 beat 3
    AutoModeBeatAction.click, // bar 1 beat 4
    AutoModeBeatAction.click, // bar 2 beat 1 (4/4)
    AutoModeBeatAction.click, // bar 2 beat 2
    AutoModeBeatAction.click, // bar 2 beat 3
    AutoModeBeatAction.click, // bar 2 beat 4
  ];

  static AutoModeBeatAction actionAtBeat(int beatIndex) {
    return cyclePattern[beatIndex % cyclePattern.length];
  }

  static int randomMidi(Random random, {int minNote = minMidi, int maxNote = maxMidi}) {
    final lo = minNote < maxNote ? minNote : maxNote;
    final hi = minNote < maxNote ? maxNote : minNote;
    return lo + random.nextInt(hi - lo + 1);
  }

  /// White key MIDI values from C2 to C6 (for range selection UI).
  static const List<int> whiteKeyMidis = [
    36, 38, 40, 41, 43, 45, 47, // C2–B2
    48, 50, 52, 53, 55, 57, 59, // C3–B3
    60, 62, 64, 65, 67, 69, 71, // C4–B4
    72, 74, 76, 77, 79, 81, 83, // C5–B5
    84,                          // C6
  ];

  static const _noteNames = {
    0: 'C', 2: 'D', 4: 'E', 5: 'F', 7: 'G', 9: 'A', 11: 'B',
  };

  static String midiToNoteName(int midi) {
    return '${_noteNames[midi % 12]}${midi ~/ 12 - 1}';
  }

  static const List<String> displayLabels = ['オクターブ', '3', '4', '5', '6'];

  static String randomDisplayLabel(Random random) {
    return displayLabels[random.nextInt(displayLabels.length)];
  }
}
