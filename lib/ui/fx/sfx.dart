import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../settings.dart';

/// Efectos (síntesis procedural de `tool/gen_audio.py`). Los que tienen
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
  bell('sfx_meditation_bell', 1),
  miss('sfx_miss', 1),
  finish('sfx_finish', 1),
  bambooTok('sfx_bamboo_tok', 1),
  waterDrop('sfx_water_drop', 3),
  leafRustle('sfx_leaf_rustle', 2),
  brush('sfx_brush', 2),
  pluck('sfx_pluck', 1),
  sweep('sfx_sweep', 1),
  snip('sfx_snip', 2),
  bird('sfx_bird', 3),
  cricket('sfx_night_cricket', 1),
  // Piedra o adorno que se apoya en la arena (no contra otra piedra).
  stoneSand('sfx_stone_sand', 3),
  // Pájaros que levantan vuelo al tocar el cielo.
  wings('sfx_wings', 2),
  // Puertas corredizas de la entrada al jardín.
  gateOpen('sfx_gate_open', 1);

  final String file;
  final int variants;
  const Sfx(this.file, this.variants);
}

/// Capas de ambiente en loop.
enum Ambience {
  wind('sfx_base_wind'),
  rain('sfx_rain_ambient'),
  rake('sfx_sand_rake'),
  whisk('sfx_whisk');

  /// Ambientes que se pueden elegir para meditar.
  static const forMeditation = [wind, rain];

  /// El rastrillo y el batidor son efectos de lo que hace el jugador: siguen
  /// al interruptor de sonido, no al de música.
  bool get isEffect => this == rake || this == whisk;

  final String file;
  const Ambience(this.file);
}

class SoundBoard {
  SoundBoard._();
  static final instance = SoundBoard._();

  final _pools = <String, List<_Voice>>{};
  final _loops = <Ambience, AudioPlayer>{};
  // Dos platos: al pasar del jardín a un juego (y de vuelta) una pieza se
  // funde con la otra, sin silencio en el medio.
  final _decks = [AudioPlayer(), AudioPlayer()];
  int _deck = 0;
  AudioPlayer get _music => _decks[_deck];
  final _rng = Random();
  bool _ready = false;
  final _loaded = Completer<void>();
  bool _hidden = false;

  /// Se completa cuando el audio terminó de cargar (bien o mal). Lo que pide
  /// sonido al abrir (la música del jardín) espera esto: antes se perdía.
  Future<void> get whenReady => _loaded.future;
  AppLifecycleListener? _lifecycle;

  /// Reproductores por sonido: hasta 3 golpes iguales superpuestos.
  static const voices = 3;

  Future<void> init() async {
    if (_ready) return;
    try {
      // Suena aunque el iPhone esté en silencio (con `ambient` el juego quedaba
      // mudo y parecía no tener sonido) y se mezcla con la música del usuario.
      // Se apaga desde Ajustes.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (e) {
      debugPrint('Contexto de audio: $e');
    }
    try {
      // Cada sonido se carga por su cuenta y en paralelo: si uno falla, los
      // demás suenan igual.
      final names = [
        for (final s in Sfx.values)
          for (var i = 1; i <= s.variants; i++) _name(s, i),
      ];
      await Future.wait([
        for (final name in names)
          () async {
            try {
              _pools[name] = await Future.wait([for (var v = 0; v < voices; v++) _Voice.load('audio/$name.m4a')]);
            } catch (e) {
              debugPrint('Sin $name: $e');
            }
          }(),
      ]);
      for (final a in Ambience.values) {
        try {
          final p = AudioPlayer();
          await p.setReleaseMode(ReleaseMode.loop);
          await p.setSource(AssetSource('audio/${a.file}.m4a'));
          _loops[a] = p;
        } catch (e) {
          debugPrint('Sin ${a.file}: $e');
        }
      }
      for (final d in _decks) {
        await d.setReleaseMode(ReleaseMode.stop);
        d.onPlayerComplete.listen((_) {
          if (!_musicOn || d != _music) return;
          // En el jardín, un respiro largo entre piezas; jugando, uno corto.
          final gap = _set == garden ? Duration(seconds: 8 + _rng.nextInt(10)) : Duration(seconds: 2 + _rng.nextInt(3));
          _musicGap = Timer(gap, _nextTrack);
        });
      }
      _lifecycle ??= AppLifecycleListener(
        onHide: () {
          _hidden = true;
          for (final p in _loops.values) {
            p.pause();
          }
          for (final d in _decks) {
            if (d.state == PlayerState.playing) d.pause();
          }
        },
        onShow: () {
          _hidden = false;
          // Lo que se estaba apagando al irse no vuelve.
          for (final d in _decks) {
            if (d != _music && d.state == PlayerState.paused) d.stop();
          }
          if (!_musicOn) return;
          if (_music.state == PlayerState.paused) {
            _music.resume();
          } else if (_music.state != PlayerState.playing && !(_musicGap?.isActive ?? false)) {
            _musicGap = Timer(const Duration(seconds: 3), _nextTrack);
          }
        },
      );
      _ready = true;
      debugPrint('Audio listo: ${_pools.length} efectos, ${_loops.length} ambientes');
    } catch (e) {
      debugPrint('Audio no disponible: $e');
    }
    if (!_loaded.isCompleted) _loaded.complete();
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

  final _fades = <Object, Timer>{};

  /// Arranca un ambiente subiendo el volumen de a poco: nada entra de golpe.
  void loop(Ambience a, {double volume = 0.5, Duration fade = const Duration(milliseconds: 1200)}) {
    if (!_ready || !(a.isEffect ? AppSettings.instance.sound : AppSettings.instance.music)) return;
    final p = _loops[a];
    if (p == null) return;
    if (p.state != PlayerState.playing) {
      p.setVolume(0);
      p.resume();
    }
    _fadeTo(a, volume, fade);
  }

  final _held = <Ambience>{};

  /// Pausa los ambientes que suenan (el chorro, el rastrillo, el viento) sin
  /// olvidarlos: la pausa de un minijuego no deja sonando el agua. La música
  /// sigue.
  void holdLoops() {
    for (final MapEntry(key: a, value: p) in _loops.entries) {
      if (p.state != PlayerState.playing) continue;
      _fades.remove(a)?.cancel();
      _held.add(a);
      p.pause();
    }
  }

  /// Retoma lo que [holdLoops] pausó.
  void releaseLoops() {
    for (final a in _held) {
      if (!_hidden) _loops[a]?.resume();
    }
    _held.clear();
  }

  /// Baja el ambiente hasta el silencio y recién ahí lo pausa.
  void stopLoop(Ambience a, {Duration fade = const Duration(milliseconds: 800)}) {
    if (!_ready || _loops[a] == null) return;
    _fadeTo(a, 0, fade, then: () => _loops[a]!.pause());
  }

  /// Corta los ambientes y, si [music], también la música (al meditar). Los
  /// minijuegos dejan la música: la suya se funde con la del jardín.
  void stopAllLoops({Duration fade = const Duration(milliseconds: 800), bool music = true}) {
    _held.clear();
    for (final a in Ambience.values) {
      stopLoop(a, fade: fade);
    }
    if (music) stopMusic(fade: fade);
  }

  /// La música del jardín.
  static const garden = 'garden';

  /// Piezas de música (`tool/gen_audio.py`): terminan en silencio y se
  /// alternan, con un respiro entre una y otra. El jardín tiene dos; cada
  /// minijuego, la suya.
  static const _gardenTracks = ['music_garden_01', 'music_garden_02'];
  static const gameTracks = {
    'stack', 'sand', 'rain', 'pond', 'shishi', 'leaves', 'moss', //
    'bonsai', 'enso', 'bell', 'matcha', 'flute', 'lanterns',
  };

  /// Las piezas de [set]: un juego sin pieza propia sigue con la del jardín.
  static List<String> tracksFor(String set) => gameTracks.contains(set) ? ['music_game_$set'] : _gardenTracks;

  bool _musicOn = false;
  double _musicVolume = 0.28;
  String _set = garden;
  final _track = <String, int>{};
  Timer? _musicGap;

  /// Arranca la música de [set] (el jardín o el id de un minijuego). Si ya
  /// sonaba otra, se funden sin silencio; si es la misma, sigue.
  void music({double volume = 0.28, String set = garden}) {
    if (!_ready || !AppSettings.instance.music) return;
    _musicVolume = volume;
    if (tracksFor(set).first != tracksFor(_set).first) return _switchTo(set);
    _set = set;
    if (_musicOn) return;
    _musicOn = true;
    // Si se estaba apagando, vuelve a subir sin cortar la pieza.
    if (_music.state == PlayerState.playing) {
      _fadeTo(_music, volume, const Duration(milliseconds: 1500));
      return;
    }
    _musicGap?.cancel();
    _musicGap = Timer(const Duration(seconds: 3), _nextTrack);
  }

  static const _crossfade = Duration(milliseconds: 1800);

  /// La pieza que suena se apaga en un plato mientras la de [set] entra en el
  /// otro.
  void _switchTo(String set) {
    _set = set;
    _musicOn = true;
    _musicGap?.cancel();
    final old = _music;
    final playing = old.state == PlayerState.playing;
    if (playing) {
      _fadeTo(
        old,
        0,
        _crossfade,
        then: () {
          if (old != _music) old.stop();
        },
      );
    } else {
      old.stop();
    }
    _deck = 1 - _deck;
    _nextTrack(fadeIn: playing ? _crossfade : const Duration(milliseconds: 600));
  }

  Future<void> _nextTrack({Duration? fadeIn}) async {
    if (!_musicOn || _hidden) return;
    final p = _music, set = _set, tracks = tracksFor(set);
    final i = (_track[set] ?? 0) % tracks.length;
    _fades.remove(p)?.cancel();
    try {
      await p.play(AssetSource('audio/${tracks[i]}.m4a'), volume: fadeIn == null ? _musicVolume : 0);
      _track[set] = i + 1;
      // Si mientras cargaba se cambió de pieza o se apagó la música, esta no va.
      if (p != _music || !_musicOn || _set != set) {
        if (p != _music) p.stop();
        return;
      }
      if (fadeIn != null) _fadeTo(p, _musicVolume, fadeIn);
    } catch (_) {
      // Sin música se juega igual.
    }
  }

  /// Baja la música hasta el silencio y la detiene.
  void stopMusic({Duration fade = const Duration(milliseconds: 1500)}) {
    if (!_ready) return;
    _musicOn = false;
    _musicGap?.cancel();
    for (final d in _decks) {
      if (d.state != PlayerState.playing) continue;
      _fadeTo(
        d,
        0,
        fade,
        then: () {
          if (!_musicOn || d != _music) d.stop();
        },
      );
    }
  }

  /// [key] es un [Ambience] o uno de los platos de música.
  void _fadeTo(Object key, double target, Duration fade, {VoidCallback? then}) {
    final p = key is Ambience ? _loops[key]! : key as AudioPlayer;
    _fades.remove(key)?.cancel();
    final from = p.volume;
    const step = Duration(milliseconds: 50);
    final steps = max(1, fade.inMilliseconds ~/ step.inMilliseconds);
    var i = 0;
    _fades[key] = Timer.periodic(step, (t) {
      i++;
      // Curva suave (coseno): sin escalones audibles al principio ni al final.
      final k = 0.5 - cos(pi * i / steps) / 2;
      p.setVolume(from + (target - from) * k);
      if (i >= steps) {
        t.cancel();
        _fades.remove(key);
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
  static int _lastLevel = 0;

  /// Evita que varios golpes seguidos (una piedra que rebota) se sientan como
  /// un zumbido. Un golpe más fuerte que el anterior pasa igual: el roce del
  /// botón no tapa el festejo que dispara.
  static bool _ready(int level) {
    if (!_on) return false;
    final now = DateTime.now();
    if (now.difference(_last) < const Duration(milliseconds: 90) && level <= _lastLevel) return false;
    _last = now;
    _lastLevel = level;
    return true;
  }

  /// Un roce: piedras que se apoyan, toques de interfaz.
  static void light() {
    if (_ready(0)) HapticFeedback.selectionClick();
  }

  /// Un golpe suave: "genial", juntar piedritas, una caída.
  static void medium() {
    if (_ready(1)) HapticFeedback.lightImpact();
  }

  /// Dos golpes suaves y espaciados, como un latido: "perfecto", subir de nivel.
  static void perfect() {
    if (!_ready(2)) return;
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 160), HapticFeedback.selectionClick);
  }
}
