import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _faqItems = [
    _FaqItem(
      category: 'Rides',
      question: 'How do I book a ride?',
      answer:
          'Tap the "Ride" button on the home screen, enter your pickup and drop-off locations, select your preferred vehicle type, and confirm your booking.',
    ),
    _FaqItem(
      category: 'Rides',
      question: 'Can I schedule a ride in advance?',
      answer:
          'Yes! After entering your destination, tap "Schedule Ride" to pick a date and time for your upcoming trip.',
    ),
    _FaqItem(
      category: 'Rides',
      question: 'How do I cancel a ride?',
      answer:
          'You can cancel an active ride by tapping the "Cancel" button on the active ride screen. Please note that cancellation fees may apply depending on when you cancel.',
    ),
    _FaqItem(
      category: 'Rides',
      question: 'What vehicle types are available?',
      answer:
          'We offer Standard, Comfort, XL, Luxury, and Accessible vehicles. Each type has different pricing and features to suit your needs.',
    ),
    _FaqItem(
      category: 'Payments',
      question: 'What payment methods do you accept?',
      answer:
          'We accept Visa, Mastercard, and cash payments. You can add and manage cards in Account > Payment Methods.',
    ),
    _FaqItem(
      category: 'Payments',
      question: 'How do I get a receipt?',
      answer:
          'After each completed ride, you can view and download your receipt from the Trip Summary screen in My Rides.',
    ),
    _FaqItem(
      category: 'GoCoins',
      question: 'What are GoCoins?',
      answer:
          'GoCoins are our loyalty reward points. You earn GoCoins on every ride and can redeem them for ride discounts. Check the Rewards tab for details.',
    ),
    _FaqItem(
      category: 'GoCoins',
      question: 'How do I redeem GoCoins?',
      answer:
          'Go to the Rewards tab and tap "Redeem". You need a minimum of 200 GoCoins to redeem. The discount is automatically applied to your next ride.',
    ),
    _FaqItem(
      category: 'GoCoins',
      question: 'Do GoCoins expire?',
      answer:
          'GoCoins expire after 6 months of account inactivity. Keep riding to maintain your balance!',
    ),
    _FaqItem(
      category: 'Account',
      question: 'How do I update my profile?',
      answer:
          'Go to Account > Edit Profile to update your name, email, and profile photo. Phone number cannot be changed for security reasons.',
    ),
    _FaqItem(
      category: 'Account',
      question: 'How do I delete my account?',
      answer:
          'Go to Account > Delete Account. Please note this action is permanent and all your data, GoCoins, and ride history will be deleted. You can download your data first under Account > Download My Data.',
    ),
    _FaqItem(
      category: 'Safety',
      question: 'What is the SOS feature?',
      answer:
          'During an active ride, you can use the SOS button to alert emergency services. This will share your current location and ride details.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqItems;
    final query = _searchQuery.toLowerCase();
    return _faqItems
        .where((f) =>
            f.question.toLowerCase().contains(query) ||
            f.answer.toLowerCase().contains(query) ||
            f.category.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;
    final categories = faqs.map((f) => f.category).toSet().toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                              ),
                              child: Icon(Icons.arrow_back,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Help Center',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.backgroundDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search FAQs...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── FAQ List ───────────────────────────────
          if (faqs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('No results found',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (final category in categories) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 8, left: 4),
                      child: Text(
                        category.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...faqs
                        .where((f) => f.category == category)
                        .map((faq) => _FaqTile(faq: faq)),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _expanded
                  ? AppColors.primaryGold.withOpacity(0.3)
                  : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
            ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight:
                          _expanded ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.faq.answer,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
