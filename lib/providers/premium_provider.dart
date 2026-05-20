import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumProvider extends ChangeNotifier {
  static const String _entitlementKey = 'premiumUnlocked';
  static const String monthlyProductId = 'candle_timer_premium_monthly';
  static const String yearlyProductId = 'candle_timer_premium_yearly';
  static const String lifetimeProductId = 'candle_timer_premium_lifetime';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Map<String, ProductDetails> _products = {};

  bool _isLoading = false;
  bool _isAvailable = true;
  bool _isPremium = false;
  String? _lastError;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  String? get lastError => _lastError;

  ProductDetails? get monthlyProduct => _products[monthlyProductId];
  ProductDetails? get yearlyProduct => _products[yearlyProductId];
  ProductDetails? get lifetimeProduct => _products[lifetimeProductId];

  String get monthlyPriceLabel => monthlyProduct?.price ?? '\$1.99';
  String get yearlyPriceLabel => yearlyProduct?.price ?? '\$19.99';
  String get lifetimePriceLabel => lifetimeProduct?.price ?? '\$29.99';

  PremiumProvider() {
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_entitlementKey) ?? false;

    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (_isAvailable) {
        final response = await _inAppPurchase.queryProductDetails({
          monthlyProductId,
          yearlyProductId,
          lifetimeProductId,
        });

        for (final product in response.productDetails) {
          _products[product.id] = product;
        }

        _lastError = response.error?.message;

        _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
          _handlePurchaseUpdates,
          onError: (_) {},
        );
      }
    } catch (error) {
      _isAvailable = false;
      _lastError = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _unlockPremium();
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _unlockPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_entitlementKey, true);
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _inAppPurchase.restorePurchases();
  }

  Future<bool> buyMonthly() async {
    return _buyProduct(monthlyProduct);
  }

  Future<bool> buyYearly() async {
    return _buyProduct(yearlyProduct);
  }

  Future<bool> buyLifetime() async {
    return _buyProduct(lifetimeProduct);
  }

  Future<bool> _buyProduct(ProductDetails? product) async {
    if (product == null || !_isAvailable) {
      _lastError = 'Purchases are not available yet.';
      notifyListeners();
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    final success = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    return success;
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription?.cancel());
    super.dispose();
  }
}
