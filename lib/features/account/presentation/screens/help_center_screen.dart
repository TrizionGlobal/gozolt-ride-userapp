import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    // ── General ──────────────────────────────
    _FaqItem(
      category: 'General',
      question: 'What services can I book through GOZOLT?',
      answer:
          'GOZOLT lets you book cabs, rent cars and bikes, arrange airport transfers, and request trusted Quick Services. Availability may vary by location and time.',
    ),
    _FaqItem(
      category: 'General',
      question: 'How can I check whether a service is available in my area?',
      answer:
          'Select the required service and enter your location. The app will display the available options for your area.',
    ),
    _FaqItem(
      category: 'General',
      question: 'Where can I view my bookings?',
      answer:
          'Open "History" to view upcoming, active, completed, or cancelled bookings across all GOZOLT services.',
    ),

    // ── Cab Booking ───────────────────────────
    _FaqItem(
      category: 'Cab Booking',
      question: 'How do I book a cab?',
      answer:
          'Select "Cab Booking", enter your pickup and destination, choose an available vehicle, and confirm your booking.',
    ),
    _FaqItem(
      category: 'Cab Booking',
      question: 'Can I schedule a cab in advance?',
      answer:
          'Yes! After entering your destination, tap "Schedule Ride" to pick a date and time for your upcoming trip.',
    ),
    _FaqItem(
      category: 'Cab Booking',
      question: 'How can I contact my driver?',
      answer:
          'Once a driver accepts your booking, use the Call or Message option on the active booking screen.',
    ),
    _FaqItem(
      category: 'Cab Booking',
      question: 'Can I cancel my cab booking?',
      answer:
          'You can cancel from the active booking screen. Any applicable cancellation charge will be shown according to the booking conditions.',
    ),

    // ── Car Rental ────────────────────────────
    _FaqItem(
      category: 'Car Rental',
      question: 'How do I rent a car?',
      answer:
          'Select "Car Rental", enter the location, rental dates, times and delivery preference, then choose a vehicle and complete the booking details.',
    ),
    _FaqItem(
      category: 'Car Rental',
      question: 'What documents are required to rent a car?',
      answer:
          'You will need to provide your personal details and a valid driving licence. Additional documents may be requested by the rental supplier.',
    ),
    _FaqItem(
      category: 'Car Rental',
      question: 'Can the rental car be delivered to me?',
      answer:
          'Yes! Based on your selection self-pickup, supplier delivery or doorstep delivery. The available choices will be shown during your search.',
    ),
    _FaqItem(
      category: 'Car Rental',
      question: 'Can I add optional services to my car rental?',
      answer:
          'Available add-ons may include Wi-Fi, prepaid fuel, roadside assistance and premium cleaning. Options depend on the vehicle and supplier.',
    ),
    _FaqItem(
      category: 'Car Rental',
      question: 'What happens if I return the car late?',
      answer:
          'Late-return charges may apply according to the supplier\'s rental terms. Contact the supplier or support@gozolt.com.mt as early as possible if you expect a delay.',
    ),

    // ── Bike Rental ───────────────────────────
    _FaqItem(
      category: 'Bike Rental',
      question: 'How do I rent a bike or scooter?',
      answer:
          'Select "Bike Rental", enter the pickup and return details, choose a bike or scooter, provide the rider information, and confirm your booking.',
    ),
    _FaqItem(
      category: 'Bike Rental',
      question: 'What types of bikes can I rent?',
      answer:
          'Available options include standard bikes, electric bikes and scooters. The selection depends on your location and supplier availability.',
    ),
    _FaqItem(
      category: 'Bike Rental',
      question: 'Do I need a driving licence?',
      answer:
          'Yes! A valid licence is required depending on the selected bike or scooter and applicable local regulations. The requirement will be displayed before booking.',
    ),
    _FaqItem(
      category: 'Bike Rental',
      question: 'Can a rental bike be delivered to my location?',
      answer:
          'Yes! Delivery options may be available depending on the supplier and service area. Check the options displayed during your search.',
    ),

    // ── Airport Transfer ──────────────────────
    _FaqItem(
      category: 'Airport Transfer',
      question: 'How do I book an airport transfer?',
      answer:
          'Select "Airport Transfer", choose one-way or round-trip, enter your pickup, destination, travel time, flight and passenger details, then select a vehicle.',
    ),
    _FaqItem(
      category: 'Airport Transfer',
      question: 'Can I schedule an airport transfer in advance?',
      answer:
          'Yes. You can pre-schedule your transfer by selecting your travel date and pickup time. Same-day availability depends on available suppliers and drivers.',
    ),
    _FaqItem(
      category: 'Airport Transfer',
      question: 'Can I book a return airport transfer?',
      answer:
          'Yes. Select "Return" as the journey type and enter the details for both your outbound and return transfers.',
    ),
    _FaqItem(
      category: 'Airport Transfer',
      question: 'Why is my flight number required?',
      answer:
          'Your flight number helps the transfer provider identify your journey and prepare for possible flight timing changes.',
    ),
    _FaqItem(
      category: 'Airport Transfer',
      question: 'Can I include children, infants and luggage?',
      answer:
          'Yes. Enter the number of adults, children, infants and luggage while booking so that a suitable vehicle can be displayed.',
    ),

    // ── Quick Services ────────────────────────
    _FaqItem(
      category: 'Quick Services',
      question: 'How do I book a Quick Service?',
      answer:
          'Select "Quick Services", choose the required category, enter your location and schedule, provide the service details, and review your request before confirming.',
    ),
    _FaqItem(
      category: 'Quick Services',
      question: 'Can I add photos or describe the problem?',
      answer:
          'Yes. Where available, you can add a description and upload relevant photos to help the service professional understand your request.',
    ),
    _FaqItem(
      category: 'Quick Services',
      question: 'How is a service professional assigned?',
      answer:
          'GOZOLT assigns an eligible professional based on the selected service, location, availability and booking requirements.',
    ),
    _FaqItem(
      category: 'Quick Services',
      question: 'Can I reschedule or cancel a Quick Service?',
      answer:
          'Open the booking details to view the available rescheduling or cancellation options. Applicable charges or refund conditions will be displayed before confirmation.',
    ),
    _FaqItem(
      category: 'Quick Services',
      question: 'How do I contact the assigned professional?',
      answer:
          'Once a professional is assigned, the available contact options will appear in your booking details.',
    ),
    _FaqItem(
      category: 'Quick Services',
      question: 'What should I do if the service is incomplete or unsatisfactory?',
      answer:
          'Click on "Account" in Homepage, select "Contact Support" or mail to support@gozolt.com.mt and provide the details. GOZOLT support will review your request.',
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
          'GoCoins are our loyalty rewards. You earn GoCoins on every ride and can redeem them for ride discounts. Check the Rewards tab for details.',
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
          'Go to Account > Delete Account. Please note this action is permanent and all your data, GoCoins, and ride history will be deleted.',
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
                            onTap: () => context.pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundDark.withOpacity(0.15),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: AppColors.backgroundDark, size: 20),
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
