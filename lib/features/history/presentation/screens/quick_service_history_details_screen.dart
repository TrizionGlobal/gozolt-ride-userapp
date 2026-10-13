import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../quick_services/data/models/quick_service_history_model.dart';
import '../../../quick_services/presentation/providers/quick_services_booking_provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/widgets/booking_payment_sheet.dart';
import '../../../quick_services/data/models/quick_service_booking_data.dart';
import '../../../ride/data/models/saved_payment_method.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import 'quick_services_history_view.dart';
import 'quick_service_cancellation_success_screen.dart';

class QuickServiceHistoryDetailsScreen extends ConsumerStatefulWidget {
  final QuickServiceHistoryModel booking;

  const QuickServiceHistoryDetailsScreen({super.key, required this.booking});

  @override
  ConsumerState<QuickServiceHistoryDetailsScreen> createState() => _QuickServiceHistoryDetailsScreenState();
}

class _QuickServiceHistoryDetailsScreenState extends ConsumerState<QuickServiceHistoryDetailsScreen> with WidgetsBindingObserver {
  bool _isCancelling = false;
  late QuickServiceHistoryModel _booking;
  StreamSubscription? _socketSub;
  bool _isShowingPaymentResult = false;
  Timer? _pollingTimer;

  void _navigateToPaymentConfirmation({
    required double amount,
    required String paymentMethod,
    String? stripePaymentIntentId,
  }) {
    if (_isShowingPaymentResult || !mounted) return;
    _isShowingPaymentResult = true;

    context.pushNamed(
      RouteNames.quickServicePaymentConfirmation,
      extra: {
        'bookingId': _booking.id,
        'serviceTitle': _booking.serviceTitle,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'stripePaymentIntentId': stripePaymentIntentId,
        'onDone': () {
          _isShowingPaymentResult = false;
          Navigator.of(context).pop();
        },
      },
    ).then((_) {
      _isShowingPaymentResult = false;
    });
  }

  void _navigateToPaymentFailure({
    String? errorMessage,
    required double amount,
  }) {
    if (_isShowingPaymentResult || !mounted) return;
    _isShowingPaymentResult = true;

    context.pushNamed(
      RouteNames.quickServicePaymentFailure,
      extra: {
        'bookingId': _booking.id,
        'serviceTitle': _booking.serviceTitle,
        'amount': amount,
        'errorMessage': errorMessage,
        'onRetry': () {
          _isShowingPaymentResult = false;
          _openPaymentSheet();
        },
        'onCancel': () {
          _isShowingPaymentResult = false;
        },
      },
    ).then((_) {
      _isShowingPaymentResult = false;
    });
  }

  Future<void> _verifyPaymentStatus() async {
    if (_booking.status == 'COMPLETED' || !mounted) return;
    try {
      final res = await ref.read(quickServicesRepositoryProvider).verifyPayment(_booking.id);
      if (res['isPaid'] == true && mounted) {
        _pollingTimer?.cancel();
        setState(() {
          _booking = _booking.copyWith(
            status: 'COMPLETED',
          );
        });
        ref.invalidate(quickServicesHistoryProvider);
        final paidAmount = (res['amount'] is num)
            ? (res['amount'] as num).toDouble()
            : (double.tryParse(res['amount']?.toString() ?? '0') ??
                (double.tryParse(_booking.totalAmount.toString()) ?? 0.0));
        _navigateToPaymentConfirmation(
          amount: paidAmount,
          paymentMethod: 'Online Payment (Stripe)',
          stripePaymentIntentId: res['stripePaymentIntentId']?.toString(),
        );
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyPaymentStatus();
    }
  }

  void _openPaymentSheet() {
    final booking = _booking;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingPaymentSheet(
        currentType: booking.paymentMethodType != null 
            ? PaymentMethodType.values.firstWhere(
                (e) => e.name == booking.paymentMethodType?.toLowerCase(), 
                orElse: () => PaymentMethodType.cash,
              )
            : PaymentMethodType.cash,
        currentCardId: booking.paymentMethod,
        isQuickService: true,
        isQuickServicePostPayment: true,
        onConfirm: (type, {cardId}) async {
          try {
            final response = await ref.read(quickServicesRepositoryProvider).processPayment(booking.id, type.name, cardId);
            if (mounted) {
              setState(() {
                _booking = _booking.copyWith(
                  paymentMethodType: type.name,
                );
              });
              if (response['checkoutUrl'] != null && type.name == 'iban') {
                final url = Uri.parse(response['checkoutUrl']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening secure payment gateway...'), backgroundColor: AppColors.success));
                
                // Start polling periodically while user completes payment
                _pollingTimer?.cancel();
                _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
                  if (timer.tick > 40) {
                    timer.cancel();
                  } else {
                    _verifyPaymentStatus();
                  }
                });
              } else if (type.name == 'qrcode') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please scan the QR code displayed on the worker\'s device to pay.'), 
                    backgroundColor: AppColors.primaryGold,
                  ),
                );
                // Start polling periodically for payment confirmation after customer scans QR
                _pollingTimer?.cancel();
                _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
                  if (timer.tick > 60) {
                    timer.cancel();
                  } else {
                    _verifyPaymentStatus();
                  }
                });
              } else if (type.name == 'cash') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please hand cash to the worker. Awaiting worker confirmation.'), 
                    backgroundColor: AppColors.primaryGold,
                  ),
                );
                _pollingTimer?.cancel();
                _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
                  if (timer.tick > 60) {
                    timer.cancel();
                  } else {
                    _verifyPaymentStatus();
                  }
                });
              } else {
                final paidAmount = (response['amount'] is num)
                    ? (response['amount'] as num).toDouble()
                    : (double.tryParse(booking.totalAmount.toString()) ?? 0.0);
                _navigateToPaymentConfirmation(
                  amount: paidAmount,
                  paymentMethod: type.name == 'card' ? 'Saved Card' : 'Online Payment',
                  stripePaymentIntentId: response['stripePaymentIntentId']?.toString(),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              _navigateToPaymentFailure(
                errorMessage: e.toString(),
                amount: double.tryParse(booking.totalAmount.toString()) ?? 0.0,
              );
            }
          }
          return true;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    WidgetsBinding.instance.addObserver(this);
    _verifyPaymentStatus();
    
    // Listen to real-time WebSockets
    final socketService = ref.read(socketServiceProvider);
    _socketSub = socketService.onQuickServiceEvent.listen((event) {
      if (event['bookingId']?.toString().toLowerCase() == _booking.id.toLowerCase()) {
        if (event['eventType'] == 'quick-service:payment-success' || event['eventType'] == 'quick-service:completed') {
          if (mounted) {
            setState(() {
              _booking = _booking.copyWith(
                status: 'COMPLETED',
                options: event['options'] is Map ? Map<String, dynamic>.from(event['options']) : _booking.options,
              );
            });
            if (event['eventType'] == 'quick-service:payment-success') {
              final paidAmount = (event['amount'] is num)
                  ? (event['amount'] as num).toDouble()
                  : (double.tryParse(event['amount']?.toString() ?? '0') ?? (double.tryParse(_booking.totalAmount.toString()) ?? 0.0));
              _navigateToPaymentConfirmation(
                amount: paidAmount,
                paymentMethod: event['paymentMethod']?.toString() ?? 'Online Payment (Stripe)',
                stripePaymentIntentId: event['stripePaymentIntentId']?.toString(),
              );
            }
          }
          ref.invalidate(quickServicesHistoryProvider);
        } else if (event['eventType'] == 'quick-service:payment-failed') {
          if (mounted) {
            final failedAmount = (event['amount'] is num)
                ? (event['amount'] as num).toDouble()
                : (double.tryParse(event['amount']?.toString() ?? '0') ?? (double.tryParse(_booking.totalAmount.toString()) ?? 0.0));
            _navigateToPaymentFailure(
              errorMessage: event['reason']?.toString() ?? 'Payment was not completed. Please retry.',
              amount: failedAmount,
            );
          }
        } else if (event['eventType'] == 'quick-service:payment-method-selected') {
          if (mounted) {
            setState(() {
              _booking = _booking.copyWith(
                paymentMethodType: event['method'],
              );
            });
          }
        } else if (event['eventType'] == 'quick-service:assigned') {
          if (mounted) {
            setState(() {
              _booking = _booking.copyWith(
                status: event['status']?.toString() ?? 'ASSIGNED',
                supplier: event['supplier'] is Map ? Map<String, dynamic>.from(event['supplier']) : _booking.supplier,
              );
            });
          }
          ref.invalidate(quickServicesHistoryProvider);
        } else if (event['eventType'] == 'quick-service:started') {
          if (mounted) {
            setState(() {
              _booking = _booking.copyWith(
                status: event['status']?.toString() ?? 'IN_PROGRESS',
              );
            });
          }
          ref.invalidate(quickServicesHistoryProvider);
        } else if (event['eventType'] == 'quick-service:cancelled') {
          if (mounted) {
            setState(() {
              _booking = _booking.copyWith(
                status: 'CANCELLED',
              );
            });
          }
          ref.invalidate(quickServicesHistoryProvider);
        } else if (event['eventType'] == 'quick-service:payment-required') {
          if (mounted) {
            setState(() {
              _booking = _booking.copyWith(
                status: 'AWAITING_PAYMENT',
                totalAmount: event['totalAmount'] != null ? (event['totalAmount'] as num).toDouble() : null,
                options: event['options'] is Map ? Map<String, dynamic>.from(event['options']) : _booking.options,
              );
            });
          }
          ref.invalidate(quickServicesHistoryProvider);
        } else if (event['status'] != null || event['totalAmount'] != null) {
          if (mounted) {
            setState(() {
              _booking = _booking.copyWith(
                status: event['status']?.toString() ?? _booking.status,
                totalAmount: event['totalAmount'] != null ? (event['totalAmount'] as num).toDouble() : null,
                options: event['options'] is Map ? Map<String, dynamic>.from(event['options']) : _booking.options,
              );
            });
          }
          // Refresh parent history list so it stays in sync
          ref.invalidate(quickServicesHistoryProvider);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _socketSub?.cancel();
    super.dispose();
  }

  String _getExpertVisitName(String serviceTitle) {
    final lowerCat = serviceTitle.toLowerCase();
    if (lowerCat.contains('security') || lowerCat.contains('bouncer')) {
      return 'Hiring Person/hr';
    } else if (lowerCat.contains('mechanic')) {
      return 'Mechanic Visit/hr';
    } else if (lowerCat.contains('electric')) {
      if (lowerCat.contains('commercial') || lowerCat.contains('lift') || lowerCat.contains('events')) {
        return 'Mechanic Visit/hr';
      }
      return 'Expert Visit/hr';
    } else if (lowerCat.contains('engineer') || 
               lowerCat.contains('computer') ||
               lowerCat.contains('printer') ||
               lowerCat.contains('mobile') ||
               lowerCat.contains('technician')) {
      return 'Engineering Visit/hr';
    } else if (lowerCat.contains('wash')) {
      return 'Service Agent Visit/hr';
    }
    return 'Expert Visit/hr';
  }

  double _getQuickServiceHourlyRate(String serviceTitle) {
    final lowerCat = serviceTitle.toLowerCase();
    
    if (lowerCat.contains('plumber') || lowerCat.contains('carpenter')) return 20.00;
    if (lowerCat.contains('computer') || 
        lowerCat.contains('electric') || 
        lowerCat.contains('lift') || 
        lowerCat.contains('appliance') || 
        lowerCat.contains('printer') || 
        lowerCat.contains('mobile')) return 10.00;
    
    if (lowerCat.contains('mechanic')) {
      if (lowerCat.contains('car') || lowerCat.contains('truck')) return 9.00;
      if (lowerCat.contains('bike')) return 8.00;
      return 6.00;
    }
    
    if (lowerCat.contains('truck wash')) return 8.00;
    if (lowerCat.contains('security') || lowerCat.contains('hire person')) return 7.00;
    
    return 6.00;
  }

  static bool _isInternalOptionKey(String rawKey) {
    final key = rawKey.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const internalKeys = {
      'isvalidated',
      'validationpin',
      'beautytreatmentssubtotal',
      'startedat',
      'endedat',
      'finalhourlycost',
      'finaldurationhrs',
      'durationhours',
      'durationminutes',
      'hourlyrate',
      'serviceamount',
      'alreadypaid',
      'upfrontfee',
      'materialcost',
      'issuedescription',
      'requirements',
      'subtotal',
      'tax',
      'total',
    };
    return internalKeys.contains(key);
  }

  String _formatOptionKey(String key) {
    final result = key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .replaceAll('_', ' ')
        .trim();
    return result
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatOptionValue(dynamic val) {
    if (val == null) return '';
    if (val is num) {
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
    }
    final d = double.tryParse(val.toString());
    if (d != null && val.toString().contains('.')) {
      return d % 1 == 0 ? d.toInt().toString() : d.toStringAsFixed(2);
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final status = booking.status.toUpperCase();

    // Timing and work duration calculations
    final startedAtStr = booking.options['startedAt']?.toString();
    final endedAtStr = booking.options['endedAt']?.toString();
    final startedDate = startedAtStr != null ? DateTime.tryParse(startedAtStr)?.toLocal() : null;
    final endedDate = endedAtStr != null ? DateTime.tryParse(endedAtStr)?.toLocal() : null;

    final durationHoursVal = num.tryParse(booking.options['durationHours']?.toString() ?? '') ??
        num.tryParse(booking.options['finalDurationHrs']?.toString() ?? '');

    int durationMins = int.tryParse(booking.options['durationMinutes']?.toString() ?? '') ?? 0;
    if (durationMins <= 0 && startedDate != null && endedDate != null) {
      durationMins = endedDate.difference(startedDate).inMinutes;
    }
    if (durationMins <= 0 && durationHoursVal != null) {
      durationMins = (durationHoursVal.toDouble() * 60).round();
    }

    final bool isWorkEnded = (status == 'AWAITING_PAYMENT' || status == 'COMPLETED' || booking.options['endedAt'] != null || booking.options['finalHourlyCost'] != null);

    final int billedHours = durationHoursVal != null
        ? durationHoursVal.ceil()
        : (durationMins > 0 ? (durationMins / 60).ceil() : 1);
    final int displayBilledHours = billedHours < 1 ? 1 : billedHours;

    final double hourlyRateVal = double.tryParse(booking.options['hourlyRate']?.toString() ?? '') ??
        _getQuickServiceHourlyRate(booking.serviceTitle);
    final double rawServiceAmount = isWorkEnded
        ? (double.tryParse(booking.options['serviceAmount']?.toString() ?? '') ??
            (double.tryParse(booking.options['finalHourlyCost']?.toString() ?? '') ?? (displayBilledHours * hourlyRateVal)))
        : 0.0;
    final double serviceAmountVal = double.parse(rawServiceAmount.toStringAsFixed(2));

    final double alreadyPaidOnline = (booking.upfrontFee + booking.materialCost - booking.discountAmount).clamp(0.0, double.infinity);
    final double remainingBalance = (status == 'AWAITING_PAYMENT') ? serviceAmountVal : 0.0;

    final displayBookingId = 'GZ-QS-${booking.id.substring(0, 8).toUpperCase()}';
    final displayDate = DateFormat('dd MMM yyyy').format(booking.bookingDate);
    final displayTime = DateFormat('h:mm a').format(booking.bookingDate);
    
    // Extract Validation PIN
    String validationPin = '';
    if (booking.options != null && booking.options is Map<String, dynamic>) {
      validationPin = booking.options['validationPin']?.toString() ?? '';
    }

    final qrDataJson = '''
Service ID: $displayBookingId
Validation PIN: $validationPin
Service: ${booking.serviceTitle}
Date: $displayDate
Time: $displayTime
'''.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundDark.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.backgroundDark, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Booking Details',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pay Now Section
                  if (status == 'AWAITING_PAYMENT') ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryGold, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.payment, size: 48, color: AppColors.primaryGold),
                          const SizedBox(height: 16),
                          Text(
                            'Service Completed',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.backgroundDark, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _booking.paymentMethodType == 'cash'
                                ? 'Awaiting worker confirmation for cash payment.\n(Service Charge to Pay: €${serviceAmountVal.toStringAsFixed(2)})'
                                : _booking.paymentMethodType == 'qrcode'
                                    ? 'Please scan the QR code displayed on the worker\'s device to pay €${serviceAmountVal.toStringAsFixed(2)}.\nOnce paid, your booking will be confirmed automatically.'
                                    : 'Your quick service is completed. Please complete the service charge payment of €${serviceAmountVal.toStringAsFixed(2)} to finalize the booking.\n(Already Paid Online: €${alreadyPaidOnline.toStringAsFixed(2)})',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _openPaymentSheet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _booking.paymentMethodType == 'cash' || _booking.paymentMethodType == 'qrcode' ? Colors.grey[300] : AppColors.primaryGold,
                                foregroundColor: AppColors.backgroundDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                _booking.paymentMethodType == 'cash' || _booking.paymentMethodType == 'qrcode' ? 'Change Payment Method' :
                                _booking.paymentMethodType == 'iban' ? 'Complete Online Payment' :
                                'Pay Now', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (status == 'COMPLETED') ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success.withOpacity(0.5), width: 2),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, size: 48, color: AppColors.success),
                          const SizedBox(height: 16),
                          Text(
                            'Payment Completed!',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your quick service and payment have been successfully completed.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // QR Code Section
                  if (status != 'CANCELLED' && status != 'CANCELED' && status != 'AWAITING_PAYMENT' && status != 'COMPLETED') ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Present this to service person',
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: qrDataJson,
                            version: QrVersions.auto,
                            size: 150.0,
                            backgroundColor: Colors.transparent,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryGold : Colors.black,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryGold : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Service ID',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.grey, fontSize: 10),
                          ),
                          Text(
                            displayBookingId,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.0),
                          ),
                          if (status == 'PENDING' || status == 'ASSIGNED' || status == 'ACCEPTED' || status == 'IN_PROGRESS') ...[
                            const SizedBox(height: 16),
                            Container(
                              width: 150.0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'VALIDATION PIN',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primaryGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                    Text(
                                      booking.options['validationPin'] ?? 'N/A',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.backgroundDark,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Share this PIN with the worker to start the service',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],


                  // Booking Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: AppColors.primaryGold,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Booking Summary',
                                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Service Title
                        Row(
                          children: [
                            Icon(
                              booking.serviceTitle.toLowerCase() == 'beauty & wellness' ? Icons.spa : Icons.home_repair_service, 
                              size: 18, 
                              color: Colors.grey
                            ),
                            const SizedBox(width: 10),
                            Text(booking.serviceTitle, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Date & Time
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text('$displayDate • $displayTime', style: AppTextStyles.bodySmall),
                          ],
                        ),
                        
                        if (booking.location != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  booking.location!,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        if (booking.userName != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.person, size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer: ${booking.userName}', style: AppTextStyles.bodySmall),
                                    if (booking.userEmail != null) ...[
                                      const SizedBox(height: 2),
                                      Text('Email: ${booking.userEmail}', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                                    ],
                                    if (booking.userPhone != null) ...[
                                      const SizedBox(height: 2),
                                      Text('Phone: ${booking.userPhone}', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        if (booking.options.entries.where((e) => !_isInternalOptionKey(e.key) && e.value != null && e.value.toString().trim().isNotEmpty).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          ...booking.options.entries
                              .where((e) => !_isInternalOptionKey(e.key) && e.value != null && e.value.toString().trim().isNotEmpty)
                              .map((e) {
                            final label = _formatOptionKey(e.key);
                            if (e.value is List) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    ...(e.value as List).map((item) {
                                      if (item is Map) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8.0),
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: item.entries
                                                .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
                                                .map<Widget>((entry) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 6.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${_formatOptionKey(entry.key.toString())}: ', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey.shade700)),
                                                    Expanded(child: Text(_formatOptionValue(entry.value), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('• ', style: AppTextStyles.bodyMedium),
                                            Expanded(child: Text(_formatOptionValue(item), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey.shade700)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _formatOptionValue(e.value),
                                        textAlign: TextAlign.end,
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Work Duration & Timing Card
                  if (startedDate != null || endedDate != null || durationHoursVal != null || booking.options['finalHourlyCost'] != null || status == 'IN_PROGRESS' || status == 'AWAITING_PAYMENT' || status == 'COMPLETED') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.primaryGold,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Work & Duration Summary',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (startedDate != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Start Time', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700])),
                                Text(DateFormat('h:mm a').format(startedDate), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (endedDate != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('End Time', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700])),
                                Text(DateFormat('h:mm a').format(endedDate), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (durationMins > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Actual Duration', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700])),
                                Text(
                                  durationMins < 60 ? '$durationMins mins' : '${durationMins ~/ 60}h ${durationMins % 60}m',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Billed Duration', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700])),
                              Text(
                                '$displayBilledHours ${displayBilledHours == 1 ? 'hour' : 'hours'} (min 1 hr)',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Hourly Rate', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700])),
                              Text('€${hourlyRateVal.toStringAsFixed(2)}/hr', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Service Charge', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                '€${serviceAmountVal.toStringAsFixed(2)}',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Selected Add-ons Card (Matching Price Summary style)
                  // Selected Add-ons Card (Matching Price Summary style)
                  if (booking.addOns.where((a) => a is Map).isNotEmpty || (booking.requirements != null && booking.requirements!.trim().isNotEmpty) || (booking.images != null && booking.images!.isNotEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Add-ons & Details',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (booking.addOns.where((a) => a is Map).isNotEmpty)
                            ...booking.addOns.where((a) => a is Map).map((addon) {
                              String name = 'Unknown Add-on';
                              String countOrPrice = '';
                              if (addon is Map) {
                                name = addon['name']?.toString() ?? 'Unknown Add-on';
                                if (addon.containsKey('count') && addon['count'] != null) {
                                  countOrPrice = '${addon['count']}';
                                } else if (addon.containsKey('price') && addon['price'] != null) {
                                  countOrPrice = '€${addon['price']}';
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ),
                                    Text(
                                      countOrPrice,
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          
                          if (booking.addOns.where((a) => a is Map).isNotEmpty && ((booking.requirements != null && booking.requirements!.trim().isNotEmpty) || (booking.images != null && booking.images!.isNotEmpty)))
                            const Divider(height: 24),
                          
                          if (booking.requirements != null && booking.requirements!.trim().isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Issue description: ${booking.requirements!}',
                                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            if (booking.images != null && booking.images!.isNotEmpty) const SizedBox(height: 10),
                          ],

                          if (booking.images != null && booking.images!.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 10),
                                Text('Attached Photo (${booking.images!.length})', style: AppTextStyles.bodySmall),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: booking.images!.length,
                                      itemBuilder: (context, index) {
                                        final path = booking.images![index];
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(
                                              path,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                width: 40,
                                                height: 40,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, size: 16, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Supplier Details
                  if (booking.supplier != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier Details',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Company', style: AppTextStyles.bodyMedium),
                              Text(booking.supplier!['companyName'] ?? 'N/A', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Estimated Spare Price (Informational only - moved below Supplier Details)
                  if (booking.estimatedPrice != null && booking.estimatedPrice!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Spare Price',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(Estimate only, not included in total)',
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            booking.estimatedPrice!,
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.amber[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Price Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Summary',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // 1. Settled Online Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALREADY PAID ONLINE',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Upfront Booking Fee', style: AppTextStyles.bodyMedium),
                                  Text('€${booking.upfrontFee.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (booking.materialCost > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      booking.serviceCategory.toLowerCase().contains('wash')
                                          ? 'Cleaning Materials'
                                          : (booking.options['Material Preference']?.toString().toLowerCase().contains('tool') == true
                                              ? 'Tools Included'
                                              : (booking.options['Material Preference']?.toString().toLowerCase().contains('product') == true
                                                  ? 'Products Included'
                                                  : 'Materials Included')),
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    Text('€${booking.materialCost.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                              if (booking.discountAmount > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('GoCoins Discount', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryGold)),
                                    Text('-€${booking.discountAmount.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Settled Online', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                  Text(
                                    '€${(booking.upfrontFee + booking.materialCost - booking.discountAmount).toStringAsFixed(2)}',
                                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 2. Service Amount Section (Only shown once service has completed / work ended)
                        if (isWorkEnded) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SERVICE CHARGE (BILLED SEPARATELY)',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      (booking.serviceCategory.toLowerCase().contains('beauty') || booking.serviceCategory.toLowerCase().contains('wellness'))
                                          ? 'Selected Treatments'
                                          : 'Hourly Service ($displayBilledHours ${displayBilledHours == 1 ? 'hr' : 'hrs'} × €${hourlyRateVal.toStringAsFixed(2)})', 
                                      style: AppTextStyles.bodyMedium
                                    ),
                                    Text(
                                      '€${serviceAmountVal.toStringAsFixed(2)}', 
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold, 
                                        color: status == 'COMPLETED' ? Colors.green : AppColors.primaryGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Divider(),
                        const SizedBox(height: 12),

                        if (status == 'CANCELLED' || status == 'CANCELED') ...[
                          // For cancelled booking: show paid amount, refund status & policy
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Amount Paid Online',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '€${alreadyPaidOnline.toStringAsFixed(2)}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.materialCost > 0 ? 'Refund Initiated' : 'Booking Cancelled',
                                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    if (booking.materialCost > 0)
                                      Text(
                                        'Credited within 3-5 business days',
                                        style: AppTextStyles.labelSmall.copyWith(color: Colors.grey[500], fontSize: 10),
                                      ),
                                  ],
                                ),
                                if (booking.materialCost > 0)
                                  Text(
                                    '€${booking.materialCost.toStringAsFixed(2)}',
                                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                              ],
                            ),
                          ),
                          if (booking.upfrontFee > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Note: Upfront fee of €${booking.upfrontFee.toStringAsFixed(2)} is non-refundable.',
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.grey[500], fontStyle: FontStyle.italic),
                            ),
                          ],
                        ] else if (!isWorkEnded) ...[
                          // Before service completed: show ONLY already paid online amount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Amount Paid Online',
                                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '€${alreadyPaidOnline.toStringAsFixed(2)}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Note: Service charge is separate and will be billed upon completion.',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ] else ...[
                          // After work ended / completed: show already paid and service charge SEPARATELY (never combined)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Already Paid Online',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '€${alreadyPaidOnline.toStringAsFixed(2)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Service Amount',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '€${serviceAmountVal.toStringAsFixed(2)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (status == 'AWAITING_PAYMENT') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Service Amount Due',
                                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.error),
                                  ),
                                  Text(
                                    '€${serviceAmountVal.toStringAsFixed(2)}',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (status == 'COMPLETED') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Service Amount Status',
                                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: Colors.green[800]),
                                  ),
                                  Text(
                                    'Paid (€${serviceAmountVal.toStringAsFixed(2)})',
                                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (booking.paymentMethodType != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Payment Method', style: AppTextStyles.bodyMedium),
                                Text(
                                  booking.paymentMethodType!.toUpperCase(),
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (status == 'PENDING') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isCancelling ? null : () async {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final double estimatedRefund = booking.materialCost;
                          
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(context).cardTheme.color,
                              title: const Text('Cancel Booking'),
                              content: Text(
                                estimatedRefund > 0
                                    ? 'Are you sure you want to cancel this booking? A refund of €${estimatedRefund.toStringAsFixed(2)} will be credited to your original payment method within 3-5 business days.\n\nNote: Upfront booking fee (€${booking.upfrontFee.toStringAsFixed(2)}) is non-refundable.'
                                    : 'Are you sure you want to cancel this booking? Note: Upfront booking fee (€${booking.upfrontFee.toStringAsFixed(2)}) is non-refundable per platform policy.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text('NO', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(ctx).pop();

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
                                    );

                                    try {
                                      final response = await ref.read(quickServicesRepositoryProvider).cancelQuickServiceBooking(booking.id);
                                      
                                      ref.invalidate(quickServicesHistoryProvider);
                                      
                                      if (mounted) {
                                        Navigator.of(context).pop(); // dismiss loading dialog
                                        setState(() {
                                          _booking = _booking.copyWith(status: 'CANCELLED');
                                        });

                                        final double finalRefund = (response['refundAmount'] != null)
                                            ? (double.tryParse(response['refundAmount'].toString()) ?? estimatedRefund)
                                            : estimatedRefund;
                                        final String refundDays = response['refundDays']?.toString() ?? '3-5 business days';
                                        final String refundStatus = response['refundStatus']?.toString() ?? 'REFUNDED';

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => QuickServiceCancellationSuccessScreen(
                                              refundAmount: finalRefund,
                                              upfrontFee: booking.upfrontFee,
                                              refundDays: refundDays,
                                              refundStatus: refundStatus,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Navigator.of(context).pop(); // dismiss loading dialog
                                        final String errorMsg = e.toString().replaceAll('Exception: ', '');
                                        showDialog(
                                          context: context,
                                          builder: (errCtx) => AlertDialog(
                                            backgroundColor: Theme.of(context).cardTheme.color,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Row(
                                              children: [
                                                Icon(Icons.error_outline, color: AppColors.error, size: 28),
                                                SizedBox(width: 8),
                                                Text('Cancellation Failed', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            content: Text(
                                              errorMsg.isNotEmpty ? errorMsg : 'Unable to cancel this booking. Please try again or contact customer support.',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(errCtx).pop(),
                                                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('YES, CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isCancelling 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Cancel Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else if (status == 'IN_PROGRESS') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.engineering_outlined, color: AppColors.primaryGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'The assigned ${_getExpertVisitName(booking.serviceTitle).split('/').first} has arrived and already started their work.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.backgroundDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (status == 'ASSIGNED' || status == 'ACCEPTED') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primaryGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'The assigned ${_getExpertVisitName(booking.serviceTitle).split('/').first} will come to complete the service.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.backgroundDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusBg;
    Color statusText;
    String displayStatus;

    if (status == 'COMPLETED') {
        statusBg = AppColors.success.withOpacity(0.1);
        statusText = AppColors.success;
        displayStatus = 'Completed';
    } else if (status == 'CANCELLED' || status == 'CANCELED') {
        statusBg = AppColors.error.withOpacity(0.1);
        statusText = AppColors.error;
        displayStatus = 'Cancelled';
    } else if (status == 'ASSIGNED') {
        statusBg = AppColors.primaryGold.withOpacity(0.15);
        statusText = AppColors.primaryGold;
        displayStatus = 'Assigned';
    } else if (status == 'IN_PROGRESS') {
        statusBg = Colors.blue.withOpacity(0.15);
        statusText = Colors.blue;
        displayStatus = 'In Progress';
    } else if (status == 'AWAITING_PAYMENT') {
        statusBg = Colors.orange.withOpacity(0.15);
        statusText = Colors.orange;
        displayStatus = 'Awaiting Payment';
    } else {
        statusBg = AppColors.primaryGold.withOpacity(0.1);
        statusText = AppColors.primaryGold;
        displayStatus = 'Scheduled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayStatus,
        style: AppTextStyles.labelSmall.copyWith(color: statusText, fontWeight: FontWeight.bold),
      ),
    );
  }
}
