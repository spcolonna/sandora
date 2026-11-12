import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Los minijuegos pintan y reciben toques en coordenadas de pantalla; el mundo
/// de Flame (donde van los avisos y las lucecitas) tiene que usar las mismas.
/// Con el ancla centrada que trae Flame todo salía corrido medio ancho y medio
/// alto. Se fija al montar: antes el juego todavía no tiene tamaño.
mixin ScreenSpace on FlameGame {
  @override
  void onMount() {
    camera.viewfinder.anchor = Anchor.topLeft;
    super.onMount();
  }
}
