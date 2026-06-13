import 'dart:math';

/// What happens on each beat of the auto mode loop.
enum AutoModeBeatAction {
  note,
  click,
}

/// Auto mode: metronome at 120 BPM with random single notes (C2–C6).
class AutoModeNote {
  AutoModeNote._();

  static const minMidi = 36; // C2
  static const maxMidi = 84; // C6
  static const bpm = 120;
  static const beatDuration = Duration(milliseconds: 60000 ~/ bpm);
  static const noteDuration = Duration(milliseconds: 350);

  /// 2/4 bar (note, click) → 4/4 bar (4 clicks) → 4/4 bar (4 clicks) → repeat.
  static const List<AutoModeBeatAction> cyclePattern = [
    AutoModeBeatAction.note,  // bar 1 beat 1 (2/4) - plays click and random note
    AutoModeBeatAction.click, // bar 1 beat 2
    AutoModeBeatAction.click, // bar 2 beat 1 (4/4)
    AutoModeBeatAction.click, // bar 2 beat 2
    AutoModeBeatAction.click, // bar 2 beat 3
    AutoModeBeatAction.click, // bar 2 beat 4
    AutoModeBeatAction.click, // bar 3 beat 1 (4/4)
    AutoModeBeatAction.click, // bar 3 beat 2
    AutoModeBeatAction.click, // bar 3 beat 3
    AutoModeBeatAction.click, // bar 3 beat 4
  ];

  static AutoModeBeatAction actionAtBeat(int beatIndex) {
    return cyclePattern[beatIndex % cyclePattern.length];
  }

  static int randomMidi(Random random) {
    return minMidi + random.nextInt(maxMidi - minMidi + 1);
  }

  static const List<String> displayLabels = ['オクターブ', '3', '4', '5', '6'];

  static String randomDisplayLabel(Random random) {
    return displayLabels[random.nextInt(displayLabels.length)];
  }
}
