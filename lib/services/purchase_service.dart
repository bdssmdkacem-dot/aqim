import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// يدير عملية شراء "إزالة الإعلانات" (منتج واحد غير قابل للاستهلاك عبر
/// Google Play Billing). معرّف المنتج أدناه يجب أن يطابق **بالضبط** ما
/// تُنشئه فـ Play Console (راجع README لخطوات الإنشاء).
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const String removeAdsProductId = 'remove_ads_lifetime';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? removeAdsProduct;
  bool storeAvailable = false;
  String? lastError;

  void Function()? _onAdsRemoved;

  Future<void> init({required void Function() onAdsRemoved}) async {
    _onAdsRemoved = onAdsRemoved;

    storeAvailable = await _iap.isAvailable();
    if (!storeAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );

    final response = await _iap.queryProductDetails({removeAdsProductId});
    if (response.productDetails.isNotEmpty) {
      removeAdsProduct = response.productDetails.first;
    }
  }

  Future<void> buyRemoveAds() async {
    final product = removeAdsProduct;
    if (product == null) {
      lastError = 'المنتج غير متوفر حاليًا. تأكد من اتصالك بالإنترنت وأن التطبيق مثبَّت من Google Play.';
      return;
    }
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == removeAdsProductId) {
            _onAdsRemoved?.call();
          }
          break;
        case PurchaseStatus.error:
          lastError = purchase.error?.message;
          break;
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }
      // إلزامي: بدونه قد يُسترجَع المبلغ للمستخدم تلقائيًا خلال 3 أيام.
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
