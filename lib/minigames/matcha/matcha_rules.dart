import '../../balance/balance.dart';
import '../common/grade.dart';

/// Reglas del Matcha, en Dart puro para poder probarlas.
///
/// Se bate en zigzag: cada cambio de dirección es una batida. La partida tiene
/// tramos con un ritmo ideal (batidas por segundo); cada batida vale según qué
/// tan cerca del ritmo cayó y si fue lo bastante amplia. La espuma es la suma
/// de lo que valieron las batidas sobre las que pedía la partida.
class MatchaRules {
  final BalanceSection b;
  MatchaRules(this.b);

  /// Ritmo ideal de cada tramo (batidas por segundo).
  List<double> get tempos => b.list('tempos');
  double get phaseSeconds => b.d('phaseSeconds');
  double get duration => phaseSeconds * tempos.length;

  /// Ritmo ideal en el segundo [t] de la partida.
  double tempoAt(double t) => tempos[(t / phaseSeconds).floor().clamp(0, tempos.length - 1)];

  /// Batidas que pide la partida entera.
  double get expected => tempos.fold(0.0, (a, v) => a + v * phaseSeconds);

  /// Cuánto vale una batida que llegó [interval] segundos después de la
  /// anterior, con [amplitude] (fracción del ancho del cuenco) de recorrido.
  double strokeValue(double interval, double amplitude, double tempo) {
    if (interval <= 0) return 0;
    final rate = 1 / interval;
    final rhythm = (1 - (rate - tempo).abs() / (tempo * b.d('tolerance'))).clamp(0.0, 1.0);
    final reach = amplitude >= b.d('minAmplitude') ? 1.0 : b.d('weakStroke');
    return rhythm * reach;
  }

  /// Espuma (0 a 1) con la suma de lo que valieron las batidas.
  double foam(double sum) => (sum / (expected * b.d('perfectShare'))).clamp(0.0, 1.0);

  Grade? grade(double value) => value >= 0.85
      ? Grade.perfect
      : value >= 0.6
      ? Grade.great
      : value >= 0.35
      ? Grade.good
      : null;
}

/// Sigue el batidor y avisa cada vez que cambia de dirección (una batida).
class WhiskTracker {
  /// Píxeles que tiene que volver para contar el cambio de dirección.
  final double slack;
  WhiskTracker({this.slack = 6});

  double _dir = 0, _extreme = 0, _turnX = 0;
  double? _turnT;

  /// Apoyó el dedo en [x] (en el segundo [t]).
  void start(double x, double t) {
    _dir = 0;
    _extreme = _turnX = x;
    _turnT ??= t;
  }

  /// El dedo pasó a [x] en el segundo [t]. Si con eso dio la vuelta, devuelve
  /// cuánto tardó desde la vuelta anterior y cuánto recorrió (píxeles).
  ({double interval, double reach})? move(double x, double t) {
    if (_dir == 0) {
      if ((x - _turnX).abs() > slack) {
        _dir = (x - _turnX).sign;
        _extreme = x;
      }
      return null;
    }
    if ((x - _extreme) * _dir >= 0) {
      _extreme = x;
      return null;
    }
    if ((_extreme - x).abs() <= slack) return null;
    final stroke = (interval: t - (_turnT ?? t), reach: (_extreme - _turnX).abs());
    _turnT = t;
    _turnX = _extreme;
    _extreme = x;
    _dir = -_dir;
    return stroke;
  }
}
