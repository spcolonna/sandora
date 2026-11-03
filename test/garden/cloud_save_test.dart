import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandora/garden/cloud_save.dart';

void main() {
  test('gana la copia con el reinicio más nuevo, después la de más Calma y después la más nueva', () {
    const local = (resetAt: 10, calm: 300, at: 500);
    expect(CloudSave.cloudWins(local, (resetAt: 20, calm: 0, at: 1)), isTrue, reason: 'otro aparato reinició');
    expect(CloudSave.cloudWins(local, (resetAt: 5, calm: 900, at: 900)), isFalse, reason: 'reinicio viejo');
    expect(CloudSave.cloudWins(local, (resetAt: 10, calm: 310, at: 1)), isTrue);
    expect(CloudSave.cloudWins(local, (resetAt: 10, calm: 290, at: 900)), isFalse);
    expect(CloudSave.cloudWins(local, (resetAt: 10, calm: 300, at: 501)), isTrue);
    expect(CloudSave.cloudWins(local, local), isFalse, reason: 'la misma no se vuelve a aplicar');
  });

  test('la partida viaja entera y los ajustes del aparato quedan', () async {
    SharedPreferences.setMockInitialValues({
      'calm': 420,
      'pebbles': 37,
      'serenity': 0.5,
      'introSeen': true,
      'expansions': ['patio1', 'pond'],
      'gardens': '[{}]',
      'sound': false,
      'language': 'ja',
      'weather.code': 'rain',
      'cloud.resetAt': 7,
    });
    final a = await SharedPreferences.getInstance();
    final blob = CloudSave.encode(a, at: 1234);
    final got = CloudSave.decode(blob)!;
    expect(got.meta, (resetAt: 7, calm: 420, at: 1234));
    expect(got.data.keys, containsAll(['calm', 'pebbles', 'serenity', 'introSeen', 'expansions', 'gardens']));
    expect(got.data.keys, isNot(contains('sound')));
    expect(got.data.keys, isNot(contains('weather.code')));
    expect(got.data.keys, isNot(contains('cloud.resetAt')));

    // Otro aparato, con una partida corta propia y sus ajustes.
    SharedPreferences.setMockInitialValues({'calm': 10, 'tower': '[]', 'sound': true, 'language': 'es'});
    final b = await SharedPreferences.getInstance();
    expect(CloudSave.cloudWins(CloudSave.localMeta(b), got.meta), isTrue);
    await CloudSave.apply(b, got.meta, got.data);
    expect(b.getInt('calm'), 420);
    expect(b.getDouble('serenity'), 0.5);
    expect(b.getStringList('expansions'), ['patio1', 'pond']);
    expect(b.containsKey('tower'), isFalse, reason: 'lo que no estaba en la copia se va');
    expect(b.getBool('sound'), isTrue);
    expect(b.getString('language'), 'es');
    expect(CloudSave.localMeta(b), got.meta, reason: 'después no vuelve a ganar la misma copia');
  });

  test('una copia rota no rompe nada', () {
    expect(CloudSave.decode('no es una copia'), isNull);
  });
}
