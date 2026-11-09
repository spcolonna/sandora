import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../garden/decor.dart';
import '../garden/economy.dart';
import '../garden/progress.dart';
import '../garden/mirador.dart';
import '../i18n/i18n.dart';
import 'decor_tray.dart';
import 'garden/garden_scene.dart';
import 'garden/garden_view.dart';
import 'fx/sfx.dart';
import 'garden/garden_decor.dart';
import 'garden/scene_art.dart';
import 'theme/palette.dart';
import 'upgrade_sheet.dart';
import 'widgets/currency.dart';
import 'widgets/glass.dart';
import 'widgets/washi.dart';

/// Lo que pidió ver la Maqueta al cerrarse: la decoración [index] en la vista
/// [side] o, sin [index], un paseo por el jardín desde esa vista.
typedef ModelFocus = ({int side, int? index});

/// La Maqueta: el jardín en miniatura sobre una mesa. Cada vista (patio,
/// estanque, bosque) es una grilla de parcelas; se compran parcelas y se pone
/// cada decoración en la suya. Entra deslizando desde el costado, como el
/// Mercado. Devuelve la decoración que se pidió ver en el jardín, si alguna.
///
/// Con [world] (la vista Sendero) es la vista aérea: el mismo jardín visto
/// desde arriba, con cada parcela en su hueco al costado del camino.
Future<ModelFocus?> openModel(BuildContext context, {int side = 0, MiradorWorld? world}) => Navigator.of(context).push(
  CupertinoPageRoute<ModelFocus>(
    builder: (_) => ModelScreen(side: side, world: world),
  ),
);

class ModelScreen extends StatefulWidget {
  final int side;
  final MiradorWorld? world;
  const ModelScreen({super.key, this.side = 0, this.world});

  @override
  State<ModelScreen> createState() => _ModelScreenState();
}

class _ModelScreenState extends State<ModelScreen> {
  late int _side = widget.side;

  /// La decoración de la caja elegida para poner, o la ya puesta elegida (su índice).
  String? _holding;
  int? _picked;

  Progress get p => Progress.instance;

  void _tell(String text) => showWashiToast(context, text, duration: const Duration(seconds: 2));

  void _setSide(int side) {
    if (side == _side) return;
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
    setState(() {
      _side = side;
      _picked = null;
    });
  }

  /// Un toque en el cajón: elige la que está en la caja o la compra.
  void _tapTray(DecorItem d) {
    if (_holding == d.id) {
      setState(() => _holding = null);
      return;
    }
    if (p.decorStored(d.id) == 0) {
      if (p.level < d.level) {
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
        return _tell(tr('decor.needLevel', {'n': d.level}));
      }
      if (!p.buyDecor(d)) {
        SoundBoard.instance.play(Sfx.uiTap, volume: 0.3);
        return _tell(tr('decor.needMore'));
      }
      SoundBoard.instance.play(Sfx.good, volume: 0.5);
    } else {
      SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    }
    Haptics.light();
    // Si hay una sola parcela libre, va directo ahí.
    final free = _freeCells();
    if (free.length == 1) return _place(d.id, free.first);
    setState(() {
      _holding = d.id;
      _picked = null;
    });
    if (free.isEmpty) _tell(tr('model.full'));
  }

  List<int> _freeCells() => [
    for (var c = 0; c < p.modelRules.cells; c++)
      if (p.parcelOpen(_side, c) && p.decorAt(_side, c) == null) c,
  ];

  void _place(String id, int cell) {
    if (p.placeDecor(id, _side, cell) == null) return;
    SoundBoard.instance.play(Sfx.stoneSand, volume: 0.7);
    Haptics.light();
    setState(() => _holding = p.decorStored(id) > 0 && _freeCells().isNotEmpty ? id : null);
  }

  void _move(int index, int cell) {
    if (!p.moveDecor(index, cell)) return;
    SoundBoard.instance.play(Sfx.stoneSand, volume: 0.6);
    Haptics.light();
    setState(() => _picked = null);
  }

  void _tapCell(int cell) {
    final here = p.decorAt(_side, cell);
    if (!p.parcelOpen(_side, cell)) {
      _buyParcel(cell);
      return;
    }
    if (_holding != null && here == null) return _place(_holding!, cell);
    if (_picked != null && _picked != here) return _move(_picked!, cell);
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.35);
    setState(() {
      _picked = here == null || here == _picked ? null : here;
      _holding = null;
    });
  }

  Future<void> _buyParcel(int cell) async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.4);
    final cost = p.parcelCost(_side);
    final can = p.canBuyParcel(_side, cell);
    final yes = await showWashiDialog<bool>(
      context,
      title: tr('model.parcelTitle'),
      actions: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [for (final c in cost.entries) CurrencyChip.of(c.key, c.value)],
        ),
        const SizedBox(height: 10),
        InkButton(
          label: tr(can ? 'model.parcelBuy' : 'decor.needMore'),
          onPressed: can ? () => Navigator.of(context, rootNavigator: true).pop(true) : null,
        ),
        InkButton.quiet(label: tr('common.cancel'), onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
      ],
    );
    if (yes != true || !mounted) return;
    if (p.buyParcel(_side, cell)) {
      SoundBoard.instance.play(Sfx.good, volume: 0.55);
      Haptics.light();
      setState(() {});
    }
  }

  void _store() {
    final i = _picked;
    if (i == null) return;
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    p.storeDecor(i);
    setState(() => _picked = null);
  }

  void _flip() {
    final i = _picked;
    if (i == null) return;
    SoundBoard.instance.play(Sfx.stoneSand, volume: 0.4);
    p.flipDecor(i);
  }

  void _seeInGarden() {
    final i = _picked;
    if (i == null) return;
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    Navigator.of(context).pop<ModelFocus>((side: _side, index: i));
  }

  /// Recorrer el jardín empezando por la zona que se está viendo.
  void _walk() {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    Navigator.of(context).pop<ModelFocus>((side: _side, index: null));
  }

  Future<void> _upgrades() async {
    SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
    await showWashiSheet<void>(context, builder: (_) => const _UpgradeList());
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Palette.paper,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(washiTexture), fit: BoxFit.cover),
        ),
        child: ListenableBuilder(
          listenable: p,
          builder: (context, _) {
            if ((_picked ?? -1) >= p.decor.length || (_picked != null && p.decor[_picked!].side != _side)) {
              _picked = null;
            }
            final upgrades = p.upgradeRules.places.where(p.gameUnlocked).isNotEmpty;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(8, pad.top + 4, 12, 0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                        child: InkIconButton(
                          glyph: InkGlyph.back,
                          size: 42,
                          tooltip: tr('result.garden'),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tr(widget.world != null ? 'aerial.title' : 'model.title'),
                          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      InkButton.small(label: tr('model.walk'), onPressed: _walk),
                      if (upgrades) ...[
                        const SizedBox(width: 8),
                        Badge(
                          isLabelVisible: p.upgradeAvailable,
                          smallSize: 10,
                          backgroundColor: Palette.lantern,
                          child: InkButton.small(label: tr('model.upgrades'), onPressed: _upgrades),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      CurrencyChip.pebbles(p.pebbles),
                      for (final e in Essence.values) CurrencyChip.essence(e, p.essences[e]!),
                      CurrencyChip.lotus(p.lotus),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _ZoneTabs(side: _side, onTap: _setSide),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: widget.world != null
                        ? _AerialBoard(
                            world: widget.world!,
                            side: _side,
                            holding: _holding,
                            picked: _picked,
                            onTap: _tapCell,
                            onDropNew: (id, cell) => _place(id, cell),
                            onDropMove: _move,
                          )
                        : _Board(
                            side: _side,
                            holding: _holding,
                            picked: _picked,
                            onTap: _tapCell,
                            onDropNew: (id, cell) => _place(id, cell),
                            onDropMove: _move,
                          ),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: _picked != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkButton.small(label: tr('decor.store'), onPressed: _store),
                              ),
                              const SizedBox(width: 8),
                              InkIconButton(
                                key: const ValueKey('flip'),
                                glyph: InkGlyph.replay,
                                size: 40,
                                tooltip: tr('model.flip'),
                                onPressed: _flip,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkButton.small(label: tr('model.see'), onPressed: _seeInGarden),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: Text(
                              tr(
                                _holding != null
                                    ? 'model.hintPlace'
                                    : p.guideStep == Guide.place && p.decor.any((d) => d.placed)
                                    ? 'guide.placeDone'
                                    : 'model.hint',
                              ),
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(color: Palette.ink.withValues(alpha: 0.7)),
                            ),
                          ),
                        ),
                ),
                ColoredBox(
                  color: Palette.paper.withValues(alpha: 0.7),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, pad.bottom),
                    child: DecorTray(selected: _holding, onTap: _tapTray),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Las tres vistas del jardín, como pestañas.
class _ZoneTabs extends StatelessWidget {
  final int side;
  final ValueChanged<int> onTap;
  const _ZoneTabs({required this.side, required this.onTap});

  static const _names = ['garden.patio', 'garden.pond', 'garden.forest'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _names.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkChip(label: tr(_names[i]), selected: i == side, onTap: () => onTap(i)),
          ),
      ],
    );
  }
}

/// Dónde queda cada parcela en la bandeja: un trapecio (el fondo más angosto,
/// como si se mirara la mesa desde arriba y un poco de costado).
class _ModelGeometry {
  final Size size;
  final ModelRules rules;
  _ModelGeometry(this.size, this.rules);

  static const backWidth = 0.76, margin = 0.06;

  /// Altura de cada fila, del fondo al frente (las de adelante, más altas).
  List<double> get _rowWeights => [for (var r = 0; r < rules.rows; r++) 1 + 0.18 * r];

  double _y(int row) {
    final w = _rowWeights, total = w.fold(0.0, (a, b) => a + b);
    final inner = size.height * (1 - 2 * margin);
    return size.height * margin + inner * w.take(row).fold(0.0, (a, b) => a + b) / total;
  }

  double _halfWidth(double y) {
    final t = ((y - size.height * margin) / (size.height * (1 - 2 * margin))).clamp(0.0, 1.0);
    return size.width * (1 - 2 * margin) / 2 * lerpDouble(backWidth, 1, t)!;
  }

  double _x(int col, double y) {
    final hw = _halfWidth(y);
    return size.width / 2 - hw + 2 * hw * col / rules.cols;
  }

  /// Las cuatro esquinas de la parcela [cell].
  List<Offset> corners(int cell) {
    final r = rules.row(cell), c = rules.col(cell);
    final top = _y(r), bottom = _y(r + 1);
    return [
      Offset(_x(c, top), top),
      Offset(_x(c + 1, top), top),
      Offset(_x(c + 1, bottom), bottom),
      Offset(_x(c, bottom), bottom),
    ];
  }

  /// El rectángulo que se toca: el medio del trapecio.
  Rect hit(int cell) {
    final k = corners(cell);
    final mid = (k[0].dy + k[3].dy) / 2;
    final c = rules.col(cell);
    return Rect.fromLTRB(_x(c, mid), k[0].dy, _x(c + 1, mid), k[3].dy);
  }

  /// La bandeja entera.
  List<Offset> get tray {
    final top = _y(0), bottom = _y(rules.rows);
    return [
      Offset(_x(0, top), top),
      Offset(_x(rules.cols, top), top),
      Offset(_x(rules.cols, bottom), bottom),
      Offset(_x(0, bottom), bottom),
    ];
  }
}

class _Board extends StatelessWidget {
  final int side;
  final String? holding;
  final int? picked;
  final ValueChanged<int> onTap;
  final void Function(String id, int cell) onDropNew;
  final void Function(int index, int cell) onDropMove;

  const _Board({
    required this.side,
    required this.holding,
    required this.picked,
    required this.onTap,
    required this.onDropNew,
    required this.onDropMove,
  });

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return LayoutBuilder(
      builder: (context, box) {
        // La bandeja mantiene su proporción y se centra.
        final w = box.maxWidth, h = (w * 0.9).clamp(0.0, box.maxHeight);
        final geo = _ModelGeometry(Size(w, h), p.modelRules);
        final cells = p.modelRules.cells;
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrayPainter(geo, side, [for (var c = 0; c < cells; c++) p.parcelOpen(side, c)]),
                  ),
                ),
                // Del fondo al frente, para que lo de adelante tape lo de atrás.
                for (var c = 0; c < cells; c++)
                  Positioned.fromRect(
                    rect: geo.hit(c),
                    child: _Cell(
                      key: ValueKey('cell$side.$c'),
                      side: side,
                      cell: c,
                      decor: p.decorAt(side, c),
                      open: p.parcelOpen(side, c),
                      picked: picked != null && p.decorAt(side, c) == picked,
                      target: holding != null && p.parcelOpen(side, c) && p.decorAt(side, c) == null,
                      onTap: () => onTap(c),
                      onDropNew: (id) => onDropNew(id, c),
                      onDropMove: (i) => onDropMove(i, c),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Una parcela: cerrada (candado y precio), libre o con su figurita.
class _Cell extends StatelessWidget {
  final int side, cell;
  final int? decor;
  final bool open, picked, target;
  final VoidCallback onTap;
  final ValueChanged<String> onDropNew;
  final ValueChanged<int> onDropMove;

  const _Cell({
    super.key,
    required this.side,
    required this.cell,
    required this.decor,
    required this.open,
    required this.picked,
    required this.target,
    required this.onTap,
    required this.onDropNew,
    required this.onDropMove,
  });

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final item = decor == null ? null : p.decorRules.byId(p.decor[decor!].id);
    final figure = item == null
        ? null
        : LayoutBuilder(
            builder: (context, box) {
              // La figurita parada en el medio de la parcela, más alta que ella.
              final fw = box.maxWidth * (0.55 + item.size * 2.2);
              final fh = fw * item.aspect;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: (box.maxWidth - fw) / 2,
                    top: box.maxHeight * 0.78 - fh,
                    width: fw,
                    height: fh,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _Figure(item.id, lifted: picked, flip: p.decor[decor!].flip),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
    Widget body = Semantics(
      button: true,
      label: item != null ? tr('decor.${item.id}') : tr(open ? 'model.free' : 'model.locked'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!open)
              Center(
                child: FittedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 18, color: Palette.ink.withValues(alpha: 0.45)),
                      _CostLine(p.parcelCost(side)),
                    ],
                  ),
                ),
              ),
            if (target) Center(child: Icon(Icons.add_rounded, size: 22, color: Palette.ink.withValues(alpha: 0.45))),
            ?figure,
          ],
        ),
      ),
    );
    if (decor != null) {
      body = Draggable<int>(
        data: decor,
        feedback: SizedBox.square(dimension: 84, child: CustomPaint(painter: DecorPainter(item!.id, item.aspect))),
        childWhenDragging: const SizedBox.expand(),
        child: body,
      );
    }
    if (!open) return body;
    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) => d.data is String ? decor == null : d.data != decor,
      onAcceptWithDetails: (d) => switch (d.data) {
        final String id => onDropNew(id),
        final int i => onDropMove(i),
        _ => null,
      },
      builder: (context, hover, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: hover.isNotEmpty ? Palette.lantern.withValues(alpha: 0.25) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: body,
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  final Map<String, int> cost;
  const _CostLine(this.cost);

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in cost.entries) ...[
          SizedBox(width: 14, height: 14, child: FittedBox(child: CurrencyIcon(c.key))),
          const SizedBox(width: 2),
          Text(
            '${c.value}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: p.walletOf(c.key) >= c.value ? Palette.ink : const Color(0xFFB0503C),
            ),
          ),
        ],
      ],
    );
  }
}

/// Una decoración en miniatura; elegida, levantada y con su aro.
class _Figure extends CustomPainter {
  final String id;
  final bool lifted;
  final bool flip;
  _Figure(this.id, {required this.lifted, this.flip = false});

  @override
  void paint(Canvas canvas, Size size) {
    var r = Offset.zero & size;
    if (lifted) {
      canvas.drawOval(
        Rect.fromCenter(center: r.bottomCenter, width: r.width * 1.1, height: r.width * 0.3),
        Paint()
          ..color = Palette.lantern
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      r = r.shift(Offset(0, -size.height * 0.08));
    }
    paintDecor(canvas, id, r, flip: flip);
  }

  @override
  bool shouldRepaint(_Figure old) => old.id != id || old.lifted != lifted || old.flip != flip;
}

/// La bandeja de madera con el suelo de cada vista (arena rastrillada, el
/// borde del estanque, musgo) y las parcelas marcadas; las cerradas, apagadas.
class _TrayPainter extends CustomPainter {
  final _ModelGeometry geo;
  final int side;
  final List<bool> open;
  _TrayPainter(this.geo, this.side, this.open);

  static const _trayArt = ['model_tray_patio', 'model_tray_pond', 'model_tray_forest'];
  static const _ground = [Color(0xFFE9DFC8), Color(0xFFD9DDBF), Color(0xFFC9D3A8)];

  Path _poly(List<Offset> k) => Path()..addPolygon(k, true);

  @override
  void paint(Canvas canvas, Size size) {
    final tray = geo.tray;
    // El marco de madera y su sombra sobre el papel.
    final frame = _poly([
      tray[0] + const Offset(-10, -10),
      tray[1] + const Offset(10, -10),
      tray[2] + const Offset(14, 12),
      tray[3] + const Offset(-14, 12),
    ]);
    canvas.drawPath(frame.shift(const Offset(0, 8)), Paint()..color = Palette.ink.withValues(alpha: 0.12));
    canvas.drawPath(frame, Paint()..color = Palette.wood);
    final ground = _poly(tray);
    final art = SceneArt.instance[_trayArt[side]];
    if (art != null) {
      canvas.save();
      canvas.clipPath(ground);
      drawArt(canvas, art, ground.getBounds());
      canvas.restore();
    } else {
      canvas.drawPath(ground, Paint()..color = _ground[side]);
      _details(canvas, ground);
    }
    for (var c = 0; c < open.length; c++) {
      final cell = _poly(geo.corners(c));
      if (!open[c]) {
        canvas.drawPath(cell, Paint()..color = Palette.ink.withValues(alpha: 0.18));
      }
      canvas.drawPath(
        cell,
        Paint()
          ..color = Palette.ink.withValues(alpha: open[c] ? 0.22 : 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  /// Sin arte: unas líneas de rastrillo en el patio, agua al fondo del
  /// estanque y manchas de musgo en el bosque.
  void _details(Canvas canvas, Path ground) {
    final b = ground.getBounds();
    canvas.save();
    canvas.clipPath(ground);
    switch (side) {
      case 0:
        final rake = Paint()
          ..color = const Color(0xFFCDBF9F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        for (var y = b.top + 8; y < b.bottom; y += 9) {
          canvas.drawLine(Offset(b.left, y), Offset(b.right, y), rake);
        }
      case 1:
        canvas.drawRect(
          Rect.fromLTRB(b.left, b.top, b.right, b.top + b.height * 0.12),
          Paint()..color = const Color(0xFF8FB3B5),
        );
      default:
        final moss = Paint()..color = const Color(0xFF9DB07A);
        for (var i = 0; i < 9; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(b.left + b.width * ((i * 37) % 100) / 100, b.top + b.height * ((i * 53) % 100) / 100),
              width: b.width * 0.16,
              height: b.height * 0.07,
            ),
            moss,
          );
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrayPainter old) =>
      old.side != side || old.geo.size != geo.size || old.open.join() != open.join();
}

/// Las mejoras de cada lugar.
class _UpgradeList extends StatelessWidget {
  const _UpgradeList();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final places = p.upgradeRules.places.where(p.gameUnlocked).toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('model.upgrades'), style: text.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(tr('model.upgradesDesc'), style: text.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                for (final g in places)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Glass(
                      opacity: 0.7,
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.construction_rounded, color: Palette.ink),
                        title: Text(tr('mg.$g.name')),
                        trailing: Badge(
                          isLabelVisible: p.canUpgrade(g),
                          smallSize: 10,
                          backgroundColor: Palette.lantern,
                          child: Text(
                            '${p.upgradeTier(g)}/${p.upgradeRules.maxTier}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        onTap: () {
                          SoundBoard.instance.play(Sfx.uiTap, volume: 0.45);
                          showUpgradeSheet(context, g);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La vista aérea de una zona del Sendero: el camino, los ramales y los
/// lugares sobre papel, y cada parcela en su hueco. Arranca acercada a las
/// parcelas; se pellizca para alejar y ver toda la zona.
class _AerialBoard extends StatefulWidget {
  final MiradorWorld world;
  final int side;
  final String? holding;
  final int? picked;
  final ValueChanged<int> onTap;
  final void Function(String id, int cell) onDropNew;
  final void Function(int index, int cell) onDropMove;

  const _AerialBoard({
    required this.world,
    required this.side,
    required this.holding,
    required this.picked,
    required this.onTap,
    required this.onDropNew,
    required this.onDropMove,
  });

  @override
  State<_AerialBoard> createState() => _AerialBoardState();
}

class _AerialBoardState extends State<_AerialBoard> {
  final _view = TransformationController();

  /// Para qué zona y tamaño se acomodó la vista.
  (int, Size)? _fitted;

  MiradorWorld get world => widget.world;

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  Rect _around(Iterable<Offset> pts) {
    var box = Rect.fromPoints(pts.first, pts.first);
    for (final p in pts) {
      box = box.expandToInclude(Rect.fromPoints(p, p));
    }
    return box;
  }

  /// Todo el patio (la vista aérea se puede alejar hasta verlo entero).
  Rect _zone(int side) => world.wall.inflate(0.8);

  /// Las parcelas de la zona.
  Rect _cells(int side) =>
      _around([for (var c = 0; c < world.cols * world.rows; c++) world.slot(side, c)]).inflate(0.9);

  @override
  Widget build(BuildContext context) {
    final p = Progress.instance;
    final side = widget.side;
    return LayoutBuilder(
      builder: (context, box) {
        final vp = box.biggest;
        final focus = _cells(side);
        final k = min(vp.width / focus.width, vp.height / focus.height);
        final zone = _zone(side).expandToInclude(focus);
        final size = Size(zone.width * k, zone.height * k);
        // Hacia adelante es hacia arriba.
        Offset map(Offset w) => Offset((w.dx - zone.left) * k, (zone.bottom - w.dy) * k);
        if (_fitted != (side, vp)) {
          _fitted = (side, vp);
          final c = map(focus.center);
          _view.value = Matrix4.translationValues(vp.width / 2 - c.dx, vp.height / 2 - c.dy, 0);
        }
        final cell = 1.05 * k;
        final cells = p.modelRules.cells;
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: InteractiveViewer(
            transformationController: _view,
            constrained: false,
            minScale: min(1, min(vp.width / size.width, vp.height / size.height)),
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(60),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _AerialPainter(world, side, zone, k))),
                  for (var c = 0; c < cells; c++)
                    Positioned.fromRect(
                      rect: Rect.fromCenter(center: map(world.slot(side, c)), width: cell, height: cell),
                      child: _Cell(
                        key: ValueKey('cell$side.$c'),
                        side: side,
                        cell: c,
                        decor: p.decorAt(side, c),
                        open: p.parcelOpen(side, c),
                        picked: widget.picked != null && p.decorAt(side, c) == widget.picked,
                        target: widget.holding != null && p.parcelOpen(side, c) && p.decorAt(side, c) == null,
                        onTap: () => widget.onTap(c),
                        onDropNew: (id) => widget.onDropNew(id, c),
                        onDropMove: (i) => widget.onDropMove(i, c),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AerialPainter extends CustomPainter {
  final MiradorWorld world;
  final int side;
  final Rect bounds;
  final double k;
  _AerialPainter(this.world, this.side, this.bounds, this.k);

  Offset _map(Offset w) => Offset((w.dx - bounds.left) * k, (bounds.bottom - w.dy) * k);

  static const _zones = [Color(0xFFE2D5B8), Color(0xFFC9CDAA), Color(0xFF98A87A)];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paper = SceneArt.instance['bg_path_aerial_paper'];
    if (paper != null) {
      drawArt(canvas, paper, Offset.zero & size);
      canvas.drawRect(Offset.zero & size, Paint()..color = _zones[side].withValues(alpha: 0.35));
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = Color.lerp(_zones[side], Palette.paper, 0.35)!);
    }
    // El muro, el musgo y el agua.
    final wall = Rect.fromPoints(_map(world.wall.topLeft), _map(world.wall.bottomRight));
    canvas.drawRect(
      wall,
      Paint()
        ..color = Palette.wood.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3, 0.3 * k),
    );
    for (final (c, r) in world.moss) {
      canvas.drawCircle(_map(c), r * k * 0.8, Paint()..color = Palette.moss.withValues(alpha: 0.22));
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: _map(world.pondAt),
        width: world.pondRadii.width * 2 * k,
        height: world.pondRadii.height * 2 * k,
      ),
      Paint()..color = Palette.water.withValues(alpha: 0.8),
    );
    // El paisaje, como copas y piedras vistas desde arriba.
    for (final o in world.objects) {
      if (o.kind != PanoKind.prop) continue;
      final c = _map(o.at);
      if (!(Offset.zero & size).inflate(20).contains(c)) continue;
      if (o.decor == 'pavilion') {
        canvas.drawRect(
          Rect.fromCenter(center: c, width: o.width * k, height: 1.8 * k),
          Paint()..color = Palette.wood.withValues(alpha: 0.55),
        );
        continue;
      }
      final green = !const {
        'boulder',
        'rocks',
        'peak',
        'lantern',
        'jizo',
        'pagoda',
        'obj_court_rock',
        'obj_court_lantern_tall',
      }.contains(o.decor);
      canvas.drawCircle(
        c,
        o.width * k * 0.38,
        Paint()..color = (green ? Palette.moss : Palette.stone).withValues(alpha: 0.45),
      );
    }
    // Los senderos de piedras entre miradores.
    for (final (q, r) in world.stones) {
      canvas.drawCircle(_map(q), max(2, r * k), Paint()..color = const Color(0xFFB9A982));
    }
    // Los portones.
    for (final o in world.objects) {
      if (o.kind != PanoKind.gate) continue;
      final a = _map(o.at - Offset(o.width / 2, 0)), b = _map(o.at + Offset(o.width / 2, 0));
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Palette.clay
          ..strokeWidth = max(3, 0.25 * k)
          ..strokeCap = StrokeCap.round,
      );
    }
    // Los lugares, con su nombre.
    for (final o in world.objects) {
      if (o.place == null) continue;
      final c = _map(o.at);
      if (!(Offset.zero & size).inflate(30).contains(c)) continue;
      canvas.drawCircle(c, max(10, 0.7 * k), Paint()..color = Palette.wood.withValues(alpha: 0.85));
      final tp = TextPainter(
        text: TextSpan(
          text: o.place == 'model' ? tr('model.title') : placeName(Place.values.byName(o.place!)),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Palette.ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 110);
      tp.paint(canvas, c + Offset(-tp.width / 2, max(10, 0.7 * k) + 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AerialPainter old) => old.side != side || old.k != k || old.bounds != bounds;
}
