import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../fx/sfx.dart';
import '../garden/garden_gate.dart';
import '../garden_screen.dart';
import '../theme/palette.dart';
import 'currency.dart';
import 'washi.dart';

/// Cuántas sugerencias de nombre hay en i18n (`garden.suggest.N`).
const _suggestions = 8;

const _art = 'assets/images/ui/ui_garden_sign.webp';

/// Cartel de madera colgado en el jardín con su nombre. Tocarlo abre los
/// jardines: cambiarle el nombre, pasar a otro o comprar uno nuevo.
class GardenSign extends StatelessWidget {
  const GardenSign({super.key});

  static const _width = 170.0;

  /// Lo que ocupa, para dejarle lugar.
  static const width = _width, height = _width / _aspect;

  // Proporción de `ui_garden_sign` (recortado) y zona libre de la tabla,
  // debajo de los agujeros de las cuerdas.
  static const _aspect = 593 / 308;
  static const _text = EdgeInsets.fromLTRB(
    _width * 0.13,
    _width / _aspect * 0.55,
    _width * 0.13,
    _width / _aspect * 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: Progress.instance, builder: (context, _) => _sign(context));
  }

  Widget _sign(BuildContext context) {
    final name = Progress.instance.gardenName;
    return GestureDetector(
      onTap: () => showGardensSheet(context),
      child: SizedBox(
        width: _width,
        height: _width / _aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_art, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            Padding(
              padding: _text,
              child: AnimatedSwitcher(
                duration: Calm.appear,
                child: FittedBox(
                  key: ValueKey(name),
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (name == null) ...[
                        const Icon(Icons.edit_rounded, size: 14, color: Palette.ink),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        name ?? tr('garden.unnamed'),
                        maxLines: 1,
                        style: TextStyle(
                          color: Palette.ink,
                          fontWeight: name == null ? FontWeight.w500 : FontWeight.w700,
                          fontSize: name == null ? 13 : 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Los jardines del jugador: el actual (con su nombre para cambiar), los
/// otros para pasar a ellos y uno nuevo para comprar con lotos.
Future<void> showGardensSheet(BuildContext context) {
  SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
  return showWashiSheet(
    context,
    builder: (sheet) => ListenableBuilder(
      listenable: Progress.instance,
      builder: (sheet, _) {
        final p = Progress.instance;
        final text = Theme.of(sheet).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('gardens.title'), style: text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                for (var i = 0; i < p.gardenCount; i++)
                  WashiTile(
                    glow: i == p.currentGarden,
                    onTap: i == p.currentGarden
                        ? null
                        : () async {
                            Navigator.pop(sheet);
                            await p.switchGarden(i);
                            if (context.mounted) _enterGarden(context);
                          },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.gardenNameAt(i) ?? tr('gardens.number', {'n': i + 1}), style: text.titleMedium),
                              if (i == p.currentGarden) Text(tr('gardens.here'), style: text.bodySmall),
                            ],
                          ),
                        ),
                        if (i == p.currentGarden)
                          InkIconButton(
                            glyph: InkGlyph.edit,
                            size: 38,
                            tooltip: tr('garden.name.title'),
                            onPressed: () {
                              Navigator.pop(sheet);
                              showGardenNameSheet(context);
                            },
                          )
                        else
                          InkButton.small(
                            label: tr('gardens.go'),
                            onPressed: () async {
                              Navigator.pop(sheet);
                              await p.switchGarden(i);
                              if (context.mounted) _enterGarden(context);
                            },
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                WashiTile(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('gardens.new'), style: text.titleMedium),
                            Text(
                              p.gardenCount >= p.gardenMax
                                  ? tr('gardens.full')
                                  : p.level < p.gardenMinLevel
                                  ? tr('gardens.level', {'n': p.gardenMinLevel})
                                  : tr('gardens.newDesc'),
                              style: text.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            CurrencyChip.lotus(p.gardenCost),
                          ],
                        ),
                      ),
                      InkButton.small(
                        label: tr('shop.dealBuy'),
                        onPressed: p.canBuyGarden
                            ? () async {
                                Navigator.pop(sheet);
                                SoundBoard.instance.play(Sfx.good, volume: 0.5);
                                if (await p.buyGarden() && context.mounted) _enterGarden(context);
                              }
                            : null,
                      ),
                    ],
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

/// Entra al jardín elegido como al abrir la app: con las puertas shoji.
void _enterGarden(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(calmRoute<void>(const GardenGate(child: GardenScreen())), (route) => false);
}

/// Hoja para elegir o cambiar el nombre del jardín, con una sugerencia ya
/// escrita que se puede aceptar tal cual.
Future<void> showGardenNameSheet(BuildContext context) {
  Progress.instance.markGardenNameOffered();
  return showWashiSheet(context, isScrollControlled: true, builder: (context) => const _NameSheet());
}

class _NameSheet extends StatefulWidget {
  const _NameSheet();

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  final _rng = Random();
  late int _idea = _rng.nextInt(_suggestions);
  late final _field = TextEditingController(text: Progress.instance.gardenName ?? tr('garden.suggest.${_idea + 1}'));

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _another() {
    _idea = (_idea + 1 + _rng.nextInt(_suggestions - 1)) % _suggestions;
    setState(() => _field.text = tr('garden.suggest.${_idea + 1}'));
    Haptics.light();
  }

  void _save() {
    Progress.instance.renameGarden(_field.text);
    SoundBoard.instance.play(Sfx.good, volume: 0.4);
    Haptics.light();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('garden.name.title'), style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(tr('garden.name.desc'), style: text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          TextField(
            controller: _field,
            autofocus: false,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.sentences,
            maxLength: Progress.gardenNameMax,
            inputFormatters: [LengthLimitingTextInputFormatter(Progress.gardenNameMax)],
            style: text.titleMedium,
            decoration: InputDecoration(
              hintText: tr('garden.name.hint'),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(5),
                child: InkIconButton(
                  glyph: InkGlyph.replay,
                  size: 36,
                  tooltip: tr('garden.name.other'),
                  onPressed: _another,
                ),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkButton.quiet(label: tr('garden.name.later'), onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkButton(label: tr('garden.name.save'), height: 48, onPressed: _save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
