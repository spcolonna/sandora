import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../settings.dart';

/// Efectos (placeholders de `tool/gen_placeholder_audio.py`). Los que tienen
/// variantes se alternan al azar; además cada golpe varía un poco el volumen
/// para que no suene repetido (GDD, Audio).
enum Sfx {
  stackPlace('sfx_stack_place', 3),
  stackFall('sfx_stack_fall', 1),
  rainNote('sfx_rain_note', 5),
  uiTap('sfx_ui_tap', 1),
  good('sfx_ui_good', 1),
  great('sfx_ui_great', 1),
  perfect('sfx_ui_perfect', 1),
  catMeow('sfx_cat_meow', 1),
  fluteNote('sfx_flute_note', 4),
  bell('sfx_meditation_bell', 1);

  final String file;
  final int variants;
  const Sfx(this.file, this.variants);
}

/// Capas de ambiente en loop.
enum Ambience {
  wind('sfx_base_wind'),
  rain('sfx_rain_ambient'),
  rake('sfx_sand_rake');

  /// Ambientes que se pueden elegir para meditar.
  static const forMeditation = [wind, rain];

  final String file;
  const Ambience(this.file);
}

class SoundBoard {
  SoundBoard._();
  static final instance = SoundBoard._();

  final _pools = <String, List<_Voice>>{};
  final _loops = <Ambience, AudioPlayer>{};
  final _rng = Random();
  bool _ready = false;
  bool _hidden = false;
  AppLifecycleListener? _lifecycle;

  /// Reproductores por sonido: hasta 3 golpes iguales superpuestos.
  static const voices = 3;

  Future<void> init() async {
    if (_ready) return;
    try {
      // Se mezcla con la música del usuario y respeta el modo silencio en iOS.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build().copy(iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient)),
      );
      for (final s in Sfx.values) {
        for (var i = 1; i <= s.variants; i++) {
          final name = _name(s, i);
          _pools[name] = [for (var v = 0; v < voices; v++) await _Voice.load('audio/$name.m4a')];
        }
      }
      for (final a in Ambience.values) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setSource(AssetSource('audio/${a.file}.m4a'));
        _loops[a] = p;
      }
      _lifecycle ??= AppLifecycleListener(
        onHide: () {
          _hidden = true;
          for (final p in _loops.values) {
            p.pause();
          }
        },
        onShow: () => _hidden = false,
      );
      _ready = true;
    } catch (e) {
      debugPrint('Audio no disponible: $e');
    }
  }

  static String _name(Sfx s, int i) => s.variants > 1 ? '${s.file}_${i.toString().padLeft(2, '0')}' : s.file;

  /// Toca [s]. [variant] (1..variants) elige una nota fija, por ejemplo la de
  /// cada vasija; si no, se elige al azar.
  void play(Sfx s, {double volume = 1, int? variant}) {
    if (!_ready || _hidden || !AppSettings.instance.sound) return;
    final name = _name(s, variant ?? 1 + _rng.nextInt(s.variants));
    final v = (volume * (0.88 + _rng.nextDouble() * 0.12)).clamp(0.0, 1.0);
    final pool = _pools[name];
    if (pool == null) return;
    final voice = pool.where((x) => !x.busy).fold<_Voice?>(null, (a, x) => a == null || x.used < a.used ? x : a);
    voice?.play(v).ignore();
  }

  final _fades = <Ambience, Timer>{};

  /// Arranca un ambiente subiendo el volumen de a poco: nada entra de golpe.
  void loop(Ambience a, {double volume = 0.5, Duration fade = const Duration(milliseconds: 1200)}) {
    if (!_ready || !AppSettings.instance.music) return;
    final p = _loops[a]!;
    if (p.state != PlayerState.playing) {
      p.setVolume(0);
      p.resume();
    }
    _fadeTo(a, volume, fade);
  }

  /// Baja el ambiente hasta el silencio y recién ahí lo pausa.
  void stopLoop(Ambience a, {Duration fade = const Duration(milliseconds: 800)}) {
    if (!_ready) return;
    _fadeTo(a, 0, fade, then: () => _loops[a]!.pause());
  }

  void stopAllLoops({Duration fade = const Duration(milliseconds: 800)}) {
    for (final a in Ambience.values) {
      stopLoop(a, fade: fade);
    }
  }

  void _fadeTo(Ambience a, double target, Duration fade, {VoidCallback? then}) {
    final p = _loops[a]!;
    _fades.remove(a)?.cancel();
    final from = p.volume;
    const step = Duration(milliseconds: 50);
    final steps = max(1, fade.inMilliseconds ~/ step.inMilliseconds);
    var i = 0;
    _fades[a] = Timer.periodic(step, (t) {
      i++;
      // Curva suave (coseno): sin escalones audibles al principio ni al final.
      final k = 0.5 - cos(pi * i / steps) / 2;
      p.setVolume(from + (target - from) * k);
      if (i >= steps) {
        t.cancel();
        _fades.remove(a);
        then?.call();
      }
    });
  }
}

/// Un reproductor precargado. Un golpe que llega tarde se descarta: un efecto
/// fuera de tiempo es peor que ninguno.
class _Voice {
  final AudioPlayer player;
  _Voice(this.player);

  static const late = Duration(milliseconds: 250);

  bool busy = false;
  int used = 0;

  static Future<_Voice> load(String path) async {
    final p = AudioPlayer();
    await p.setReleaseMode(ReleaseMode.stop);
    await p.setPlayerMode(PlayerMode.lowLatency);
    await p.setSource(AssetSource(path));
    return _Voice(p);
  }

  Future<void> play(double volume) async {
    busy = true;
    used = DateTime.now().microsecondsSinceEpoch;
    final asked = Stopwatch()..start();
    try {
      await player.stop();
      if (asked.elapsed > late) return;
      await player.setVolume(volume);
      if (asked.elapsed > late) return;
      await player.resume();
      if (asked.elapsed > late) await player.stop();
    } catch (_) {
      // Sin audio no se juega peor.
    } finally {
      busy = false;
    }
  }
}

/// Vibraciones, en tres niveles como la celebración (GDD, pilar 5), todas
/// livianas (pilar 8: nada es brusco). Nunca se usan los golpes pesados.
class Haptics {
  static bool get _on => AppSettings.instance.haptics;
  static DateTime _last = DateTime(0);

  /// Evita que varios golpes seguidos (una piedra que rebota) se sientan como
  /// un zumbido.
  static bool _ready() {
    if (!_on) return false;
    final now = DateTime.now();
    if (now.difference(_last) < const Duration(milliseconds: 90)) return false;
    _last = now;
    return true;
  }

  /// Un roce: piedras que se apoyan, toques de interfaz.
  static void light() {
    if (_ready()) HapticFeedback.selectionClick();
  }

  /// Un golpe suave: "genial", juntar piedritas, una caída.
  static void medium() {
    if (_ready()) HapticFeedback.lightImpact();
  }

  /// Dos golpes suaves y espaciados, como un latido: "perfecto", subir de nivel.
  static void perfect() {
    if (!_ready()) return;
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 160), HapticFeedback.selectionClick);
  }
}
