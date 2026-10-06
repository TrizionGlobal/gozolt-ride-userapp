import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../data/models/airport_transfer_passenger_details.dart';
import '../providers/airport_transfer_passenger_provider.dart';
import '../providers/airport_transfer_provider.dart';
import '../widgets/airport_transfer_header.dart';

class AirportTransferPassengerDetailsScreen extends ConsumerStatefulWidget {
  const AirportTransferPassengerDetailsScreen({
    super.key,
  });

  @override
  ConsumerState<AirportTransferPassengerDetailsScreen> createState() =>
      _AirportTransferPassengerDetailsScreenState();
}

class _AirportTransferPassengerDetailsScreenState
    extends ConsumerState<AirportTransferPassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _whatsAppController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _flightNumberController;
  late final TextEditingController _airlineController;
  late final TextEditingController _terminalController;
  late final TextEditingController _welcomeSignController;
  late final TextEditingController _meetInstructionsController;
  late final TextEditingController _assistanceController;

  bool _sameAsPhone = false;
  bool _meetAndGreetRequired = false;

  @override
  void initState() {
    super.initState();

    final saved = ref.read(airportTransferPassengerDetailsProvider);
    final draft = ref.read(airportTransferDraftProvider);

    _fullNameController = TextEditingController(text: saved.fullName);

    _phoneController = TextEditingController(text: saved.phoneNumber);

    _emailController = TextEditingController(text: saved.email);

    _whatsAppController = TextEditingController(text: saved.whatsAppNumber);

    _nationalityController = TextEditingController(text: saved.nationality);

    _flightNumberController = TextEditingController(
      text: saved.flightNumber.isNotEmpty
          ? saved.flightNumber
          : draft.flightNumber,
    );

    _airlineController = TextEditingController(text: saved.airline);

    _terminalController = TextEditingController(text: saved.arrivalTerminal);

    _welcomeSignController = TextEditingController(text: saved.welcomeSignName);

    _meetInstructionsController = TextEditingController(
      text: saved.meetAndGreetInstructions,
    );

    _assistanceController = TextEditingController(
      text: saved.specialAssistance,
    );

    _meetAndGreetRequired = saved.meetAndGreetRequired;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _whatsAppController.dispose();
    _nationalityController.dispose();
    _flightNumberController.dispose();
    _airlineController.dispose();
    _terminalController.dispose();
    _welcomeSignController.dispose();
    _meetInstructionsController.dispose();
    _assistanceController.dispose();
    super.dispose();
  }

  void _continueToReview() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final details = AirportTransferPassengerDetails(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      whatsAppNumber: _whatsAppController.text.trim(),
      nationality: _nationalityController.text.trim(),
      flightNumber: _flightNumberController.text.trim(),
      airline: _airlineController.text.trim(),
      arrivalTerminal: _terminalController.text.trim(),
      meetAndGreetRequired: _meetAndGreetRequired,
      welcomeSignName: _welcomeSignController.text.trim(),
      meetAndGreetInstructions: _meetInstructionsController.text.trim(),
      specialAssistance: _assistanceController.text.trim(),
    );

    ref
        .read(
          airportTransferPassengerDetailsProvider.notifier,
        )
        .update(details);

    context.pushNamed(
      RouteNames.airportTransferReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final draft = ref.watch(airportTransferDraftProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AirportTransferHeader(
            title: 'Passenger & Flight Details',
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  28,
                ),
                children: [
                  _PassengerSummaryCard(
                    isDark: isDark,
                    adults: draft.adults,
                    children: draft.children,
                    infants: draft.infants,
                    luggage: draft.totalLuggage,
                  ),
                  const SizedBox(height: 14),
                  _FormCard(
                    isDark: isDark,
                    title: 'PRIMARY PASSENGER',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildField(
                        isDark: isDark,
                        controller: _fullNameController,
                        label: 'Full name',
                        hint: 'Enter passenger full name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the passenger name';
                          }

                          if (value.trim().length < 3) {
                            return 'Enter a valid full name';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        isDark: isDark,
                        controller: _nationalityController,
                        label: 'Nationality',
                        hint: 'Enter nationality',
                        icon: Icons.public_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter nationality';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FormCard(
                    isDark: isDark,
                    title: 'CONTACT INFORMATION',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      _buildField(
                        isDark: isDark,
                        controller: _phoneController,
                        label: 'Phone number',
                        hint: 'Example: +356 7712 3456',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          if (_sameAsPhone) {
                            _whatsAppController.text = value;
                          }
                        },
                        validator: (value) {
                          final phone = value?.replaceAll(' ', '') ?? '';

                          if (phone.isEmpty) {
                            return 'Please enter a phone number';
                          }

                          if (phone.length < 7) {
                            return 'Enter a valid phone number';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        isDark: isDark,
                        controller: _emailController,
                        label: 'Email address',
                        hint: 'Enter email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Please enter an email address';
                          }

                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Enter a valid email address';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        isDark: isDark,
                        controller: _whatsAppController,
                        label: 'WhatsApp number',
                        hint: 'Enter WhatsApp number',
                        icon: Icons.chat_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        readOnly: _sameAsPhone,
                      ),
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        value: _sameAsPhone,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primaryGold,
                        title: Text(
                          'Same as phone number',
                          style: AppTextStyles.bodySmall,
                        ),
                        onChanged: (selected) {
                          setState(() {
                            _sameAsPhone = selected ?? false;

                            if (_sameAsPhone) {
                              _whatsAppController.text = _phoneController.text;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FormCard(
                    isDark: isDark,
                    title: 'FLIGHT INFORMATION',
                    icon: Icons.flight_rounded,
                    children: [
                      _buildField(
                        isDark: isDark,
                        controller: _flightNumberController,
                        label: 'Flight number',
                        hint: 'Example: KM 100',
                        icon: Icons.flight_takeoff_rounded,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the flight number';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        isDark: isDark,
                        controller: _airlineController,
                        label: 'Airline',
                        hint: 'Enter airline name',
                        icon: Icons.airlines_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        isDark: isDark,
                        controller: _terminalController,
                        label: 'Arrival terminal',
                        hint: 'Optional',
                        icon: Icons.location_city_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'The flight number helps the supplier monitor delays automatically.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FormCard(
                    isDark: isDark,
                    title: 'MEET & GREET',
                    icon: Icons.waving_hand_outlined,
                    children: [
                      SwitchListTile(
                        value: _meetAndGreetRequired,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primaryGold,
                        title: Text(
                          'Use Meet & Greet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Included with this transfer',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _meetAndGreetRequired = value;
                          });
                        },
                      ),
                      if (_meetAndGreetRequired) ...[
                        const SizedBox(height: 10),
                        _buildField(
                          isDark: isDark,
                          controller: _welcomeSignController,
                          label: 'Name on welcome sign',
                          hint: 'Enter the name to display',
                          icon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (_meetAndGreetRequired &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Enter the name for the welcome sign';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          isDark: isDark,
                          controller: _meetInstructionsController,
                          label: 'Meeting instructions',
                          hint: 'Example: Meet near the arrivals gate',
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FormCard(
                    isDark: isDark,
                    title: 'SPECIAL ASSISTANCE',
                    icon: Icons.accessible_rounded,
                    children: [
                      _buildField(
                        isDark: isDark,
                        controller: _assistanceController,
                        label: 'Special requirements',
                        hint:
                            'Child seat, wheelchair assistance or other request',
                        icon: Icons.support_agent_outlined,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GozoltButton(
                label: 'Continue',
                width: double.infinity,
                onPressed: _continueToReview,
              ),
              const SizedBox(height: 7),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Next: ',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Review & Book',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      readOnly: readOnly,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: AppColors.primaryGold,
        ),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryGold,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.children,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }
}

class _PassengerSummaryCard extends StatelessWidget {
  const _PassengerSummaryCard({
    required this.isDark,
    required this.adults,
    required this.children,
    required this.infants,
    required this.luggage,
  });

  final bool isDark;
  final int adults;
  final int children;
  final int infants;
  final int luggage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _SummaryItem(
            icon: Icons.person_outline_rounded,
            value: '$adults',
            label: adults == 1 ? 'Adult' : 'Adults',
          ),
          _SummaryDivider(isDark: isDark),
          _SummaryItem(
            icon: Icons.child_care_outlined,
            value: '${children + infants}',
            label: 'Children',
          ),
          _SummaryDivider(isDark: isDark),
          _SummaryItem(
            icon: Icons.luggage_outlined,
            value: '$luggage',
            label: luggage == 1 ? 'Bag' : 'Bags',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryGold,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
