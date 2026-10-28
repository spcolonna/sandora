import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../balance/balance.dart';
import 'weather.dart';

enum RealWeatherResult { ok, denied, failed }

/// El clima que ve el jardín. Si el jugador lo pide, es el de donde está
/// (ubicación aproximada + pronóstico de MET Norway); si no, o si no hay
/// conexión, el clima propio del jardín. La ubicación no se guarda.
class WeatherService extends ChangeNotifier {
  WeatherService._();
  static final instance = WeatherService._();

  static const _api = 'https://api.met.no/weatherapi/locationforecast/2.0/compact';
  // MET Norway pide identificar la app en cada pedido.
  static const _agent = 'Sandora/1.0 (com.oraki.sandora)';

  late WeatherRules rules;
  late SharedPreferences _prefs;

  /// Si el jugador eligió el clima de donde está.
  bool useReal = false;
  Weather? _real;
  DateTime? _realAt;

  /// Cuándo dejó de llover según el clima real (se guarda).
  DateTime? _realDryAt;
  bool _busy = false;

  Future<void> load(Balance balance) async {
    rules = WeatherRules(balance);
    _prefs = await SharedPreferences.getInstance();
    useReal = _prefs.getBool('weather.real') ?? false;
    _real = Weather.values.asNameMap()[_prefs.getString('weather.code')];
    final at = _prefs.getInt('weather.at');
    _realAt = at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
    final dry = _prefs.getInt('weather.dryAt');
    _realDryAt = dry == null ? null : DateTime.fromMillisecondsSinceEpoch(dry);
  }

  bool _fresh(DateTime now, Duration age) => _realAt != null && now.difference(_realAt!) < age;

  /// Si el clima de [now] es el real (y no el propio del jardín).
  bool isReal(DateTime now) => weatherOverride == null && useReal && _real != null && _fresh(now, rules.realMaxAge);

  Weather at(DateTime now) => weatherOverride ?? (isReal(now) ? _real! : rules.simulated(now));

  /// Cuándo paró de llover, si ahora no llueve (null si llueve o si no se sabe).
  /// Con eso el jardín muestra el arcoíris y los charcos que se secan.
  DateTime? rainStoppedAt(DateTime now) {
    if (afterRainOverride > 0) return now.subtract(const Duration(minutes: afterRainOverride));
    if (at(now).wet) return null;
    if (isReal(now)) return _realDryAt;
    return rules.simulatedRainStop(now);
  }

  /// Pide permiso de ubicación y trae el clima. Solo se llama cuando el
  /// jugador lo elige.
  Future<RealWeatherResult> enableReal() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return RealWeatherResult.denied;
    }
    useReal = true;
    await _prefs.setBool('weather.real', true);
    final ok = await refresh(force: true);
    notifyListeners();
    return ok ? RealWeatherResult.ok : RealWeatherResult.failed;
  }

  Future<void> disableReal() async {
    useReal = false;
    await _prefs.setBool('weather.real', false);
    notifyListeners();
  }

  /// Actualiza el clima real si pasó el tiempo de refresco. Sin conexión o sin
  /// permiso se queda con lo último (y, si es viejo, con el clima propio).
  Future<bool> refresh({bool force = false}) async {
    if (!useReal || _busy) return false;
    if (!force && _fresh(DateTime.now(), rules.refreshEvery)) return false;
    _busy = true;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) return false;
      final pos =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
          );
      final symbol = await _fetchSymbol(pos.latitude, pos.longitude);
      if (symbol == null) return false;
      final next = weatherFromSymbol(symbol);
      if (_real != null && _real!.wet && !next.wet) {
        _realDryAt = DateTime.now();
        await _prefs.setInt('weather.dryAt', _realDryAt!.millisecondsSinceEpoch);
      }
      _real = next;
      _realAt = DateTime.now();
      await _prefs.setString('weather.code', _real!.name);
      await _prefs.setInt('weather.at', _realAt!.millisecondsSinceEpoch);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Clima real no disponible: $e');
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Símbolo del pronóstico para la próxima hora. La ubicación va redondeada
  /// a dos decimales (~1 km), como pide MET Norway y alcanza para el clima.
  static Future<String?> _fetchSymbol(double lat, double lon) async {
    final uri = Uri.parse('$_api?lat=${lat.toStringAsFixed(2)}&lon=${lon.toStringAsFixed(2)}');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, _agent);
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      return symbolFromForecast(body);
    } finally {
      client.close();
    }
  }
}

/// Saca el símbolo de la primera hora de un pronóstico `compact` de MET Norway.
@visibleForTesting
String? symbolFromForecast(Map<String, dynamic> body) {
  final series = (body['properties'] as Map?)?['timeseries'] as List?;
  if (series == null || series.isEmpty) return null;
  final data = (series.first as Map)['data'] as Map;
  for (final key in ['next_1_hours', 'next_6_hours', 'next_12_hours']) {
    final code = ((data[key] as Map?)?['summary'] as Map?)?['symbol_code'];
    if (code is String) return code;
  }
  return null;
}
