import 'dart:async';

import 'package:flutter/material.dart';

import '../garden/progress.dart';
import '../i18n/i18n.dart';
import 'widgets/currency.dart';
import 'widgets/washi.dart';

/// mm:ss (o h:mm:ss) de lo que falta.
String restClock(Duration d) {
  final s = d.inSeconds;
  final mm = (s ~/ 60 % 60).toString().padLeft(2, '0'), ss = (s % 60).toString().padLeft(2, '0');
  return s >= 3600 ? '${s ~/ 3600}:$mm:$ss' : '$mm:$ss';
}

/// El lugar descansa después de jugarlo: cuánto falta y seguir ya pagando
/// lotos. Devuelve true si se pagó (o el descanso terminó mientras miraba).
Future<bool> showRestSheet(BuildContext context, String game) async {
  final ok = await showWashiSheet<bool>(context, builder: (context) => _RestSheet(game));
  return ok ?? false;
}

class _RestSheet extends StatefulWidget {
  final String game;
  const _RestSheet(this.game);

  @override
  State<_RestSheet> createState() => _RestSheetState();
}

class _RestSheetState extends State<_RestSheet> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (Progress.instance.restLeft(widget.game) == Duration.zero) {
        Navigator.pop(context, true);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('mg.${widget.game}.name'), style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(tr('rest.title'), style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              tr('rest.desc', {'t': restClock(p.restLeft(widget.game))}),
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            InkButton(
              label: tr('rest.skip'),
              whyNot: shortNote({'lotus': p.restSkipCost}),
              onPressed: p.canSkipRest(widget.game)
                  ? () {
                      if (p.skipRest(widget.game)) Navigator.pop(context, true);
                    }
                  : null,
            ),
            const SizedBox(height: 6),
            Center(child: CurrencyChip.price('lotus', p.restSkipCost)),
            const SizedBox(height: 6),
            InkButton.quiet(label: tr('rest.later'), onPressed: () => Navigator.pop(context, false)),
          ],
        ),
      ),
    );
  }
}
