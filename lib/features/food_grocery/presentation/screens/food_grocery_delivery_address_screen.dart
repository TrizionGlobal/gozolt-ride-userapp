import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/food_grocery_delivery_address.dart';
import '../providers/food_grocery_cart_provider.dart';
import '../providers/food_grocery_delivery_provider.dart';
import '../widgets/food_grocery_header.dart';

/// Opens the Add / Edit delivery address modal sheet, pre-filling street,
/// locality, and coordinates from the accessed GPS location (without
/// pre-filling user's default name or phone number).
Future<void> showFoodGroceryAddressFormSheet(
  BuildContext context,
  WidgetRef ref, {
  FoodGroceryDeliveryAddress? address,
}) async {
  final currentLoc =
      ref.read(foodGroceryDeliveryProvider).currentLocationAddress;

  final result = await showModalBottomSheet<FoodGroceryDeliveryAddress>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _AddressFormSheet(
        address: address,
        currentLocation: currentLoc,
      );
    },
  );

  if (result == null || !context.mounted) {
    return;
  }

  final notifier = ref.read(
    foodGroceryDeliveryProvider.notifier,
  );

  if (address == null) {
    await notifier.addAddress(result);
  } else {
    await notifier.updateAddress(result);
    notifier.selectAddress(result.id);
  }
}

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
  }) =>
      showFoodGroceryAddressFormSheet(context, ref, address: address);

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

  void _continueToReview({bool isFromCart = true}) {
    final deliveryState = ref.read(
      foodGroceryDeliveryProvider,
    );

    if (!deliveryState.canContinue) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Please complete and save your delivery details to continue.',
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

    if (isFromCart) {
      context.pushNamed(
        RouteNames.foodGroceryReviewOrder,
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deliveryState = ref.watch(
      foodGroceryDeliveryProvider,
    );
    final cart = ref.watch(foodGroceryCartProvider);
    final isFromCart = cart.items.isNotEmpty;

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
                          'Saved Addresses',
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
                          'Add Address',
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
                  if (deliveryState.addresses.isEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please complete and save your delivery details to continue.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _EmptyAddressCard(
                      isDark: isDark,
                      onAddAddress: () {
                        _showAddressForm();
                      },
                    ),
                  ]
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
              onPressed: () => _continueToReview(isFromCart: isFromCart),
              style: ElevatedButton.styleFrom(
                backgroundColor: deliveryState.canContinue
                    ? AppColors.primaryGold
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                foregroundColor: deliveryState.canContinue
                    ? AppColors.backgroundDark
                    : (isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondaryLight),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFromCart
                        ? 'CONTINUE TO REVIEW'
                        : 'CONFIRM DELIVERY ADDRESS',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isFromCart
                        ? Icons.arrow_forward_rounded
                        : Icons.check_circle_outline_rounded,
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
            label: const Text('Add Address'),
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
    this.currentLocation,
  });

  final FoodGroceryDeliveryAddress? address;
  final FoodGroceryDeliveryAddress? currentLocation;

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

  String _city = 'Malta';
  String _postalCode = '';
  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();

    final address = widget.address;
    final currentLoc = widget.currentLocation;

    _selectedLabel = address?.label ?? 'Home';
    _isDefault = address?.isDefault ?? false;
    _latitude = address?.latitude ?? currentLoc?.latitude;
    _longitude = address?.longitude ?? currentLoc?.longitude;

    final initialName = address?.recipientName ?? '';
    final initialPhone = address?.phoneNumber ?? '';

    String initialAddressLine = address?.addressLine ?? '';
    if (initialAddressLine.isEmpty && currentLoc != null) {
      if (currentLoc.addressLine.isNotEmpty &&
          currentLoc.addressLine.toLowerCase() != 'current location') {
        initialAddressLine = currentLoc.addressLine;
      }
    }

    String initialLocality = address?.locality ?? '';
    if (initialLocality.isEmpty && currentLoc != null) {
      if (currentLoc.locality.isNotEmpty &&
          currentLoc.locality.toLowerCase() != 'current location') {
        initialLocality = currentLoc.locality;
      }
    }

    _city = address?.city ?? currentLoc?.city ?? 'Malta';
    _postalCode = address?.postalCode ?? currentLoc?.postalCode ?? '';

    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: initialPhone);
    _apartmentController = TextEditingController(
      text: address?.apartmentDetails ?? '',
    );
    _addressController = TextEditingController(text: initialAddressLine);
    _localityController = TextEditingController(text: initialLocality);
  }

  Future<void> _autoFillFromGps() async {
    setState(() => _isDetectingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isDetectingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;
          if (p.street?.isNotEmpty == true) {
            _addressController.text = p.street!;
          }
          if (p.locality?.isNotEmpty == true) {
            _localityController.text = p.locality!;
            _city = p.locality!;
          } else if (p.subLocality?.isNotEmpty == true) {
            _localityController.text = p.subLocality!;
          }
          if (p.postalCode?.isNotEmpty == true) {
            _postalCode = p.postalCode!;
          }
        }
      } catch (_) {
        // Fallback: coordinates preserved in _latitude and _longitude
      }
    } catch (_) {
      // Ignored
    }
    if (mounted) setState(() => _isDetectingLocation = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _apartmentController.dispose();
    _addressController.dispose();
    _localityController.dispose();
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
      city: _city.trim().isNotEmpty ? _city.trim() : 'Malta',
      postalCode: _postalCode.trim(),
      latitude: _latitude ?? previousAddress?.latitude,
      longitude: _longitude ?? previousAddress?.longitude,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
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
                    ),
                    TextButton.icon(
                      onPressed:
                          _isDetectingLocation ? null : _autoFillFromGps,
                      icon: _isDetectingLocation
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGold),
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              size: 16,
                            ),
                      label: Text(
                        _isDetectingLocation
                            ? 'Detecting...'
                            : 'Use GPS',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Address Label',
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
                  textInputAction: TextInputAction.done,
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
                          ? 'Save Address'
                          : 'Update Address',
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
