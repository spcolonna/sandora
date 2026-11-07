part of 'garden_view.dart';

/// Una parada del paseo: dónde mirar y qué es.
typedef _WalkStop = ({Rect at, String name, String kind});

/// El paseo en primera persona: la cámara entra caminando desde adelante y se
/// para en cada lugar y decoración de la vista, del más cercano al del fondo.
extension _GardenWalk on _GardenViewState {
  /// Lo que se visita en esta vista, de adelante hacia el fondo. Los lugares
  /// muy anchos (el río) se miran por su centro.
  List<_WalkStop> _walkStops() {
    final layout = _layout;
    if (layout == null) return const [];
    final p = Progress.instance;
    final stops = <_WalkStop>[
      for (final e in layout.places.entries) (at: e.value, name: _Label.nameOf(e.key), kind: tr('walk.place')),
      for (final e in _decorRects.entries)
        if (e.key < p.decor.length) (at: e.value, name: tr('decor.${p.decor[e.key].id}'), kind: tr('walk.decor')),
    ];
    stops.sort((a, b) => b.at.bottom.compareTo(a.at.bottom));
    return stops;
  }

  Future<void> _startWalk(int id) async {
    if (!mounted) return;
    _walking = id;
    bool on() => mounted && _walking == id;
    final stops = _walkStops();
    // Primero se ve la vista entera un momento, como al llegar.
    if (_zoom > 1.01) await _glide(1, Offset.zero, ms: 900);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    Offset? last;
    for (final s in stops) {
      if (!on()) return;
      final z = (_box.width * 0.5 / max(s.at.width, 1)).clamp(1.5, 2.5);
      final c = (s.at.center + _stageOrigin) * z;
      // A la altura de los ojos: lo que se mira queda un poco abajo del centro.
      final target = Offset(_box.width / 2, _box.height * 0.55) - c;
      final far = last == null ? 1.0 : ((s.at.center - last).distance / _box.width).clamp(0.3, 1.0);
      last = s.at.center;
      widget.onWalkStop?.call(s.name, s.kind);
      await _glide(z, target, ms: (2400 * far).round() + 600, steps: (6 * far).round() + 2);
      if (!on()) return;
      await Future<void>.delayed(const Duration(milliseconds: 1700));
    }
    if (!on()) return;
    // Se aleja para ver todo antes de pasar a la vista siguiente.
    await _glide(1, Offset.zero, ms: 1400);
    if (!on()) return;
    _walking = null;
    widget.onWalkDone?.call();
  }

  void _stopWalk() {
    if (_walking == null) return;
    _walking = null;
    if (mounted) _glide(1, Offset.zero, ms: 700);
  }
}
