import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Game Center (solo iOS): los logros también quedan en la cuenta de Apple.
///
/// Al abrir se intenta entrar en silencio; si hace falta iniciar sesión, la
/// pantalla de Apple recién aparece cuando se toca "Game Center" en Logros.
class GameCenter {
  GameCenter._();
  static final instance = GameCenter._();

  static const _channel = MethodChannel('sandora/games');

  /// Los logros en App Store Connect se llaman `sandora.<id>`.
  static String gameCenterId(String id) => 'sandora.$id';

  bool get supported => Platform.isIOS;

  /// Si hay sesión de Game Center.
  final signedIn = ValueNotifier(false);

  bool _started = false;

  void start() {
    if (_started || !supported) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'auth') signedIn.value = call.arguments == true;
    });
    _call('auth');
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

  /// Manda el avance (0 a 100) de cada logro. Sin sesión no hace nada.
  Future<void> report(Map<String, double> percents) async {
    if (!supported || !signedIn.value || percents.isEmpty) return;
    await _call('report', {for (final e in percents.entries) gameCenterId(e.key): e.value});
  }

  /// Abre los logros de Game Center (o el inicio de sesión de Apple). Devuelve
  /// false si no hubo nada para mostrar: la sesión se inicia desde Ajustes.
  Future<bool> show() async => supported && (await _call<bool>('show') ?? false);
}
