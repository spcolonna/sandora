import 'dart:math';

import '../balance/balance.dart';
import 'weather.dart';

/// Lo que el jardín pide mientras uno no está: maleza que crece, hojas que
/// trae el viento, la arena borrada por la lluvia y lo que tira una tormenta.
enum CareKind {
  /// Se arranca deslizando hacia arriba.
  weed,

  /// Se barre pasando el dedo.
  leaves,

  /// El dibujo del arenero quedó borrado por la lluvia: se rastrilla con el dedo.
  sand,

  /// Una piedra que se cayó de la torre: se toca y vuelve.
  stone,

  /// Una vasija volcada: se toca y se endereza.
  jar,

  /// Una decoración tumbada: se toca y se levanta.
  decor,
}

/// Un cuidado pendiente. [x] e [y] son fracciones de la vista [side] (los
/// que van en un lugar, como la arena o la vasija, se ubican con el lugar).
/// [decor] es el índice de la decoración tumbada; en las piedras, [x] es su
/// lugar al pie de la torre (0, 1, 2).
class CareTask {
  final int id;
  final CareKind kind;
  final int side;
  final double x, y;
  final int? decor;

  const CareTask(this.id, this.kind, {this.side = 0, this.x = 0.5, this.y = 0.8, this.decor});

  List<Object?> toJson() => [id, kind.index, side, (x * 1000).round(), (y * 1000).round(), decor];

  factory CareTask.fromJson(List<dynamic> j) => CareTask(
    j[0] as int,
    CareKind.values[j[1] as int],
    side: j[2] as int,
    x: (j[3] as num) / 1000,
    y: (j[4] as num) / 1000,
    decor: j[5] as int?,
  );
}

/// Qué dejó lo que pasó mientras no se miraba el jardín (para avisarlo).
enum CareNews { none, grew, storm }

/// Reglas de los cuidados. Dart puro: el clima de cada momento llega como
/// función, así se prueba sin reloj ni red.
class CareRules {
  final BalanceSection b;
  CareRules(Balance balance) : b = balance.section('care');

  double get weedEveryHours => b.d('weedEveryHours');
  int get maxWeeds => b.i('maxWeeds');
  int get maxLeaves => b.i('maxLeaves');
  int get maxStones => b.i('maxStones');
  int get maxDecor => b.i('maxDecor');
  int get maxTasks => b.i('maxTasks');
  int get serenityPerFix => b.i('serenityPerFix');
  int get pebblesPerFix => b.i('pebblesPerFix');
  int get rewardedPerDay => b.i('rewardedPerDay');

  /// Cuánto más rápido baja la serenidad por día con cada cuidado pendiente.
  double get decayPerTask => b.d('decayPerTask');

  /// Lo que apareció entre [from] y [to] además de [have]: [weeds] matas de
  /// maleza (ver [weedsSince]) y lo que trajo el clima, recorriendo el tiempo
  /// de a [blockHours] horas, cada bloque con el suyo. [decorPlaced]
  /// son los índices de las decoraciones puestas; [hasDrawing], si el arenero
  /// tiene un dibujo que la lluvia pueda borrar.
  (List<CareTask>, CareNews) spawn({
    required DateTime from,
    required DateTime to,
    required List<CareTask> have,
    int weeds = 0,
    required Weather Function(DateTime) weatherAt,
    required bool Function(Weather, DateTime) windy,
    required int blockHours,
    required List<int> decorPlaced,
    required bool hasDrawing,
    int sides = 3,
  }) {
    if (!to.isAfter(from) && weeds == 0) return (const [], CareNews.none);
    final rng = Random(from.millisecondsSinceEpoch ~/ 60000 * 7 + to.millisecondsSinceEpoch ~/ 60000);
    final out = <CareTask>[];
    var nextId = [for (final t in have) t.id].fold(0, max) + 1;
    int count(CareKind k) => have.where((t) => t.kind == k).length + out.where((t) => t.kind == k).length;
    bool room() => have.length + out.length < maxTasks;
    var news = CareNews.none;

    void add(CareKind kind, {int side = 0, double? x, double? y, int? decor}) {
      out.add(
        CareTask(
          nextId++,
          kind,
          side: side,
          x: x ?? 0.12 + rng.nextDouble() * 0.76,
          y: y ?? 0.74 + rng.nextDouble() * 0.2,
          decor: decor,
        ),
      );
    }

    // Maleza, hasta el tope, repartida en las vistas.
    for (var i = min(weeds, maxWeeds - count(CareKind.weed)); i > 0 && room(); i--) {
      add(CareKind.weed, side: rng.nextInt(sides));
      news = CareNews.grew;
    }

    // El clima de cada bloque que pasó.
    final step = Duration(hours: blockHours);
    for (var t = from; t.isBefore(to) && room(); t = t.add(step)) {
      final w = weatherAt(t);
      if (w.wet || w == Weather.snow) {
        if (hasDrawing && count(CareKind.sand) == 0) add(CareKind.sand);
      }
      if (windy(w, t) || w == Weather.storm) {
        if (count(CareKind.leaves) < maxLeaves && room()) {
          add(CareKind.leaves, side: rng.nextInt(sides));
          if (news == CareNews.none) news = CareNews.grew;
        }
      }
      if (w == Weather.storm) {
        news = CareNews.storm;
        final stones = min(1 + rng.nextInt(3), maxStones - count(CareKind.stone));
        for (var i = 0; i < stones && room(); i++) {
          add(CareKind.stone, x: count(CareKind.stone).toDouble(), y: 0);
        }
        if (count(CareKind.jar) == 0 && room() && rng.nextBool()) add(CareKind.jar);
        final standing = [
          for (final d in decorPlaced)
            if (!have.any((t) => t.decor == d) && !out.any((t) => t.decor == d)) d,
        ];
        if (standing.isNotEmpty && count(CareKind.decor) < maxDecor && room() && rng.nextBool()) {
          add(CareKind.decor, decor: standing[rng.nextInt(standing.length)]);
        }
      }
    }
    return (out, out.isEmpty ? CareNews.none : news);
  }

  /// Cuántas matas de maleza crecieron desde [since] hasta [now].
  int weedsSince(DateTime since, DateTime now) => (now.difference(since).inMinutes / 60 / weedEveryHours).floor();
}
