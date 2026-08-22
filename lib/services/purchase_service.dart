import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play subscription that removes Aqim ads.
///
/// The product must be created in Play Console as a subscription with an
/// auto-renewing monthly base plan. The store remains the source of truth for
/// the actual price and subscription status.
class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  static const String removeAdsProductId = 'remove_ads_monthly';

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

    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) => lastError = error.toString(),
    );

    final response = await _iap.queryProductDetails({removeAdsProductId});
    if (response.productDetails.isNotEmpty) {
      removeAdsProduct = response.productDetails.first;
    }

    // Restore active subscription entitlements after every app start. This is
    // important for reinstalls and new devices; Google Play remains the source
    // of truth for whether the monthly subscription is active.
    try {
      await _iap.restorePurchases();
    } catch (error) {
      lastError = error.toString();
    }
  }

  Future<void> buyRemoveAds() async {
    final product = removeAdsProduct;
    if (product == null) {
      lastError =
          'الاشتراك غير متوفر حاليًا. ثبّت التطبيق من Google Play وتحقق من اتصال الإنترنت.';
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    // Flutter's generic API uses buyNonConsumable for both non-consumables
    // and subscriptions. Google Play determines the subscription lifecycle.
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (error) {
      lastError = error.toString();
    }
  }

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

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  String get displayPrice => removeAdsProduct?.price ?? '29 د.م.';

  void dispose() {
    _subscription?.cancel();
  }
}
