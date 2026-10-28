import 'dart:convert';

/// Valores de `assets/balance/game_balance.json`. Dart puro: la app lo carga
/// desde los assets al arrancar y los tests leen el archivo directo.
class Balance {
  final Map<String, dynamic> _root;
  Balance(this._root);

  factory Balance.parse(String json) => Balance(jsonDecode(json) as Map<String, dynamic>);

  static Balance? _instance;
  static Balance get instance => _instance ?? (throw StateError('Balance sin cargar'));
  static set instance(Balance b) => _instance = b;

  BalanceSection section(String name) => BalanceSection(_root[name] as Map<String, dynamic>);

  BalanceSection get serenity => section('serenity');
  BalanceSection get repeats => section('repeats');
  BalanceSection get stack => section('stack');
  BalanceSection get sand => section('sand');
  BalanceSection get rain => section('rain');
  BalanceSection get level => section('level');
  BalanceSection get meditation => section('meditation');
  List<BalanceSection> get expansions => [
    for (final e in _root['expansions'] as List) BalanceSection(e as Map<String, dynamic>),
  ];
  BalanceSection rewards(String game) => section('rewards').sub(game);
}

class BalanceSection {
  final Map<String, dynamic> _m;
  BalanceSection(this._m);

  double d(String key) => (_m[key] as num).toDouble();
  int i(String key) => (_m[key] as num).round();
  String s(String key) => _m[key] as String;
  List<String> strings(String key) => [for (final v in _m[key] as List) v as String];
  List<double> list(String key) => [for (final v in _m[key] as List) (v as num).toDouble()];
  BalanceSection sub(String key) => BalanceSection(_m[key] as Map<String, dynamic>);
  List<BalanceSection> sections(String key) => [
    for (final v in _m[key] as List) BalanceSection(v as Map<String, dynamic>),
  ];
  bool has(String key) => _m.containsKey(key);
  bool flag(String key, {bool orElse = false}) => (_m[key] as bool?) ?? orElse;
  Map<String, num> nums(String key) => (_m[key] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as num));
}
