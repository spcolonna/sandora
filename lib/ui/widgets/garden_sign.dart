import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../garden/progress.dart';
import '../../i18n/i18n.dart';
import '../fx/calm.dart';
import '../fx/sfx.dart';
import '../theme/palette.dart';

/// Cuántas sugerencias de nombre hay en i18n (`garden.suggest.N`).
const _suggestions = 8;

/// Cartel de madera colgado en el jardín con su nombre. Tocarlo permite
/// cambiarlo. Se dibuja con código hasta tener `ui_garden_sign` (Bloque 9).
class GardenSign extends StatelessWidget {
  const GardenSign({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: Progress.instance, builder: (context, _) => _sign(context));
  }

  Widget _sign(BuildContext context) {
    final name = Progress.instance.gardenName;
    return GestureDetector(
      onTap: () => showGardenNameSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de bambú y dos cuerdas.
          SizedBox(width: 120, height: 14, child: CustomPaint(painter: _RopesPainter())),
          AnimatedSwitcher(
            duration: Calm.appear,
            child: Container(
              key: ValueKey(name),
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD3AE86), Color(0xFFB98D63)],
                ),
                border: Border.all(color: Palette.wood, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Palette.ink.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name == null) ...[
                    const Icon(Icons.edit_rounded, size: 14, color: Palette.ink),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      name ?? tr('garden.unnamed'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Palette.ink,
                        fontWeight: name == null ? FontWeight.w500 : FontWeight.w700,
                        fontSize: name == null ? 12 : 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RopesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rope = Paint()
      ..color = Palette.wood.withValues(alpha: 0.8)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(size.width * 0.25, 3), Offset(size.width * 0.25, size.height), rope);
    canvas.drawLine(Offset(size.width * 0.75, 3), Offset(size.width * 0.75, size.height), rope);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.12, 0, size.width * 0.76, 4), const Radius.circular(2)),
      Paint()..color = Palette.moss,
    );
  }

  @override
  bool shouldRepaint(_RopesPainter old) => false;
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
