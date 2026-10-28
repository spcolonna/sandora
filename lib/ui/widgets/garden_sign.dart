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

/// Cuántas sugerencias de nombre hay en i18n (`garden.suggest.N`).
const _suggestions = 8;

const _art = 'assets/images/ui/ui_garden_sign.webp';

/// Cartel de madera colgado en el jardín con su nombre. Tocarlo abre los
/// jardines: cambiarle el nombre, pasar a otro o comprar uno nuevo.
class GardenSign extends StatelessWidget {
  const GardenSign({super.key});

  static const _width = 170.0;
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
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Palette.paper,
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
                  ListTile(
                    leading: Icon(i == p.currentGarden ? Icons.spa_rounded : Icons.spa_outlined, color: Palette.moss),
                    title: Text(p.gardenNameAt(i) ?? tr('gardens.number', {'n': i + 1})),
                    subtitle: i == p.currentGarden ? Text(tr('gardens.here')) : null,
                    trailing: i == p.currentGarden
                        ? IconButton(
                            tooltip: tr('garden.name.title'),
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () {
                              Navigator.pop(sheet);
                              showGardenNameSheet(context);
                            },
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: i == p.currentGarden
                        ? null
                        : () async {
                            Navigator.pop(sheet);
                            await p.switchGarden(i);
                            if (context.mounted) _enterGarden(context);
                          },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: Text(tr('gardens.new')),
                  subtitle: Text(
                    p.gardenCount >= p.gardenMax
                        ? tr('gardens.full')
                        : p.level < p.gardenMinLevel
                        ? tr('gardens.level', {'n': p.gardenMinLevel})
                        : tr('gardens.newDesc'),
                  ),
                  trailing: CurrencyChip.lotus(p.gardenCost),
                  enabled: p.canBuyGarden,
                  onTap: () async {
                    Navigator.pop(sheet);
                    SoundBoard.instance.play(Sfx.good, volume: 0.5);
                    if (await p.buyGarden() && context.mounted) _enterGarden(context);
                  },
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
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Palette.paper,
    builder: (context) => const _NameSheet(),
  );
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
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                tooltip: tr('garden.name.other'),
                onPressed: _another,
                icon: const Icon(Icons.autorenew_rounded),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('garden.name.later'))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: _save, child: Text(tr('garden.name.save'))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
