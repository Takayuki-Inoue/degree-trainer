import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../src/services/settings.dart';
import '../../src/services/injection.dart';
import '../widgets/locale.dart';
import '../widgets/piano_view.dart';
import '../hooks/use_octave.dart';
import '../hooks/use_velocity.dart';
import '../hooks/use_sustain.dart';
import '../hooks/use_player.dart';
import '../hooks/use_piano_keyboard.dart';
import '../hooks/use_chord_recognition.dart';
import '../hooks/use_auto_mode.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = getIt<SettingsService>();
    final splitKeyboard = useListenableSelector(
      settingsService.splitKeyboard,
      () => settingsService.splitKeyboard.value,
    );

    final focusNode = useFocusNode();
    final octave = useOctave();
    final velocity = useVelocity();
    final sustain = useSustain();
    final player = usePlayer(sustain: sustain.value);
    final chord = useChordRecognition();
    final autoMode = useAutoMode(player: player);

    final onKeyEvent = usePianoKeyboard(
      octave: octave,
      velocity: velocity,
      sustain: sustain,
      player: player,
      onNoteOn: chord.onNoteOn,
      onNoteOff: chord.onNoteOff,
    );

    const nOctaves = 7;

    final onPlay = useCallback((int midi) {
      if (!focusNode.hasFocus) {
        focusNode.requestFocus();
      }
      chord.onNoteOn(midi);
      player.play(midi);
    }, [chord, player, focusNode]);

    final onStop = useCallback((int midi) {
      chord.onNoteOff(midi);
      player.stop(midi);
    }, [chord, player]);

    final shadTheme = ShadTheme.of(context);

    return LayoutBuilder(builder: (context, dimens) {
      final canSplit = dimens.maxHeight > 600;
      final showControls = dimens.maxWidth > 550;
      final isLandscape =
          dimens.maxWidth > dimens.maxHeight || dimens.minWidth > 500;

      return Focus(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: onKeyEvent,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(context.locale.title),
                if (isLandscape && chord.chord.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: shadTheme.colorScheme.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chord.chord,
                      style: shadTheme.textTheme.small.copyWith(
                        color: shadTheme.colorScheme.accentForeground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (showControls) ...[
                ShadIconButton(
                  onPressed: () => octave.adjust(-1),
                  icon: const Icon(LucideIcons.minus),
                ),
                const SizedBox(width: 4),
                ShadIconButton.outline(
                  onPressed: octave.reset,
                  icon: Text(
                    octave.offset.toString(),
                  ),
                ),
                const SizedBox(width: 4),
                ShadIconButton(
                  onPressed: () => octave.adjust(1),
                  icon: const Icon(LucideIcons.plus),
                ),
                const SizedBox(width: 10),
              ],
              Text('${context.locale.sustain}:'),
              ShadSwitch(
                value: sustain.value,
                onChanged: sustain.setSustain,
              ),
              if (canSplit) ...[
                ShadIconButton.ghost(
                  onPressed: () async {
                    settingsService.splitKeyboard.value = !splitKeyboard;
                  },
                  icon: Icon(!splitKeyboard
                      ? LucideIcons.layoutPanelTop
                      : LucideIcons.maximize),
                ),
              ],
              autoMode.isActive
                  ? ShadButton(
                      onPressed: autoMode.toggle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.square, size: 16),
                          const SizedBox(width: 8),
                          Text(context.locale.autoMode),
                        ],
                      ),
                    )
                  : ShadButton.outline(
                      onPressed: autoMode.toggle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.play, size: 16),
                          const SizedBox(width: 8),
                          Text(context.locale.autoMode),
                        ],
                      ),
                    ),
              ShadIconButton.ghost(
                onPressed: () => context.push('/settings'),
                icon: const Icon(LucideIcons.settings),
              ),
            ],
          ),
          backgroundColor: ShadTheme.of(context).colorScheme.background,
          body: Column(
            children: [
              if (autoMode.displayLabel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    autoMode.displayLabel!,
                    style: shadTheme.textTheme.h1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: shadTheme.colorScheme.primary,
                    ),
                  ),
                ),
              Expanded(
                child: Builder(builder: (context) {
                  if (canSplit && splitKeyboard) {
                    return Column(
                      children: [
                        Flexible(
                          child: PianoView(
                            octaves: nOctaves,
                            onPlay: onPlay,
                            onStop: onStop,
                            settings: settingsService,
                          ),
                        ),
                        Flexible(
                          child: PianoView(
                            octaves: nOctaves,
                            onPlay: onPlay,
                            onStop: onStop,
                            settings: settingsService,
                          ),
                        ),
                      ],
                    );
                  }
                  return PianoView(
                    octaves: nOctaves,
                    onPlay: onPlay,
                    onStop: onStop,
                    settings: settingsService,
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }
}
