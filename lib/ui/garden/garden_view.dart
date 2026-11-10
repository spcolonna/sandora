import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../garden/day_cycle.dart';
import '../../garden/progress.dart';
import '../../garden/weather.dart';
import '../../garden/weather_service.dart';
import '../../i18n/i18n.dart';
import '../theme/palette.dart';
import '../widgets/glass.dart';
import '../widgets/washi.dart';
import 'garden_scene.dart';

part 'garden_gifts.dart';
part 'garden_moment.dart';
part 'garden_sky.dart';

/// La luz y el clima de un momento, como los usa el dibujo. Mientras un
/// clima se funde en otro, cada valor queda a mitad de camino.
class _SkyState {
  final double daylight, warmth, overcast, snow, wet, rainbow;
  final WeatherBlend blend;

  static double _overcast(Weather w) => switch (w) {
    Weather.clear => 0.0,
    Weather.cloudy => 0.45,
    Weather.fog => 0.55,
    Weather.snow => 0.6,
    Weather.rain => 0.75,
    Weather.storm => 0.95,
  };

  factory _SkyState(DateTime now) {
    final cycle = Progress.instance.dayCycle;
    final daylight = cycle.daylight(now);
    final blend = WeatherService.instance.blend(now);
    final rules = WeatherService.instance.rules;
    final stoppedAt = WeatherService.instance.rainStoppedAt(now);
    // El arcoíris se ve de día y se va apagando a medida que pasa el rato.
    final clearish = blend.amount(Weather.clear) + blend.amount(Weather.cloudy);
    final rainbow = rainbowTime(now) && clearish > 0
        ? clearish * daylight * (1 - now.difference(stoppedAt!).inSeconds / rules.rainbowFor.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    return _SkyState._(
      daylight,
      cycle.warmth(now),
      blend.mix(_overcast),
      blend.amount(Weather.snow),
      blend.mix((w) => rules.wetness(w, now, stoppedAt)),
      rainbow,
      blend,
    );
  }

  const _SkyState._(this.daylight, this.warmth, this.overcast, this.snow, this.wet, this.rainbow, this.blend);
}

/// El fondo lejano, uno solo detrás de las tres vistas: cielo, sol o luna,
/// arcoíris y lomas. Al deslizar entre vistas se corre más lento que el
/// jardín, y eso le da profundidad.
class GardenBackdrop extends StatelessWidget {
  final DateTime now;
  final Weather weather;

  /// En qué vista está el deslizamiento (0 a 2).
  final ValueListenable<double> page;
  final double top;
  const GardenBackdrop({super.key, required this.now, required this.weather, required this.page, this.top = 0});

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final sky = _SkyState(now);
    return LayoutBuilder(
      builder: (context, box) {
        final stage = gardenStage(box.biggest, top: top);
        return ValueListenableBuilder(
          valueListenable: page,
          builder: (context, drift, _) => CustomPaint(
            size: box.biggest,
            painter: _ShiftedPainter(
              stage.top,
              GardenPainter(
                layer: GardenLayer.sky,
                layout: GardenLayout(stage.size, p.patioSize),
                tower: const [],
                drawing: const [],
                meditationOpen: false,
                daylight: sky.daylight,
                warmth: sky.warmth,
                arc: p.dayCycle.arc(now),
                morning: now.hour < 12,
                overcast: sky.overcast,
                snow: sky.snow,
                rainbow: sky.rainbow,
                drift: drift,
                skyTop: -stage.top,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pinta el jardín corrido hasta donde empieza en la pantalla, en un lienzo
/// que llega hasta arriba (el cielo y el follaje siguen por encima).
class _ShiftedPainter extends CustomPainter {
  final double top;
  final GardenPainter garden;
  _ShiftedPainter(this.top, this.garden);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, top);
    garden.paint(canvas, garden.size);
  }

  @override
  bool shouldRepaint(_ShiftedPainter old) => old.top != top || garden.shouldRepaint(old.garden);
}

/// Lo vivo del cielo sobre las tres vistas (nubes, estrellas, lluvia, nieve)
/// y una viñeta suave en los bordes, como mirado a través de una lente.
class GardenSkyLife extends StatefulWidget {
  final DateTime now;
  final Weather weather;
  const GardenSkyLife({super.key, required this.now, required this.weather});

  @override
  State<GardenSkyLife> createState() => _GardenSkyLifeState();
}

class _GardenSkyLifeState extends State<GardenSkyLife> with SingleTickerProviderStateMixin {
  late final _life = AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sky = _SkyState(widget.now);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _SkyLifePainter(
                _life,
                daylight: sky.daylight,
                warmth: sky.warmth,
                blend: sky.blend,
                windy: WeatherService.instance.rules.windy(widget.weather, widget.now),
              ),
            ),
          ),
          CustomPaint(painter: _VignettePainter(1 - sky.daylight)),
        ],
      ),
    );
  }
}

/// Bordes apenas más oscuros (más de noche) y un velo de luz arriba: el ojo
/// va al centro del jardín.
class _VignettePainter extends CustomPainter {
  final double night;
  _VignettePainter(this.night);

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.1),
          radius: 0.95,
          colors: [
            Colors.transparent,
            const Color(0xFF1A1F16).withValues(alpha: 0.22 + 0.18 * night),
          ],
          stops: const [0.62, 1],
        ).createShader(Rect.fromCenter(center: all.center, width: size.width * 1.25, height: size.height)),
    );
  }

  @override
  bool shouldRepaint(_VignettePainter old) => (old.night - night).abs() > 0.01;
}

/// Si paró de llover hace poco (todavía se ve el arcoíris).
bool rainbowTime(DateTime now) {
  final ws = WeatherService.instance;
  final at = ws.rainStoppedAt(now);
  return at != null && now.difference(at) < ws.rules.rainbowFor;
}

/// Si [place] todavía no se puede usar (al tocarlo se avisa por qué).
bool placeLocked(Place place) {
  final p = Progress.instance;
  return switch (place) {
    Place.meditation => !p.meditationUnlocked,
    Place.board => false,
    _ => !p.gameUnlocked(place.name),
  };
}

/// El nombre de un lugar, como se lee en su cartelito.
String placeName(Place p) => switch (p) {
  Place.board => tr('board.title'),
  Place.meditation => tr('meditation.title'),
  Place.sand => tr('mg.sand.name'),
  Place.stack => tr('mg.stack.name'),
  Place.rain => tr('mg.rain.name'),
  Place.pond ||
  Place.shishi ||
  Place.leaves ||
  Place.moss ||
  Place.bonsai ||
  Place.enso ||
  Place.bell ||
  Place.matcha ||
  Place.flute ||
  Place.lanterns => tr('mg.${p.name}.name'),
};

/// Qué falta para abrir [place] (null si ya está abierto).
String? placeLockNote(Place place) {
  final p = Progress.instance;
  final zone = p.unlockZone(place.name);
  final (locked, why) = switch (place) {
    Place.meditation => (!p.meditationUnlocked, tr('level.short', {'n': p.levels.meditationLevel})),
    Place.board => (false, ''),
    _ when zone != null => (!p.gameUnlocked(place.name), tr('level.short', {'n': zone.level})),
    _ => (!p.gameUnlocked(place.name), tr('garden.lockedDay', {'n': p.unlockDay(place.name)})),
  };
  return locked ? why : null;
}
