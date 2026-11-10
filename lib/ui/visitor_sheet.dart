import 'package:flutter/material.dart';

import '../garden/progress.dart';
import '../garden/visitors.dart';
import '../i18n/i18n.dart';
import 'fx/sfx.dart';
import 'widgets/currency.dart';
import 'widgets/washi.dart';

/// Lo que pide [r], con sus datos (la decoración, el minijuego, cuántas).
String requestText(VisitorRequest r) => switch (r.kind) {
  RequestKind.decor => tr('req.decor', {'item': tr('decor.${r.target}')}),
  RequestKind.decorCount => tr('req.decorCount', {'n': r.n}),
  RequestKind.serenity => tr('req.serenity', {'n': r.n}),
  RequestKind.stars => tr('req.stars', {'n': r.n, 'game': tr('mg.${r.target}.name')}),
  RequestKind.noCare => tr('req.noCare'),
  RequestKind.upgrade => tr('req.upgrade'),
};

/// El visitante de la entrada: qué pide y lo que deja, para aceptar; qué
/// falta, mientras se espera; o el regalo, cuando el pedido se cumplió.
Future<void> showVisitorSheet(BuildContext context) {
  return showWashiSheet(
    context,
    builder: (sheet) => ListenableBuilder(
      listenable: Progress.instance,
      builder: (sheet, _) {
        final p = Progress.instance;
        final r = p.visitorRequest;
        final text = Theme.of(sheet).textTheme;
        if (r == null || p.visitorWho == null) {
          // Se fue (o ya se le dio lo suyo) con la hoja abierta: se dice, en
          // vez de dejar el papel en blanco.
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr('req.gone'), style: text.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  InkButton.quiet(label: tr('req.ok'), onPressed: () => Navigator.pop(sheet)),
                ],
              ),
            ),
          );
        }
        final state = p.visitorState;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('album.visitor.${p.visitorWho}'), style: text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  state == VisitorState.done ? tr('req.thanks') : '“${requestText(r)}”',
                  style: text.titleMedium?.copyWith(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [for (final g in r.give.entries) CurrencyChip.of(g.key, g.value, prefix: '+')],
                ),
                const SizedBox(height: 14),
                if (state == VisitorState.waiting)
                  Text(
                    tr('req.waiting', {'n': p.visitorRules.expireDays}),
                    style: text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                if (state != VisitorState.waiting)
                  Center(
                    child: InkButton.small(
                      label: state == VisitorState.done ? tr('req.claim') : tr('req.accept'),
                      onPressed: () {
                        if (state == VisitorState.done) {
                          p.claimVisitor();
                          SoundBoard.instance.play(Sfx.perfect, volume: 0.6);
                          Haptics.perfect();
                        } else {
                          p.acceptVisitor();
                          SoundBoard.instance.play(Sfx.good, volume: 0.5);
                          Haptics.light();
                        }
                        Navigator.of(sheet).pop();
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
