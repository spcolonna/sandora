import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../balance/balance.dart';
import 'progress.dart';

/// Lo que dice una copia de la partida para decidir cuál vale: cuándo se
/// reinició por última vez, cuánta Calma tiene y cuándo se guardó.
typedef SaveMeta = ({int resetAt, int calm, int at});

/// La partida en la nube: en iOS, el almacén clave-valor de iCloud (sigue a la
/// cuenta en todos sus aparatos y vuelve al reinstalar). En Android no hace
/// nada: las preferencias viajan en la copia de seguridad de Google y vuelven
/// al instalar.
///
/// Se guarda unos segundos después de cada cambio y al salir de la app. Al
/// abrir y al volver, si la copia de la nube va más adelantada, reemplaza la
/// local.
class CloudSave with WidgetsBindingObserver {
  CloudSave._();
  static final instance = CloudSave._();

  static const _channel = MethodChannel('sandora/cloud');
  static const _key = 'save.v1';

  /// Pasado esto la copia no entra en iCloud (el límite es 1 MB por clave).
  static const _maxBytes = 900 * 1024;

  /// Lo que no viaja: los ajustes de este aparato, el clima que se vio acá y
  /// las propias marcas de la nube.
  static bool _synced(String k) =>
      !Progress.keepOnReset.contains(k) && !k.startsWith('weather.') && !k.startsWith('cloud.');

  /// Si el aparato tiene iCloud con sesión iniciada.
  final available = ValueNotifier(false);

  /// Cuándo se guardó o se trajo por última vez.
  final lastSync = ValueNotifier<DateTime?>(null);

  /// Avisa cuando una copia de la nube reemplazó la partida (para mostrar el
  /// aviso grande que espera).
  final restored = ValueNotifier(0);

  SharedPreferences? _prefs;
  Timer? _debounce;
  bool _started = false, _busy = false;

  /// La copia de la nube gana si viene de un reinicio más nuevo, si tiene más
  /// Calma (siempre sube) o, con la misma, si es más nueva.
  static bool cloudWins(SaveMeta local, SaveMeta cloud) {
    if (cloud.resetAt != local.resetAt) return cloud.resetAt > local.resetAt;
    if (cloud.calm != local.calm) return cloud.calm > local.calm;
    return cloud.at > local.at;
  }

  /// La partida de [prefs] lista para subir, comprimida.
  static String encode(SharedPreferences prefs, {required int at}) {
    final data = {
      for (final k in prefs.getKeys())
        if (_synced(k)) k: prefs.get(k),
    };
    final json = jsonEncode({
      'resetAt': prefs.getInt('cloud.resetAt') ?? 0,
      'calm': prefs.getInt('calm') ?? 0,
      'at': at,
      'data': data,
    });
    return base64.encode(gzip.encode(utf8.encode(json)));
  }

  /// Lo que hay dentro de una copia (null si está rota).
  static ({SaveMeta meta, Map<String, dynamic> data})? decode(String blob) {
    try {
      final m = jsonDecode(utf8.decode(gzip.decode(base64.decode(blob)))) as Map<String, dynamic>;
      return (
        meta: (resetAt: m['resetAt'] as int, calm: m['calm'] as int, at: m['at'] as int),
        data: (m['data'] as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  static SaveMeta localMeta(SharedPreferences prefs) =>
      (resetAt: prefs.getInt('cloud.resetAt') ?? 0, calm: prefs.getInt('calm') ?? 0, at: prefs.getInt('cloud.at') ?? 0);

  /// Reemplaza la partida local por [data] (los ajustes quedan).
  static Future<void> apply(SharedPreferences prefs, SaveMeta meta, Map<String, dynamic> data) async {
    for (final k in prefs.getKeys().where(_synced).toList()) {
      if (!data.containsKey(k)) await prefs.remove(k);
    }
    for (final MapEntry(:key, :value) in data.entries) {
      switch (value) {
        case int():
          await prefs.setInt(key, value);
        case double():
          await prefs.setDouble(key, value);
        case bool():
          await prefs.setBool(key, value);
        case String():
          await prefs.setString(key, value);
        case List():
          await prefs.setStringList(key, [for (final e in value) e as String]);
      }
    }
    await prefs.setInt('cloud.resetAt', meta.resetAt);
    await prefs.setInt('cloud.at', meta.at);
  }

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Trae la copia de la nube y, si va más adelantada, la pone en lugar de la
  /// local. Se llama antes de cargar [Progress]; devuelve si la reemplazó.
  Future<bool> pull() async {
    if (!Platform.isIOS) return false;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    available.value = await _call<bool>('available') ?? false;
    final blob = await _call<String>('get', _key);
    if (blob == null) return false;
    final cloud = decode(blob);
    if (cloud == null || !cloudWins(localMeta(prefs), cloud.meta)) return false;
    final fresh = (prefs.getInt('calm') ?? 0) == 0;
    await apply(prefs, cloud.meta, cloud.data);
    lastSync.value = DateTime.now();
    // A quien abre la app en un aparato nuevo se le cuenta que su jardín volvió.
    if (fresh) {
      final queue = prefs.getStringList('milestones') ?? [];
      await prefs.setStringList('milestones', [...queue, 'cloud']);
    }
    return true;
  }

  /// Sube la partida tal como está.
  Future<void> push() async {
    _debounce?.cancel();
    final prefs = _prefs;
    if (prefs == null || !Platform.isIOS) return;
    final at = DateTime.now().millisecondsSinceEpoch;
    final blob = encode(prefs, at: at);
    if (blob.length > _maxBytes) return;
    final ok = await _call<bool>('set', {'key': _key, 'value': blob});
    if (ok == null) return;
    await prefs.setInt('cloud.at', at);
    lastSync.value = DateTime.now();
  }

  /// Después de reiniciar la partida: la copia nueva gana en todos lados.
  Future<void> markReset() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setInt('cloud.resetAt', DateTime.now().millisecondsSinceEpoch);
    await push();
  }

  /// Empieza a guardar con cada cambio y a mirar la nube al volver.
  void start() {
    if (_started || !Platform.isIOS) return;
    _started = true;
    Progress.instance.addListener(_schedule);
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      // Otro aparato guardó (o iCloud terminó de bajar la copia).
      if (call.method == 'changed') await _refresh();
    });
    _schedule();
  }

  /// Guarda un rato después del primer cambio (los que siguen entran en el
  /// mismo viaje).
  void _schedule() {
    if (_debounce?.isActive ?? false) return;
    _debounce = Timer(const Duration(seconds: 8), push);
  }

  /// Si la nube trae algo más adelantado, recarga la partida.
  Future<void> _refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      if (!await pull()) return;
      await Progress.instance.reload(Balance.instance);
      restored.value++;
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.inactive:
        if (_debounce?.isActive ?? false) push();
      case AppLifecycleState.resumed:
        _refresh();
      default:
    }
  }
}
