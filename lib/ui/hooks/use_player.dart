import '../../src/services/player.dart';
import '../../src/services/injection.dart';

class PianoPlayer {
  final PlayerService service;
  final bool globalSustain;

  PianoPlayer({required this.service, required this.globalSustain});

  Future<void> play(int midi) async {
    await service.play(midi, sustain: globalSustain);
  }

  Future<void> stop(int midi) async {
    await service.stop(midi, sustain: globalSustain);
  }

  Future<void> playClick({required bool accent}) async {
    await service.playClick(accent: accent);
  }
}

PianoPlayer usePlayer({required bool sustain}) {
  final player = getIt<PlayerService>();
  return PianoPlayer(service: player, globalSustain: sustain);
}
