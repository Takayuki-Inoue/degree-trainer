import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_piano/src/models/auto_mode.dart';

void main() {
  group('AutoModeNote', () {
    test('randomMidi stays within C2 to C6', () {
      final random = Random(0);
      for (var i = 0; i < 100; i++) {
        final midi = AutoModeNote.randomMidi(random);
        expect(midi, inInclusiveRange(AutoModeNote.minMidi, AutoModeNote.maxMidi));
      }
    });

    test('beatDuration matches BPM 120', () {
      expect(AutoModeNote.beatDuration, const Duration(milliseconds: 500));
    });

    test('cyclePattern plays clicks on all beats, with a random note on first beat', () {
      expect(AutoModeNote.cyclePattern, hasLength(8));
      expect(AutoModeNote.actionAtBeat(0), AutoModeBeatAction.note);
      for (var i = 1; i < 8; i++) {
        expect(AutoModeNote.actionAtBeat(i), AutoModeBeatAction.click);
      }
      expect(AutoModeNote.actionAtBeat(8), AutoModeBeatAction.note);
    });
  });
}
