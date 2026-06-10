import 'dart:math';

/// What happens on each beat of the auto mode loop.
enum AutoModeBeatAction {
  note,
  click,
}

/// Auto mode: metronome at 120 BPM with random single notes (C2–C5).
class AutoModeNote {
  AutoModeNote._();

  static const minMidi = 36; // C2
  static const maxMidi = 72; // C5
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

  /// C → オクターブ, others → octave register 3–6 (C2=3 … C5=6).
  static String displayLabel(int midi) {
    if (midi % 12 == 0) return 'オクターブ';
    return '${midi ~/ 12}';
  }
}
