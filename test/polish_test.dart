import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sandora/minigames/common/grade.dart';
import 'package:sandora/ui/fx/reward_flight.dart';
import 'package:sandora/ui/widgets/soft.dart';

void main() {
  group('FadingNote', () {
    test('un aviso nuevo se enciende de a poco', () {
      final n = FadingNote();
      expect(n.show('hola', 0), ('hola', 0.0));
      final (s, a) = n.show('hola', FadingNote.fade / 2);
      expect(s, 'hola');
      expect(a, closeTo(0.5, 1e-9));
      expect(n.show('hola', 1).$2, 1.0);
    });

    test('al cambiar, el anterior se apaga antes de que entre el nuevo', () {
      final n = FadingNote();
      n.show('uno', 0);
      n.show('uno', 1);
      expect(n.show('dos', 1).$1, 'uno');
      final (s, a) = n.show('dos', 1 + FadingNote.fade * 0.25);
      expect(s, 'uno');
      expect(a, closeTo(0.5, 1e-9));
      expect(n.show('dos', 1 + FadingNote.fade * 0.75).$1, 'dos');
      expect(n.show('dos', 2), ('dos', 1.0));
    });

    test('al quedar vacío, el último se apaga en vez de cortarse', () {
      final n = FadingNote();
      n.show('uno', 0);
      n.show('uno', 1);
      expect(n.show('', 1), ('uno', 1.0));
      expect(n.show('', 1 + FadingNote.fade), ('uno', 0.0));
    });
  });

  testWidgets('el contador no muestra lo que todavía vuela hacia él', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: HeldAmount(currency: 'test', value: 100, builder: (n) => Text('$n')),
      ),
    );
    expect(find.text('100'), findsOneWidget);
    RewardFlight.hold('test', 30);
    await tester.pump();
    expect(find.text('70'), findsOneWidget);
    RewardFlight.heldOf('test').value = 0;
    await tester.pump();
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('sin contador a la vista, lo retenido se libera enseguida', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    RewardFlight.hold('lost', 12);
    RewardFlight.fly(ctx, from: Offset.zero, currency: 'lost', amount: 12, held: true);
    expect(RewardFlight.heldOf('lost').value, 0);
  });

  testWidgets('CountUp cuenta hasta el valor nuevo', (tester) async {
    Widget at(int v) => Directionality(
      textDirection: TextDirection.ltr,
      child: CountUp(value: v, format: (n) => 'n=$n'),
    );
    await tester.pumpWidget(at(2));
    expect(find.text('n=2'), findsOneWidget);
    await tester.pumpWidget(at(12));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('n=12'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('n=12'), findsOneWidget);
  });

  testWidgets('SoftShow oculto no atrapa toques', (tester) async {
    var taps = 0;
    Widget at(bool v) => Directionality(
      textDirection: TextDirection.ltr,
      child: SoftShow(
        visible: v,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    await tester.pumpWidget(at(false));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(50, 50));
    expect(taps, 0);
    await tester.pumpWidget(at(true));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(50, 50));
    expect(taps, 1);
  });
}
