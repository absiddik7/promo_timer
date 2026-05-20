import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';

class LifetimePaywallScreen extends StatefulWidget {
  const LifetimePaywallScreen({super.key});

  @override
  State<LifetimePaywallScreen> createState() => _LifetimePaywallScreenState();
}

class _LifetimePaywallScreenState extends State<LifetimePaywallScreen> {
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
    final success = await premium.buyLifetime();

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

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    _closeWhenPremiumUnlocked();
    final lifetimePrice = premium.lifetimePriceLabel;

    return Scaffold(
      backgroundColor: const Color(0xFF090B12),
      body: Stack(
        children: [
          const _PaywallBackdrop(),
          SafeArea(
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
                            Icons.diamond_rounded,
                            color: Color(0xFF140D04),
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Prefer to own it forever?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'One-time payment. Unlock everything permanently, no subscriptions ever.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
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
                        _BulletPoint('All premium candle colors and backgrounds'),
                        const SizedBox(height: 8),
                        _BulletPoint('Full premium sound library'),
                        const SizedBox(height: 8),
                        _BulletPoint('All future premium features included'),
                        const SizedBox(height: 8),
                        _BulletPoint('Forever access, cancel anytime'),
                        const SizedBox(height: 32),
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
                                    'Trusted payment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Processed securely through Google Play. Your access is tied to your account.',
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFF5D080),
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF5D080).withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lifetime access',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'One-time payment',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              lifetimePrice,
                              style: const TextStyle(
                                color: Color(0xFFF5D080),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            _isPurchasing ? 'Processing...' : 'Unlock forever',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: premium.isLoading ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Back'),
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

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 12),
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
