import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/onboarding_action_button.dart';

class OnboardingScreen10 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const OnboardingScreen10({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingScreen10> createState() => _OnboardingScreen10State();
}

class _OnboardingScreen10State extends State<OnboardingScreen10> {
  final InAppReview _inAppReview = InAppReview.instance;
  bool _feedbackPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showFeedbackPrompt());
    });
  }

  Future<void> _showFeedbackPrompt() async {
    if (!mounted || _feedbackPromptShown) return;

    _feedbackPromptShown = true;

    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;

    final feedback = await showModalBottomSheet<_FeedbackResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141B2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _FeedbackSheet(
          onSubmit: (rating, message) {
            Navigator.of(context).pop(
              _FeedbackResult(rating: rating, message: message),
            );
          },
        );
      },
    );

    if (feedback == null) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'onboarding_feedback_v1',
      jsonEncode({
        'rating': feedback.rating,
        'message': feedback.message,
        'submittedAt': DateTime.now().toIso8601String(),
      }),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Thanks for the feedback.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Early feedback badge
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
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFFF5D080),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Early feedback',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Built for the first people to use it, and shaped by what they notice most.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No ratings yet, just real feedback about whether the timer feels calm, clear, and worth returning to.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Early feedback 1
                  _QuoteCard(
                    quote:
                        'Feels calm, focused, and surprisingly polished for a first release.',
                    author: 'Early feedback',
                  ),
                  const SizedBox(height: 20),
                  // Early feedback 2
                  _QuoteCard(
                    quote:
                        'The candle makes each session feel more intentional from the first tap.',
                    author: 'Early feedback',
                  ),
                  const SizedBox(height: 40),
                  // First-release note
                  const Text(
                    'Made to earn trust from the very first version.',
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
            child: OnboardingActionButton(
              label: 'Continue',
              onPressed: widget.onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackResult {
  final int rating;
  final String message;

  const _FeedbackResult({required this.rating, required this.message});
}

class _FeedbackSheet extends StatefulWidget {
  final void Function(int rating, String message) onSubmit;

  const _FeedbackSheet({required this.onSubmit});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final TextEditingController _messageController = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleMessageChanged);
  }

  void _handleMessageChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_rating, _messageController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How was your first session?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ratings matter later. For now, tell us what felt calming, confusing, or worth improving.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= _rating;

              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = starIndex;
                  });
                },
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isSelected
                      ? const Color(0xFFF5D080)
                      : Colors.white.withOpacity(0.35),
                  size: 30,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'What should feel better?',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.38)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFF5D080)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _rating == 0 && _messageController.text.trim().isEmpty
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5D080),
                    foregroundColor: const Color(0xFF16110A),
                    disabledBackgroundColor: Colors.white.withOpacity(0.18),
                    disabledForegroundColor: Colors.white.withOpacity(0.45),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Send feedback',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
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
