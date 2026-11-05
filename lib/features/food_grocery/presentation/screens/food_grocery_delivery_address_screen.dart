import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../data/models/food_grocery_delivery_address.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryDeliveryAddressScreen extends ConsumerStatefulWidget {
  const FoodGroceryDeliveryAddressScreen({super.key});

  @override
  ConsumerState<FoodGroceryDeliveryAddressScreen> createState() =>
      _FoodGroceryDeliveryAddressScreenState();
}

class _FoodGroceryDeliveryAddressScreenState
    extends ConsumerState<FoodGroceryDeliveryAddressScreen> {
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    final delivery = ref.read(foodGroceryDeliveryProvider);
    _instructionsController = TextEditingController(
      text: delivery.deliveryInstructions,
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _openAddressForm({
    FoodGroceryDeliveryAddress? address,
  }) async {
    final result = await showModalBottomSheet<FoodGroceryDeliveryAddress>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(address: address),
    );

    if (result == null || !mounted) return;

    final notifier = ref.read(foodGroceryDeliveryProvider.notifier);
    if (address == null) {
      notifier.addAddress(result);
    } else {
      notifier.updateAddress(result);
    }
  }

  Future<void> _removeAddress(
    FoodGroceryDeliveryAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Remove address?',
            style: AppTextStyles.titleMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This address will be removed from your saved addresses.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'REMOVE',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ref.read(foodGroceryDeliveryProvider.notifier).removeAddress(address.id);
    }
  }

  void _continueToReview() {
    final delivery = ref.read(foodGroceryDeliveryProvider);
    if (delivery.selectedAddressId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please select a delivery address.'),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    ref
        .read(foodGroceryDeliveryProvider.notifier)
        .updateDeliveryInstructions(_instructionsController.text.trim());

    context.pushNamed(RouteNames.foodGroceryReviewOrder);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delivery = ref.watch(foodGroceryDeliveryProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(title: 'Delivery Address'),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SAVED ADDRESSES',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openAddressForm,
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: Text(
                          'Add Address',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryGoldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (delivery.addresses.isEmpty)
                    _EmptyAddressCard(
                      isDark: isDark,
                      onAdd: _openAddressForm,
                    )
                  else
                    ...delivery.addresses.map(
                      (address) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AddressCard(
                          isDark: isDark,
                          address: address,
                          isSelected: delivery.selectedAddressId == address.id,
                          onSelect: () => ref
                              .read(foodGroceryDeliveryProvider.notifier)
                              .selectAddress(address.id),
                          onEdit: () => _openAddressForm(address: address),
                          onRemove: () => _removeAddress(address),
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  _InstructionsCard(
                    isDark: isDark,
                    controller: _instructionsController,
                    onChanged: (value) => ref
                        .read(foodGroceryDeliveryProvider.notifier)
                        .updateDeliveryInstructions(value),
                  ),
                  const SizedBox(height: 13),
                  _DeliveryPreferenceCard(
                    isDark: isDark,
                    leaveAtDoor: delivery.leaveAtDoor,
                    onChanged: ref
                        .read(foodGroceryDeliveryProvider.notifier)
                        .setLeaveAtDoor,
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed:
                  delivery.selectedAddressId == null ? null : _continueToReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                disabledBackgroundColor:
                    AppColors.primaryGold.withValues(alpha: 0.45),
                foregroundColor: AppColors.backgroundDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to review',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.isDark,
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onRemove,
  });

  final bool isDark;
  final FoodGroceryDeliveryAddress address;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                address.label.toLowerCase().contains('work')
                    ? Icons.work_outline_rounded
                    : Icons.home_outlined,
                color: AppColors.primaryGoldDark,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryGold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryGoldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    address.fullAddress,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${address.recipientName} • ${address.phoneNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'EDIT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryGoldDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onRemove,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'REMOVE',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGold : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGold
                      : (isDark
                          ? AppColors.textSecondary
                          : AppColors.borderLight),
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddressCard extends StatelessWidget {
  const _EmptyAddressCard({required this.isDark, required this.onAdd});

  final bool isDark;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            color: AppColors.primaryGoldDark,
            size: 34,
          ),
          const SizedBox(height: 9),
          Text(
            'No saved addresses',
            style: AppTextStyles.bodyMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({
    required this.isDark,
    required this.controller,
    required this.onChanged,
  });

  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notes_rounded,
                color: AppColors.primaryGoldDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'DELIVERY INSTRUCTIONS',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 3,
            maxLines: 4,
            maxLength: 180,
            style: AppTextStyles.bodyMedium.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Example: Ring the bell or call when outside',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              contentPadding: const EdgeInsets.all(13),
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
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPreferenceCard extends StatelessWidget {
  const _DeliveryPreferenceCard({
    required this.isDark,
    required this.leaveAtDoor,
    required this.onChanged,
  });

  final bool isDark;
  final bool leaveAtDoor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                Icons.door_front_door_outlined,
                color: leaveAtDoor
                    ? AppColors.success
                    : isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'DELIVERY PREFERENCE',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave at the door',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'The delivery partner will leave the order safely at your door.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: leaveAtDoor,
                onChanged: onChanged,
                activeThumbColor: AppColors.primaryGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({this.address});

  final FoodGroceryDeliveryAddress? address;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _addressController;
  late final TextEditingController _localityController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _labelController = TextEditingController(text: address?.label ?? 'Home');
    _nameController = TextEditingController(text: address?.recipientName ?? '');
    _phoneController = TextEditingController(text: address?.phoneNumber ?? '');
    _apartmentController =
        TextEditingController(text: address?.apartmentDetails ?? '');
    _addressController =
        TextEditingController(text: address?.addressLine ?? '');
    _localityController = TextEditingController(text: address?.locality ?? '');
    _cityController = TextEditingController(text: address?.city ?? 'Malta');
    _postalController = TextEditingController(text: address?.postalCode ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _apartmentController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final existing = widget.address;
    Navigator.of(context).pop(
      FoodGroceryDeliveryAddress(
        id: existing?.id ??
            'temporary-address-${DateTime.now().millisecondsSinceEpoch}',
        label: _labelController.text.trim(),
        recipientName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        addressLine: _addressController.text.trim(),
        locality: _localityController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalController.text.trim(),
        apartmentDetails: _apartmentController.text.trim(),
        isDefault: existing?.isDefault ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.address == null ? 'Add address' : 'Edit address',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                18 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _AddressField(
                      controller: _labelController,
                      label: 'Address label',
                      hint: 'Home, Work or Other',
                      validator: _required,
                    ),
                    const SizedBox(height: 11),
                    _AddressField(
                      controller: _nameController,
                      label: 'Recipient name',
                      validator: _required,
                    ),
                    const SizedBox(height: 11),
                    _AddressField(
                      controller: _phoneController,
                      label: 'Phone number',
                      keyboardType: TextInputType.phone,
                      validator: _required,
                    ),
                    const SizedBox(height: 11),
                    _AddressField(
                      controller: _apartmentController,
                      label: 'Apartment / floor',
                      hint: 'Optional',
                    ),
                    const SizedBox(height: 11),
                    _AddressField(
                      controller: _addressController,
                      label: 'Street address',
                      validator: _required,
                    ),
                    const SizedBox(height: 11),
                    _AddressField(
                      controller: _localityController,
                      label: 'Locality',
                      validator: _required,
                    ),
                    const SizedBox(height: 11),
                    _AddressField(
                      controller: _cityController,
                      label: 'City / country',
                      validator: _required,
                    ),
                    const SizedBox(height: 11),
                    _AddressField(
                      controller: _postalController,
                      label: 'Postal code',
                      validator: _required,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: AppColors.backgroundDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          widget.address == null
                              ? 'Add Address'
                              : 'Save Changes',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
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
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
