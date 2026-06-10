import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_piano/src/models/auto_mode.dart';

void main() {
  group('AutoModeNote', () {
    test('randomMidi stays within C2 to C5', () {
      final random = Random(0);
      for (var i = 0; i < 100; i++) {
        final midi = AutoModeNote.randomMidi(random);
        expect(midi, inInclusiveRange(AutoModeNote.minMidi, AutoModeNote.maxMidi));
      }
    });

    test('displayLabel maps C to octave label and others to register', () {
      expect(AutoModeNote.displayLabel(36), 'オクターブ'); // C2
      expect(AutoModeNote.displayLabel(40), '3'); // E2
      expect(AutoModeNote.displayLabel(48), 'オクターブ'); // C3
      expect(AutoModeNote.displayLabel(64), '5'); // E4
      expect(AutoModeNote.displayLabel(72), 'オクターブ'); // C5
    });

    test('beatDuration matches BPM 120', () {
      expect(AutoModeNote.beatDuration, const Duration(milliseconds: 500));
    });

    test('cyclePattern is 2 active beats then 8 rests', () {
      expect(AutoModeNote.cyclePattern, hasLength(10));
      expect(AutoModeNote.actionAtBeat(0), AutoModeBeatAction.accentAndNote);
      expect(AutoModeNote.actionAtBeat(1), AutoModeBeatAction.click);
      for (var i = 2; i < 10; i++) {
        expect(AutoModeNote.actionAtBeat(i), AutoModeBeatAction.rest);
      }
      expect(AutoModeNote.actionAtBeat(10), AutoModeBeatAction.accentAndNote);
    });
  });
}
