import 'dart:math';

/// Lo que flota en el estanque.
enum Tile { lotus, pad, stone, koi, drop }

/// Piezas especiales: una línea de 4 deja una onda (barre su fila o su
/// columna), una L o una T deja una flor abierta (barre 3x3) y una línea de 5
/// deja una luna (se lleva todas las de un tipo).
enum Power { none, rowWave, colWave, bloom, moon }

class Piece {
  /// Identidad para animar: la pieza conserva su id cuando cae.
  final int id;

  /// Null solo en la luna, que no tiene tipo.
  final Tile? tile;
  final Power power;
  const Piece(this.id, this.tile, [this.power = Power.none]);
}

/// Un paso de la resolución: qué se fue, qué especiales nacieron, qué cayó y
/// qué entró nuevo desde arriba.
class PondStep {
  final Set<int> cleared;
  final Map<int, Piece> created;
  final Map<int, int> falls; // de -> a (índices)
  final Map<int, int> spawned; // índice -> filas que cae desde arriba
  final int points;
  final int lotus;
  const PondStep(this.cleared, this.created, this.falls, this.spawned, this.points, this.lotus);
}

/// Tablero del 3 en línea, en Dart puro. Índice de celda = fila * cols + col;
/// la fila 0 es la de arriba.
class PondBoard {
  final int cols, rows;
  final Random rng;
  final List<Piece?> cells;
  int _nextId = 0;

  PondBoard(this.cols, this.rows, this.rng) : cells = List.filled(cols * rows, null) {
    for (var i = 0; i < cells.length; i++) {
      // Sin líneas hechas de entrada.
      Tile t;
      do {
        t = _randomTile();
      } while (_wouldMatch(i, t));
      cells[i] = _piece(t);
    }
    if (!hasMove()) shuffle();
  }

  /// Para los tests: un tablero con estas fichas (null = luna).
  PondBoard.fromTiles(this.cols, this.rows, this.rng, List<Tile?> tiles) : cells = List.filled(cols * rows, null) {
    for (var i = 0; i < tiles.length; i++) {
      cells[i] = tiles[i] == null ? _piece(null, Power.moon) : _piece(tiles[i]);
    }
  }

  Piece _piece(Tile? t, [Power p = Power.none]) => Piece(_nextId++, t, p);
  Tile _randomTile() => Tile.values[rng.nextInt(Tile.values.length)];

  int col(int i) => i % cols;
  int row(int i) => i ~/ cols;
  Tile? tileAt(int r, int c) => (r < 0 || c < 0 || r >= rows || c >= cols) ? null : cells[r * cols + c]?.tile;

  bool _wouldMatch(int i, Tile t) {
    final r = row(i), c = col(i);
    return (tileAt(r, c - 1) == t && tileAt(r, c - 2) == t) || (tileAt(r - 1, c) == t && tileAt(r - 2, c) == t);
  }

  bool adjacent(int a, int b) =>
      (row(a) == row(b) && (col(a) - col(b)).abs() == 1) || (col(a) == col(b) && (row(a) - row(b)).abs() == 1);

  /// Grupos de 3 o más iguales en línea. Las líneas que se cruzan (L, T) son
  /// un solo grupo.
  List<Set<int>> groups() {
    final runs = <Set<int>>[];
    for (var r = 0; r < rows; r++) {
      _runs([for (var c = 0; c < cols; c++) r * cols + c], runs);
    }
    for (var c = 0; c < cols; c++) {
      _runs([for (var r = 0; r < rows; r++) r * cols + c], runs);
    }
    // Unir las que comparten celdas.
    final merged = <Set<int>>[];
    for (final run in runs) {
      final touching = merged.where((g) => g.any(run.contains)).toList();
      final g = {...run};
      for (final t in touching) {
        g.addAll(t);
        merged.remove(t);
      }
      merged.add(g);
    }
    return merged;
  }

  void _runs(List<int> line, List<Set<int>> out) {
    var start = 0;
    for (var k = 1; k <= line.length; k++) {
      final same = k < line.length && cells[line[k]]?.tile != null && cells[line[k]]?.tile == cells[line[start]]?.tile;
      if (same) continue;
      if (k - start >= 3 && cells[line[start]]?.tile != null) out.add(line.sublist(start, k).toSet());
      start = k;
    }
  }

  void _swap(int a, int b) {
    final t = cells[a];
    cells[a] = cells[b];
    cells[b] = t;
  }

  /// Intenta cambiar [a] y [b]. Vale si arma una línea o si una es la luna.
  /// Si no vale, el tablero queda como estaba.
  bool trySwap(int a, int b) {
    if (!adjacent(a, b)) return false;
    _swap(a, b);
    if (cells[a]?.power == Power.moon || cells[b]?.power == Power.moon || groups().isNotEmpty) return true;
    _swap(a, b);
    return false;
  }

  /// Hay algún cambio que arme una línea.
  bool hasMove() {
    for (var i = 0; i < cells.length; i++) {
      for (final j in [if (col(i) + 1 < cols) i + 1, if (row(i) + 1 < rows) i + cols]) {
        if (cells[i]?.power == Power.moon || cells[j]?.power == Power.moon) return true;
        _swap(i, j);
        final ok = groups().isNotEmpty;
        _swap(i, j);
        if (ok) return true;
      }
    }
    return false;
  }

  /// Mezcla las piezas hasta que no haya líneas hechas y sí haya jugada.
  void shuffle() {
    for (var tries = 0; tries < 200; tries++) {
      cells.shuffle(rng);
      if (groups().isEmpty && hasMove()) return;
    }
    // Muy raro: se rehace el tablero.
    for (var i = 0; i < cells.length; i++) {
      Tile t;
      do {
        t = _randomTile();
      } while (_wouldMatch(i, t));
      cells[i] = _piece(t);
    }
  }

  /// Corre la fila [r] un lugar ([dir] = 1 a la derecha); la que sale entra
  /// por el otro lado. Es la corriente del estanque.
  void drift(int r, int dir) {
    final line = [for (var c = 0; c < cols; c++) cells[r * cols + c]];
    for (var c = 0; c < cols; c++) {
      cells[r * cols + (c + dir) % cols] = line[c];
    }
  }

  /// Resuelve un paso. [moved] son las celdas del cambio (ahí nacen los
  /// especiales). [cascade] empieza en 1 y multiplica los puntos. Devuelve null
  /// si no hay nada que resolver.
  PondStep? step({Set<int> moved = const {}, int cascade = 1}) {
    final cleared = <int>{};
    final created = <int, Piece>{};
    // La luna cambiada se lleva todas las del tipo con que se cambió.
    final moons = moved.where((i) => cells[i]?.power == Power.moon).toList();
    if (moons.isNotEmpty && cascade == 1) {
      final moon = moons.first;
      final other = moved.firstWhere((i) => i != moon, orElse: () => moon);
      final t = cells[other]?.tile ?? _randomTile();
      cleared.add(moon);
      for (var i = 0; i < cells.length; i++) {
        if (cells[i]?.tile == t) cleared.add(i);
      }
    }
    for (final g in groups()) {
      final rowsIn = g.map(row).toSet(), colsIn = g.map(col).toSet();
      final t = cells[g.first]!.tile;
      final longest = max(_longestLine(g, true), _longestLine(g, false));
      Power? power;
      if (longest >= 5) {
        power = Power.moon;
      } else if (rowsIn.length >= 3 && colsIn.length >= 3) {
        power = Power.bloom;
      } else if (longest == 4) {
        power = rowsIn.length == 1 ? Power.rowWave : Power.colWave;
      }
      cleared.addAll(g);
      if (power != null) {
        final at = g.firstWhere(moved.contains, orElse: () => (g.toList()..sort())[g.length ~/ 2]);
        created[at] = _piece(power == Power.moon ? null : t, power);
      }
    }
    if (cleared.isEmpty) return null;
    // Los especiales que se van disparan su efecto (en cadena).
    final queue = [...cleared];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      final p = cells[i];
      if (p == null || p.power == Power.none) continue;
      final hit = <int>[];
      switch (p.power) {
        case Power.rowWave:
          hit.addAll([for (var c = 0; c < cols; c++) row(i) * cols + c]);
        case Power.colWave:
          hit.addAll([for (var r = 0; r < rows; r++) r * cols + col(i)]);
        case Power.bloom:
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              final r = row(i) + dr, c = col(i) + dc;
              if (r >= 0 && c >= 0 && r < rows && c < cols) hit.add(r * cols + c);
            }
          }
        case Power.moon:
          if (!moons.contains(i)) {
            final t = _randomTile();
            for (var k = 0; k < cells.length; k++) {
              if (cells[k]?.tile == t) hit.add(k);
            }
          }
        case Power.none:
      }
      for (final h in hit) {
        if (cleared.add(h)) queue.add(h);
      }
    }
    created.removeWhere((i, _) => !cleared.contains(i));
    var lotus = 0;
    for (final i in cleared) {
      if (cells[i]?.tile == Tile.lotus && !created.containsKey(i)) lotus++;
    }
    final points = (cleared.length - created.length) * 10 * cascade;
    for (final i in cleared) {
      cells[i] = created[i];
    }
    // Gravedad y piezas nuevas desde arriba.
    final falls = <int, int>{};
    final spawned = <int, int>{};
    for (var c = 0; c < cols; c++) {
      var write = rows - 1;
      for (var r = rows - 1; r >= 0; r--) {
        final i = r * cols + c;
        if (cells[i] == null) continue;
        final to = write * cols + c;
        if (to != i) {
          cells[to] = cells[i];
          cells[i] = null;
          falls[i] = to;
        }
        write--;
      }
      final missing = write + 1;
      for (var r = write; r >= 0; r--) {
        final i = r * cols + c;
        cells[i] = _piece(_randomTile());
        spawned[i] = missing;
      }
    }
    return PondStep(cleared, created, falls, spawned, points, lotus);
  }

  int _longestLine(Set<int> g, bool horizontal) {
    var best = 0;
    for (final i in g) {
      var n = 1;
      var k = i;
      while (true) {
        final next = horizontal ? k + 1 : k + cols;
        if (!g.contains(next) || (horizontal && row(next) != row(k))) break;
        n++;
        k = next;
      }
      best = max(best, n);
    }
    return best;
  }
}
