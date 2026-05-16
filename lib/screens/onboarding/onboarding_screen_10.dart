import 'package:flutter/material.dart';

class OnboardingScreen10 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen10({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Rating badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (_) {
                            return const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB400),
                                size: 20,
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          const Text(
                            '4.8 stars',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // User quote 1
                    _QuoteCard(
                      quote: 'Finally a timer I actually enjoy using.',
                      author: 'Sarah',
                    ),
                    const SizedBox(height: 20),
                    // User quote 2
                    _QuoteCard(
                      quote: 'The candle makes focus feel like a ritual.',
                      author: 'Alex',
                    ),
                    const SizedBox(height: 40),
                    // Stats
                    const Text(
                      'Join 50,000+ people who focus with a candle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB8A89F),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F1320),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const _QuoteCard({
    required this.quote,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '— $author',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
