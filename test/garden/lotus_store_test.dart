import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/garden/lotus_store.dart';

import '../helpers.dart';

void main() {
  final s = loadBalance().section('shop').sub('lotusPacks');
  final packs = [for (final p in s.sections('packs')) (id: p.s('id'), lotus: p.i('lotus'))];

  test('la venta de lotos queda apagada hasta crear los productos', () {
    expect(s.flag('enabled'), isFalse);
    expect(packs.map((p) => p.lotus), [5, 12, 30]);
  });

  test('cada compra entrega sus lotos una sola vez', () {
    final ledger = LotusLedger(packs);
    expect(ledger.deliver('t1', packs[1].id), 12);
    expect(ledger.deliver('t1', packs[1].id), 0, reason: 'la tienda avisó de nuevo la misma compra');
    expect(ledger.deliver('t2', packs[0].id), 5);
    expect(ledger.deliver('t3', 'otro.producto'), 0);
    final again = LotusLedger(packs, ledger.delivered);
    expect(again.deliver('t2', packs[0].id), 0, reason: 'lo entregado se recuerda al reabrir');
  });
}
