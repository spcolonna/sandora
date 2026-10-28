import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../balance/balance.dart';
import 'progress.dart';

/// Un paquete de lotos a la venta: el id del producto en las tiendas y cuántos da.
typedef LotusPack = ({String id, int lotus});

/// Qué compras ya se entregaron, para no dar dos veces los mismos lotos (la
/// tienda puede avisar de nuevo una compra si la app se cerró antes de
/// completarla). Dart puro para poder probarlo.
class LotusLedger {
  final List<LotusPack> packs;
  final Set<String> delivered;
  LotusLedger(this.packs, [Set<String>? delivered]) : delivered = delivered ?? {};

  /// Lotos a entregar por la compra [purchaseId] de [productId]: 0 si ya se
  /// entregó o si el producto no es un paquete conocido.
  int deliver(String purchaseId, String productId) {
    final pack = packs.where((p) => p.id == productId).firstOrNull;
    if (pack == null || !delivered.add(purchaseId)) return 0;
    return pack.lotus;
  }
}

/// Venta de lotos con las compras de la tienda (App Store / Play). Se apaga
/// con `shop.lotusPacks.enabled` hasta que existan los productos.
class LotusStore {
  LotusStore._();
  static final instance = LotusStore._();

  late List<LotusPack> packs;
  late LotusLedger _ledger;
  late SharedPreferences _prefs;
  bool enabled = false;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Productos que devolvió la tienda (vacío si no hay o está apagada).
  final products = ValueNotifier<List<ProductDetails>>([]);

  Future<void> load(Balance balance) async {
    final s = balance.section('shop').sub('lotusPacks');
    packs = [for (final p in s.sections('packs')) (id: p.s('id'), lotus: p.i('lotus'))];
    enabled = s.flag('enabled');
    _prefs = await SharedPreferences.getInstance();
    _ledger = LotusLedger(packs, (_prefs.getStringList('lotus.delivered') ?? []).toSet());
    if (!enabled || kIsWeb) return;
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return;
      // Las compras que quedaron a medias se entregan al volver a abrir.
      _sub = iap.purchaseStream.listen(_onPurchases, onError: (Object e) => debugPrint('Compras: $e'));
      final res = await iap.queryProductDetails({for (final p in packs) p.id});
      products.value = [...res.productDetails]..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    } catch (e) {
      debugPrint('Tienda no disponible: $e');
    }
  }

  int lotusOf(ProductDetails product) => packs.firstWhere((p) => p.id == product.id).lotus;

  Future<void> buy(ProductDetails product) =>
      InAppPurchase.instance.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        final n = _ledger.deliver(p.purchaseID ?? '${p.productID}@${p.transactionDate}', p.productID);
        if (n > 0) {
          Progress.instance.grantLotus(n);
          await _prefs.setStringList('lotus.delivered', _ledger.delivered.toList());
        }
      }
      if (p.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(p);
    }
  }

  void dispose() => _sub?.cancel();
}
