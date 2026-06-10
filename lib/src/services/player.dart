import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:dart_melty_soundfont/synthesizer.dart';
import 'package:dart_melty_soundfont/synthesizer_settings.dart';
import 'package:dart_melty_soundfont/audio_renderer_ex.dart';
import 'package:dart_melty_soundfont/array_int16.dart';

import 'audio/pcm_audio_player.dart';

@lazySingleton
class PlayerService {
  Synthesizer? _synth;
  late final PcmAudioPlayer _audioPlayer;
  bool _isInitialized = false;

  Int16List? _clickPcmData;
  int _clickPlaybackIndex = -1;
  double _clickVolumeMultiplier = 1.0;

  PlayerService() {
    _init();
  }

  Future<void> _init() async {
    _audioPlayer = PcmAudioPlayer();
    await _audioPlayer.setup(sampleRate: 44100, channelCount: 1);
    _audioPlayer.setFeedCallback(_onFeed);

    await _loadClickWav();

    ByteData bytes = await rootBundle.load('assets/sounds/Piano.sf2');
    _synth = Synthesizer.loadByteData(bytes, SynthesizerSettings());

    _isInitialized = true;
  }

  Future<void> _loadClickWav() async {
    try {
      ByteData bytes = await rootBundle.load('assets/sounds/Click48_24.wav');
      Uint8List uint8list = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);

      int offset = 12;
      int numChannels = 0;
      int sampleRate = 0;
      int bitsPerSample = 0;
      int audioFormat = 0;
      int dataOffset = 0;
      int dataSize = 0;

      while (offset < uint8list.length - 8) {
        String chunkId = String.fromCharCodes(uint8list.sublist(offset, offset + 4));
        int chunkSize = bytes.getUint32(offset + 4, Endian.little);

        if (chunkId == 'fmt ') {
          audioFormat = bytes.getUint16(offset + 8, Endian.little);
          numChannels = bytes.getUint16(offset + 10, Endian.little);
          sampleRate = bytes.getUint32(offset + 12, Endian.little);
          bitsPerSample = bytes.getUint16(offset + 22, Endian.little);
        } else if (chunkId == 'data') {
          dataOffset = offset + 8;
          dataSize = chunkSize;
        }
        offset += 8 + chunkSize;
        if (chunkSize % 2 != 0) {
          offset += 1;
        }
      }

      if (dataOffset == 0 || numChannels == 0 || sampleRate == 0 || bitsPerSample == 0) {
        throw Exception("Invalid WAV header or unsupported format");
      }

      int bytesPerSample = bitsPerSample ~/ 8;
      int totalSamples = dataSize ~/ (numChannels * bytesPerSample);

      double getSampleValue(int byteOffset) {
        if (bitsPerSample == 16) {
          int val = bytes.getInt16(byteOffset, Endian.little);
          return val / 32768.0;
        } else if (bitsPerSample == 24) {
          int b0 = uint8list[byteOffset];
          int b1 = uint8list[byteOffset + 1];
          int b2 = uint8list[byteOffset + 2];
          int val = (b2 << 16) | (b1 << 8) | b0;
          if (val >= 0x800000) {
            val -= 0x1000000;
          }
          return val / 8388608.0;
        } else if (bitsPerSample == 32) {
          if (audioFormat == 3) {
            return bytes.getFloat32(byteOffset, Endian.little);
          } else {
            int val = bytes.getInt32(byteOffset, Endian.little);
            return val / 2147483648.0;
          }
        }
        return 0.0;
      }

      // 1. Downmix to Mono (at original sample rate)
      List<double> monoSamples = List<double>.filled(totalSamples, 0.0);
      int frameSize = numChannels * bytesPerSample;
      for (int i = 0; i < totalSamples; i++) {
        double sum = 0.0;
        for (int ch = 0; ch < numChannels; ch++) {
          int sampleByteOffset = dataOffset + i * frameSize + ch * bytesPerSample;
          sum += getSampleValue(sampleByteOffset);
        }
        monoSamples[i] = sum / numChannels;
      }

      // 2. Resample to 44100 Hz
      int targetSampleRate = 44100;
      if (sampleRate == targetSampleRate) {
        _clickPcmData = Int16List(totalSamples);
        for (int i = 0; i < totalSamples; i++) {
          _clickPcmData![i] = (monoSamples[i] * 32767.0).round().clamp(-32768, 32767);
        }
      } else {
        double resampleRatio = sampleRate / targetSampleRate;
        int mono44kLength = (totalSamples / resampleRatio).floor();
        _clickPcmData = Int16List(mono44kLength);

        for (int j = 0; j < mono44kLength; j++) {
          double inputIndex = j * resampleRatio;
          int index1 = inputIndex.floor();
          int index2 = index1 + 1;
          double t = inputIndex - index1;

          if (index2 >= totalSamples) {
            index2 = index1;
          }

          double sample1 = monoSamples[index1];
          double sample2 = monoSamples[index2];
          double interpolated = sample1 + (sample2 - sample1) * t;

          _clickPcmData![j] = (interpolated * 32767.0).round().clamp(-32768, 32767);
        }
      }
    } catch (e, stack) {
      print("Failed to load or parse click WAV: $e");
      print(stack);
    }
  }

  void _onFeed(int framesToRender) async {
    if (_synth == null) return;
    
    int frames = framesToRender > 0 ? framesToRender : 2048;
    ArrayInt16 buffer = ArrayInt16.zeros(numShorts: frames);
    _synth!.renderMonoInt16(buffer);

    if (_clickPlaybackIndex >= 0 && _clickPcmData != null) {
      for (int i = 0; i < frames; i++) {
        if (_clickPlaybackIndex >= _clickPcmData!.length) {
          _clickPlaybackIndex = -1;
          break;
        }
        int synthSample = buffer.bytes.getInt16(i * 2, Endian.little);
        int clickSample = _clickPcmData![_clickPlaybackIndex];
        int mixed = (synthSample + clickSample * _clickVolumeMultiplier).round();
        buffer.bytes.setInt16(i * 2, mixed.clamp(-32768, 32767), Endian.little);
        _clickPlaybackIndex++;
      }
    }

    await _audioPlayer.feed(buffer);
  }

  Future<void> playClick({required bool accent}) async {
    _clickVolumeMultiplier = accent ? 1.0 : 0.4;
    _clickPlaybackIndex = 0;
    _audioPlayer.play();
  }

  Future<void> play(int midi, {bool sustain = false}) async {
    if (!_isInitialized || _synth == null) return;
    
    _synth!.processMidiMessage(channel: 0, command: 0xB0, data1: 64, data2: sustain ? 127 : 0);
    _synth!.noteOn(channel: 0, key: midi, velocity: 100);

    _audioPlayer.play();
  }

  Future<void> stop(int midi, {bool sustain = false}) async {
    if (!_isInitialized || _synth == null) return;
    
    _synth!.processMidiMessage(channel: 0, command: 0xB0, data1: 64, data2: sustain ? 127 : 0);
    _synth!.noteOff(channel: 0, key: midi);
  }

  Future<void> stopSustain() async {
    if (!_isInitialized || _synth == null) return;
    _synth!.processMidiMessage(channel: 0, command: 0xB0, data1: 64, data2: 0);
    _synth!.noteOffAll();
  }
}
