import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import 'lifetime_paywall_screen.dart';

class PaywallScreen extends StatefulWidget {
  final String source;

  const PaywallScreen({super.key, this.source = 'app'});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PaywallPlan _selectedPlan = PaywallPlan.yearly;
  bool _isPurchasing = false;
  bool _didAutoClose = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _closeWhenPremiumUnlocked();
  }

  void _closeWhenPremiumUnlocked() {
    final premium = context.watch<PremiumProvider>();
    if (!premium.isPremium || _didAutoClose) return;

    _didAutoClose = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _purchase() async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    final premium = context.read<PremiumProvider>();
    final success = _selectedPlan == PaywallPlan.yearly
        ? await premium.buyYearly()
        : await premium.buyMonthly();

    if (!mounted) return;

    setState(() {
      _isPurchasing = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.read<PremiumProvider>().lastError ??
                  'Purchase could not be started yet.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Complete the purchase in Google Play.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _restore() async {
    final premium = context.read<PremiumProvider>();
    await premium.restorePurchases();
    if (!mounted) return;

    if (premium.isPremium) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('No active subscription found to restore.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showLifetimePaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LifetimePaywallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    _closeWhenPremiumUnlocked();
    final monthlyPrice = premium.monthlyPriceLabel;
    final yearlyPrice = premium.yearlyPriceLabel;

    return Scaffold(
      backgroundColor: const Color(0xFF090B12),
      body: Stack(
        children: [
          const _PaywallBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: premium.isLoading ? null : _restore,
                        child: const Text('Restore'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF7D38A), Color(0xFFB27A2A)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF5D080).withValues(alpha: 0.28),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF140D04),
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Unlock Candle Plus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Get every premium candle, background, and sound.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'What you get:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BulletPoint('All premium candle colors'),
                        const SizedBox(height: 6),
                        _BulletPoint('Premium backgrounds'),
                        const SizedBox(height: 6),
                        _BulletPoint('Full sound library'),
                        const SizedBox(height: 6),
                        _BulletPoint('Future premium features'),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: Colors.greenAccent.shade200,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Trusted subscription',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Billed securely through Google Play. Cancel anytime from your account settings.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _PricingCardHorizontal(
                              title: 'Monthly',
                              price: monthlyPrice,
                              highlighted: _selectedPlan == PaywallPlan.monthly,
                              onTap: () {
                                setState(() {
                                  _selectedPlan = PaywallPlan.monthly;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PricingCardHorizontal(
                              title: 'Yearly',
                              price: yearlyPrice,
                              highlighted: _selectedPlan == PaywallPlan.yearly,
                              badge: 'Best value',
                              onTap: () {
                                setState(() {
                                  _selectedPlan = PaywallPlan.yearly;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPurchasing || premium.isLoading || !premium.isAvailable
                              ? null
                              : _purchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5D080),
                            foregroundColor: const Color(0xFF16110A),
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.18),
                            disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _isPurchasing
                                ? 'Starting purchase...'
                                : _selectedPlan == PaywallPlan.yearly
                                    ? 'Continue yearly'
                                    : 'Continue monthly',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: premium.isLoading ? null : _showLifetimePaywall,
                        child: const Text('Not now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum PaywallPlan { monthly, yearly }

class _PaywallBackdrop extends StatelessWidget {
  const _PaywallBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.15, -0.85),
          radius: 1.2,
          colors: [
            Color(0xFF2A1E12),
            Color(0xFF120F16),
            Color(0xFF090B12),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowBlob(color: const Color(0xFFF5D080).withValues(alpha: 0.16), size: 220),
          ),
          Positioned(
            bottom: 90,
            left: -100,
            child: _GlowBlob(color: const Color(0xFFB9A6FF).withValues(alpha: 0.12), size: 260),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 12),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5D080),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PricingCardHorizontal extends StatelessWidget {
  final String title;
  final String price;
  final bool highlighted;
  final String? badge;
  final VoidCallback onTap;

  const _PricingCardHorizontal({
    required this.title,
    required this.price,
    required this.highlighted,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlighted ? const Color(0xFFF5D080) : Colors.white.withValues(alpha: 0.15),
            width: highlighted ? 2 : 1,
          ),
          gradient: highlighted
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF5D080).withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: highlighted ? null : Colors.white.withValues(alpha: 0.05),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: highlighted ? const Color(0xFFF5D080) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (highlighted)
              Positioned(
                top: 10,
                right: 10,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFFF5D080),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
