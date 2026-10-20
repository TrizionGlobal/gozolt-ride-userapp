import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/food_grocery_delivery_address.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../widgets/food_grocery_header.dart';

class FoodGroceryDeliveryAddressScreen extends ConsumerStatefulWidget {
  const FoodGroceryDeliveryAddressScreen({
    super.key,
  });

  @override
  ConsumerState<FoodGroceryDeliveryAddressScreen> createState() =>
      _FoodGroceryDeliveryAddressScreenState();
}

class _FoodGroceryDeliveryAddressScreenState
    extends ConsumerState<FoodGroceryDeliveryAddressScreen> {
  late final TextEditingController _deliveryInstructionsController;

  @override
  void initState() {
    super.initState();

    final deliveryState = ref.read(
      foodGroceryDeliveryProvider,
    );

    _deliveryInstructionsController = TextEditingController(
      text: deliveryState.deliveryInstructions,
    );
  }

  @override
  void dispose() {
    _deliveryInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _showAddressForm({
    FoodGroceryDeliveryAddress? address,
  }) async {
    final result = await showModalBottomSheet<FoodGroceryDeliveryAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddressFormSheet(
          address: address,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final notifier = ref.read(
      foodGroceryDeliveryProvider.notifier,
    );

    if (address == null) {
      notifier.addAddress(result);
    } else {
      notifier.updateAddress(result);
      notifier.selectAddress(result.id);
    }
  }

  Future<void> _confirmRemoveAddress(
    FoodGroceryDeliveryAddress address,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
            'Are you sure you want to remove the '
            '${address.label} address?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'CANCEL',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
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

    if (shouldRemove != true || !mounted) {
      return;
    }

    ref.read(foodGroceryDeliveryProvider.notifier).removeAddress(address.id);
  }

  void _continueToReview() {
    final deliveryState = ref.read(
      foodGroceryDeliveryProvider,
    );

    if (!deliveryState.canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a delivery address.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    context.pushNamed(
      RouteNames.foodGroceryReviewOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deliveryState = ref.watch(
      foodGroceryDeliveryProvider,
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          const FoodGroceryHeader(
            title: 'Delivery Address',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24,
                ),
                children: [
                  _DeliveryInformationCard(
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),
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
                        onPressed: () {
                          _showAddressForm();
                        },
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 19,
                        ),
                        label: Text(
                          'ADD ADDRESS',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (deliveryState.addresses.isEmpty)
                    _EmptyAddressCard(
                      isDark: isDark,
                      onAddAddress: () {
                        _showAddressForm();
                      },
                    )
                  else
                    ...deliveryState.addresses.map(
                      (address) {
                        final isSelected =
                            address.id == deliveryState.selectedAddressId;

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: _AddressCard(
                            address: address,
                            isDark: isDark,
                            isSelected: isSelected,
                            onSelected: () {
                              ref
                                  .read(
                                    foodGroceryDeliveryProvider.notifier,
                                  )
                                  .selectAddress(
                                    address.id,
                                  );
                            },
                            onEdit: () {
                              _showAddressForm(
                                address: address,
                              );
                            },
                            onRemove: () {
                              _confirmRemoveAddress(
                                address,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  _SectionCard(
                    isDark: isDark,
                    title: 'DELIVERY INSTRUCTIONS',
                    icon: Icons.notes_rounded,
                    child: TextField(
                      controller: _deliveryInstructionsController,
                      maxLines: 3,
                      maxLength: 180,
                      onChanged: (value) {
                        ref
                            .read(
                              foodGroceryDeliveryProvider.notifier,
                            )
                            .updateDeliveryInstructions(
                              value,
                            );
                      },
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Example: Ring the bell or call when outside',
                        hintStyle: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        contentPadding: const EdgeInsets.all(13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
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
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    isDark: isDark,
                    title: 'DELIVERY PREFERENCE',
                    icon: Icons.door_front_door_outlined,
                    child: SwitchListTile.adaptive(
                      value: deliveryState.leaveAtDoor,
                      onChanged: (value) {
                        ref
                            .read(
                              foodGroceryDeliveryProvider.notifier,
                            )
                            .setLeaveAtDoor(value);
                      },
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: AppColors.primaryGold,
                      title: Text(
                        'Leave at the door',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'The delivery partner will leave '
                        'the order safely at your door.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                          height: 1.35,
                        ),
                      ),
                    ),
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
              onPressed: deliveryState.canContinue ? _continueToReview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.backgroundDark,
                disabledBackgroundColor:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                disabledForegroundColor: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONTINUE TO REVIEW',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryInformationCard extends StatelessWidget {
  const _DeliveryInformationCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(
          alpha: 0.11,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.primaryGold,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Choose the exact address where you want '
              'your food or groceries delivered.',
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDark,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
    required this.onRemove,
  });

  final FoodGroceryDeliveryAddress address;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  IconData get _addressIcon {
    switch (address.label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGold
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(
                    alpha: 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _addressIcon,
                  size: 20,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
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
                              color: AppColors.primaryGold.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryGold,
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${address.recipientName} • '
                      '${address.phoneNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        TextButton(
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.primaryGold,
                          ),
                          child: Text(
                            'EDIT',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onRemove,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.error,
                          ),
                          child: Text(
                            'REMOVE',
                            style: AppTextStyles.labelSmall.copyWith(
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
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.primaryGold : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGold
                        : (isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.backgroundDark,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.child,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final Widget child;

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
                icon,
                size: 19,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptyAddressCard extends StatelessWidget {
  const _EmptyAddressCard({
    required this.isDark,
    required this.onAddAddress,
  });

  final bool isDark;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
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
            Icons.add_location_alt_outlined,
            size: 38,
            color: AppColors.primaryGold,
          ),
          const SizedBox(height: 10),
          Text(
            'No saved address',
            style: AppTextStyles.titleSmall.copyWith(
              color:
                  isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Add an address to continue with delivery.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddAddress,
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text('ADD ADDRESS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGold,
              side: const BorderSide(
                color: AppColors.primaryGold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({
    this.address,
  });

  final FoodGroceryDeliveryAddress? address;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedLabel;
  late bool _isDefault;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _addressController;
  late final TextEditingController _localityController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();

    final address = widget.address;

    _selectedLabel = address?.label ?? 'Home';
    _isDefault = address?.isDefault ?? false;

    _nameController = TextEditingController(
      text: address?.recipientName ?? '',
    );
    _phoneController = TextEditingController(
      text: address?.phoneNumber ?? '',
    );
    _apartmentController = TextEditingController(
      text: address?.apartmentDetails ?? '',
    );
    _addressController = TextEditingController(
      text: address?.addressLine ?? '',
    );
    _localityController = TextEditingController(
      text: address?.locality ?? '',
    );
    _cityController = TextEditingController(
      text: address?.city ?? 'Malta',
    );
    _postalCodeController = TextEditingController(
      text: address?.postalCode ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _apartmentController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final previousAddress = widget.address;

    final address = FoodGroceryDeliveryAddress(
      id: previousAddress?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      label: _selectedLabel,
      recipientName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      apartmentDetails: _apartmentController.text.trim().isEmpty
          ? null
          : _apartmentController.text.trim(),
      addressLine: _addressController.text.trim(),
      locality: _localityController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      latitude: previousAddress?.latitude,
      longitude: previousAddress?.longitude,
      isDefault: _isDefault,
    );

    Navigator.pop(context, address);
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.address == null
                      ? 'Add delivery address'
                      : 'Edit delivery address',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ADDRESS LABEL',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final label in ['Home', 'Work', 'Other'])
                      ChoiceChip(
                        label: Text(label),
                        selected: _selectedLabel == label,
                        onSelected: (_) {
                          setState(() {
                            _selectedLabel = label;
                          });
                        },
                        selectedColor: AppColors.primaryGold,
                        backgroundColor: isDark
                            ? AppColors.cardDark
                            : AppColors.backgroundLight,
                        side: BorderSide(
                          color: _selectedLabel == label
                              ? AppColors.primaryGold
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                        ),
                        labelStyle: AppTextStyles.bodySmall.copyWith(
                          color: _selectedLabel == label
                              ? AppColors.backgroundDark
                              : (isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _AddressTextField(
                  controller: _nameController,
                  label: 'Recipient name',
                  hint: 'Enter recipient name',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _AddressTextField(
                  controller: _phoneController,
                  label: 'Phone number',
                  hint: '+356',
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                  validator: _requiredValidator,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _AddressTextField(
                  controller: _apartmentController,
                  label: 'Apartment / floor',
                  hint: 'Optional',
                  icon: Icons.apartment_outlined,
                  isDark: isDark,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _AddressTextField(
                  controller: _addressController,
                  label: 'Street address',
                  hint: 'House number and street',
                  icon: Icons.location_on_outlined,
                  isDark: isDark,
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _AddressTextField(
                  controller: _localityController,
                  label: 'Locality',
                  hint: 'Example: Ħal Luqa',
                  icon: Icons.map_outlined,
                  isDark: isDark,
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AddressTextField(
                        controller: _cityController,
                        label: 'Country',
                        hint: 'Malta',
                        icon: Icons.public_outlined,
                        isDark: isDark,
                        validator: _requiredValidator,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AddressTextField(
                        controller: _postalCodeController,
                        label: 'Postcode',
                        hint: 'LQA 1311',
                        icon: Icons.local_post_office_outlined,
                        isDark: isDark,
                        validator: _requiredValidator,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryGold,
                  checkColor: AppColors.backgroundDark,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Set as default address',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      widget.address == null
                          ? 'SAVE ADDRESS'
                          : 'UPDATE ADDRESS',
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
    );
  }
}

class _AddressTextField extends StatelessWidget {
  const _AddressTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
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
        prefixIcon: Icon(
          icon,
          size: 19,
          color: AppColors.primaryGold,
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
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
            width: 1.4,
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
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
