import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../ride/data/models/location_data.dart';
import '../../data/models/airport_transfer_draft.dart';
import '../providers/airport_transfer_provider.dart';
import '../widgets/airport_transfer_location_search.dart';
import '../widgets/airport_transfer_header.dart';

class AirportTransferSearchScreen extends ConsumerStatefulWidget {
  const AirportTransferSearchScreen({super.key});

  @override
  ConsumerState<AirportTransferSearchScreen> createState() =>
      _AirportTransferSearchScreenState();
}

class _AirportTransferSearchScreenState
    extends ConsumerState<AirportTransferSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _flightNumberController = TextEditingController();
  final _returnFlightNumberController = TextEditingController();

  AirportTransferType _transferType = AirportTransferType.oneWay;

  LocationData? _pickupLocation;
  LocationData? _dropoffLocation;

  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;

  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _standardLuggage = 0;
  int _largeLuggage = 0;

  bool get _isRoundTrip => _transferType == AirportTransferType.roundTrip;

  @override
  void dispose() {
    _flightNumberController.dispose();
    _returnFlightNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation({required bool isPickup}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return AirportTransferLocationSearchSheet(
          showCurrentLocation: true,
          onSelect: (location) {
            Navigator.of(sheetContext).pop();

            setState(() {
              if (isPickup) {
                _pickupLocation = location;
              } else {
                _dropoffLocation = location;
              }
            });
          },
        );
      },
    );
  }

  Future<DateTime?> _showDatePicker({
    DateTime? initialDate,
    DateTime? firstDate,
  }) {
    final now = DateTime.now();
    final minimumDate = firstDate ?? now;

    return showDatePicker(
      context: context,
      initialDate: initialDate ?? minimumDate,
      firstDate: minimumDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGold,
                  onPrimary: Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _selectPickupDate() async {
    final selectedDate = await _showDatePicker(
      initialDate: _pickupDate,
    );

    if (selectedDate == null) return;

    setState(() {
      _pickupDate = selectedDate;

      if (_returnDate != null && _returnDate!.isBefore(selectedDate)) {
        _returnDate = null;
        _returnTime = null;
      }
    });
  }

  Future<void> _selectReturnDate() async {
    if (_pickupDate == null) {
      _showMessage('Select the pickup date first.');
      return;
    }

    final selectedDate = await _showDatePicker(
      initialDate: _returnDate ?? _pickupDate,
      firstDate: _pickupDate,
    );

    if (selectedDate == null) return;

    setState(() {
      _returnDate = selectedDate;
    });
  }

  Future<TimeOfDay?> _showCompactTimePicker(
    TimeOfDay initialTime,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              hourMinuteTextStyle: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? AppColors.textPrimary : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              hourMinuteColor: AppColors.primaryGold.withValues(
                alpha: 0.16,
              ),
              dialHandColor: AppColors.primaryGold,
              dialBackgroundColor:
                  isDark ? AppColors.cardDark : Colors.grey.shade100,
              dialTextColor: isDark ? AppColors.textPrimary : Colors.black87,
              entryModeIconColor: AppColors.primaryGold,
              helpTextStyle: AppTextStyles.labelSmall.copyWith(
                color: isDark ? AppColors.textSecondary : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGold,
                  onPrimary: Colors.white,
                  surface: isDark ? AppColors.surfaceDark : Colors.white,
                  onSurface: isDark ? AppColors.textPrimary : Colors.black87,
                ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _selectPickupTime() async {
    final selectedTime = await _showCompactTimePicker(
      _pickupTime ?? TimeOfDay.now(),
    );

    if (selectedTime == null) return;

    setState(() {
      _pickupTime = selectedTime;
    });
  }

  Future<void> _selectReturnTime() async {
    final selectedTime = await _showCompactTimePicker(
      _returnTime ?? TimeOfDay.now(),
    );

    if (selectedTime == null) return;

    setState(() {
      _returnTime = selectedTime;
    });
  }

  Future<void> _selectPassengers() async {
    int adults = _adults;
    int children = _children;
    int infants = _infants;

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return _CounterSheet(
              title: 'Passengers',
              rows: [
                _CounterRowData(
                  label: 'Adults',
                  description: 'Ages 13 and above',
                  value: adults,
                  minimum: 1,
                  onChanged: (value) {
                    updateSheet(() => adults = value);
                  },
                ),
                _CounterRowData(
                  label: 'Children',
                  description: 'Ages 2–12',
                  value: children,
                  onChanged: (value) {
                    updateSheet(() => children = value);
                  },
                ),
                _CounterRowData(
                  label: 'Infants',
                  description: 'Under 2 years',
                  value: infants,
                  onChanged: (value) {
                    updateSheet(() => infants = value);
                  },
                ),
              ],
              onDone: () {
                Navigator.of(sheetContext).pop({
                  'adults': adults,
                  'children': children,
                  'infants': infants,
                });
              },
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _adults = result['adults'] ?? 1;
      _children = result['children'] ?? 0;
      _infants = result['infants'] ?? 0;
    });
  }

  Future<void> _selectLuggage() async {
    int standard = _standardLuggage;
    int large = _largeLuggage;

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return _CounterSheet(
              title: 'Luggage',
              rows: [
                _CounterRowData(
                  label: 'Standard bags',
                  description: 'Cabin or regular suitcase',
                  value: standard,
                  onChanged: (value) {
                    updateSheet(() => standard = value);
                  },
                ),
                _CounterRowData(
                  label: 'Large bags',
                  description: 'Large or oversized suitcase',
                  value: large,
                  onChanged: (value) {
                    updateSheet(() => large = value);
                  },
                ),
              ],
              onDone: () {
                Navigator.of(sheetContext).pop({
                  'standard': standard,
                  'large': large,
                });
              },
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _standardLuggage = result['standard'] ?? 0;
      _largeLuggage = result['large'] ?? 0;
    });
  }

  String _timeForStorage(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  void _searchTransfers() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_pickupLocation == null) {
      _showMessage('Select a pickup location.');
      return;
    }

    if (_dropoffLocation == null) {
      _showMessage('Select a drop-off location.');
      return;
    }

    if (_pickupLocation!.address == _dropoffLocation!.address) {
      _showMessage(
        'Pickup and drop-off locations must be different.',
      );
      return;
    }

    if (_pickupDate == null) {
      _showMessage('Select a pickup date.');
      return;
    }

    if (_pickupTime == null) {
      _showMessage('Select a pickup time.');
      return;
    }

    if (_isRoundTrip) {
      if (_returnDate == null) {
        _showMessage('Select a return date.');
        return;
      }

      if (_returnTime == null) {
        _showMessage('Select a return time.');
        return;
      }
    }

    final draft = AirportTransferDraft(
      transferType: _transferType,
      pickupLocation: _pickupLocation,
      dropoffLocation: _dropoffLocation,
      pickupDate: _pickupDate,
      pickupTime: _timeForStorage(_pickupTime!),
      flightNumber: _flightNumberController.text.trim().toUpperCase(),
      returnDate: _returnDate,
      returnTime: _returnTime == null ? null : _timeForStorage(_returnTime!),
      returnFlightNumber:
          _returnFlightNumberController.text.trim().toUpperCase(),
      adults: _adults,
      children: _children,
      infants: _infants,
      standardLuggage: _standardLuggage,
      largeLuggage: _largeLuggage,
    );

    ref.read(airportTransferDraftProvider.notifier).update(draft);

    context.pushNamed(RouteNames.airportTransferChoose);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String get _passengerSummary {
    return '$_adults Adult${_adults == 1 ? '' : 's'}, '
        '$_children Child${_children == 1 ? '' : 'ren'}, '
        '$_infants Infant${_infants == 1 ? '' : 's'}';
  }

  String get _luggageSummary {
    if (_standardLuggage == 0 && _largeLuggage == 0) {
      return 'Add luggage';
    }

    return '$_standardLuggage Standard, $_largeLuggage Large';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ??
        (isDark ? AppColors.cardDark : Colors.white);

    return Scaffold(
      body: Column(
        children: [
          const AirportTransferHeader(
            title: 'Search Transfers',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    const SizedBox(height: 4),
                    _TransferTypeSelector(
                      value: _transferType,
                      onChanged: (value) {
                        setState(() {
                          _transferType = value;

                          if (!_isRoundTrip) {
                            _returnDate = null;
                            _returnTime = null;
                            _returnFlightNumberController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGold,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _SelectionTile(
                            label: 'PICKUP',
                            value: _pickupLocation?.address ??
                                'Select pickup location',
                            icon: Icons.circle,
                            iconSize: 16,
                            iconColor: AppColors.success,
                            isPlaceholder: _pickupLocation == null,
                            onTap: () => _selectLocation(isPickup: true),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 21,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 2,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primaryGold,
                                      width: 1,
                                    )),
                              ),
                            ),
                          ),
                          _SelectionTile(
                            label: 'DROP-OFF',
                            value: _dropoffLocation?.address ??
                                'Select drop-off location',
                            icon: Icons.circle,
                            iconSize: 16,
                            iconColor: AppColors.error,
                            isPlaceholder: _dropoffLocation == null,
                            onTap: () => _selectLocation(isPickup: false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SelectionTile(
                            label: 'DATE',
                            value: _pickupDate == null
                                ? 'Select date'
                                : DateFormat('dd MMM yyyy')
                                    .format(_pickupDate!),
                            icon: Icons.calendar_month_rounded,
                            isPlaceholder: _pickupDate == null,
                            onTap: _selectPickupDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectionTile(
                            label: 'TIME',
                            value: _pickupTime == null
                                ? 'Select time'
                                : _pickupTime!.format(context),
                            icon: Icons.schedule_rounded,
                            isPlaceholder: _pickupTime == null,
                            onTap: _selectPickupTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _flightNumberController,
                      textCapitalization: TextCapitalization.characters,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: isDark ? AppColors.textPrimary : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        hintText: 'Flight number',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textMutedLight,
                        ),
                        prefixIcon: const Icon(Icons.flight_rounded,
                            color: AppColors.textSecondaryLight),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Flight number is required';
                        }

                        if (value.trim().length < 3) {
                          return 'Enter a valid flight number';
                        }

                        return null;
                      },
                    ),
                    if (_isRoundTrip) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Return transfer',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SelectionTile(
                              label: 'RETURN DATE',
                              value: _returnDate == null
                                  ? 'Select date'
                                  : DateFormat('dd MMM yyyy')
                                      .format(_returnDate!),
                              icon: Icons.calendar_month_rounded,
                              isPlaceholder: _returnDate == null,
                              onTap: _selectReturnDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SelectionTile(
                              label: 'RETURN TIME',
                              value: _returnTime == null
                                  ? 'Select time'
                                  : _returnTime!.format(context),
                              icon: Icons.schedule_rounded,
                              isPlaceholder: _returnTime == null,
                              onTap: _selectReturnTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _returnFlightNumberController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 11,
                          ),
                          hintText: 'Return Flight number',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textSecondary
                                    : AppColors.textMutedLight,
                          ),
                          prefixIcon: const Icon(Icons.flight_rounded,
                              color: AppColors.textSecondaryLight),
                        ),
                        validator: (value) {
                          if (!_isRoundTrip) return null;

                          if (value == null || value.trim().isEmpty) {
                            return 'Return flight number is required';
                          }

                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    _SelectionTile(
                      label: 'PASSENGERS',
                      value: _passengerSummary,
                      icon: Icons.people_alt_outlined,
                      onTap: _selectPassengers,
                    ),
                    const SizedBox(height: 10),
                    _SelectionTile(
                      label: 'LUGGAGE',
                      value: _luggageSummary,
                      icon: Icons.luggage_outlined,
                      isPlaceholder:
                          _standardLuggage == 0 && _largeLuggage == 0,
                      onTap: _selectLuggage,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _searchTransfers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Search Transfers',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
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

class _TransferTypeSelector extends StatelessWidget {
  const _TransferTypeSelector({
    required this.value,
    required this.onChanged,
  });

  final AirportTransferType value;
  final ValueChanged<AirportTransferType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: SegmentedButton<AirportTransferType>(
        segments: const [
          ButtonSegment<AirportTransferType>(
            value: AirportTransferType.oneWay,
            icon: Icon(
              Icons.arrow_forward_rounded,
              size: 15,
            ),
            label: Text('One Way'),
          ),
          ButtonSegment<AirportTransferType>(
            value: AirportTransferType.roundTrip,
            icon: Icon(
              Icons.sync_alt_rounded,
              size: 15,
            ),
            label: Text('Round Trip'),
          ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          onChanged(selection.first);
        },
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8),
          ),
          visualDensity: VisualDensity.compact,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryGold
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.textSecondaryLight,
              width: 1.1,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primaryGold
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.black
                : isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.iconSize = 22,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final double iconSize;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).cardTheme.color ??
          (isDark ? AppColors.cardDark : Colors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.primaryGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark
                              ? AppColors.textSecondary
                              : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              isPlaceholder ? FontWeight.w400 : FontWeight.w600,
                          color: isPlaceholder
                              ? (isDark
                                  ? AppColors.textSecondary
                                  : Colors.black45)
                              : (isDark
                                  ? AppColors.textPrimary
                                  : Colors.black87),
                          height: 1.25),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? AppColors.textSecondary : Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterRowData {
  const _CounterRowData({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
  });

  final String label;
  final String description;
  final int value;
  final int minimum;
  final ValueChanged<int> onChanged;
}

class _CounterSheet extends StatelessWidget {
  const _CounterSheet({
    required this.title,
    required this.rows,
    required this.onDone,
  });

  final String title;
  final List<_CounterRowData> rows;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textSecondary : Colors.black38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark ? AppColors.textPrimary : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  row.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  row.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondary : Colors.black54,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      onPressed: row.value > row.minimum
                          ? () => row.onChanged(row.value - 1)
                          : null,
                      icon: const Icon(
                        Icons.remove,
                        size: 20,
                      ),
                    ),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${row.value}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:
                              isDark ? AppColors.textPrimary : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: row.value < 12
                          ? () => row.onChanged(row.value + 1)
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Done',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
