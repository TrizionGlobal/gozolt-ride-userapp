import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/ride_history_item.dart';
import '../../presentation/providers/history_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';

Future<Uint8List> generateInvoicePdf(RideHistoryItem ride, {String? passengerName}) async {
  final format = PdfPageFormat.a4;
  final actualFare = ride.actualFare ?? ride.estimatedFare ?? 0.0;
  final baseFare = ride.baseFare ?? 0.0;
  final distanceFare = ride.distanceFare ?? 0.0;
  final timeFare = ride.waitTimeFee ?? 0.0;
  final bookingFee = ride.bookingFee ?? 0.0;
  final tip = ride.tipAmount ?? 0.0;
  final extraFare = ride.extraFare ?? 0.0;
  final totalPaid = actualFare;
  
  String dateStr = ride.createdAt;
  try {
    final dt = DateTime.parse(ride.createdAt);
    dateStr = DateFormat('dd MMM yyyy - hh:mm a').format(dt);
  } catch (_) {}

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: format.copyWith(
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
      ),
      build: (pw.Context context) {
        return pw.Container(
          color: const PdfColor.fromInt(0xFFFFFFFF),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                color: const PdfColor.fromInt(0xFF021F45),
                padding: const pw.EdgeInsets.all(32),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('GOZOLT', style: pw.TextStyle(color: const PdfColor.fromInt(0xFFFFD83A), fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text('The super app', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Thank you for riding with GOZOLT', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              // Body
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(passengerName != null && passengerName.isNotEmpty ? 'Hi $passengerName,' : 'Hi there,', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Here is your invoice for your recent ride. We hope you had a great experience with GOZOLT.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    pw.SizedBox(height: 24),

                    // Info Box
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Row(
                              children: [
                                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                  pw.Text('Trip ID', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                  pw.Text(ride.id, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                                ])),
                                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                  pw.Text('Date - Time', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                  pw.Text(dateStr, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                                ])),
                              ],
                            ),
                          ),
                          if (ride.driverName != null && ride.driverName!.isNotEmpty) ...[
                            pw.Divider(color: PdfColors.grey300, height: 1),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(12),
                              child: pw.Row(
                                children: [
                                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                    pw.Text('Driver', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                    pw.Text(ride.driverName!, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                                  ])),
                                  if (ride.driverVehicle != null || ride.driverPlate != null)
                                    pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                      pw.Text('Vehicle', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                      pw.Text('${ride.driverVehicle ?? ''} ${ride.driverPlate != null ? '(${ride.driverPlate})' : ''}'.trim(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                                    ])),
                                ],
                              ),
                            ),
                          ],
                          pw.Divider(color: PdfColors.grey300, height: 1),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('From', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                pw.Text(ride.pickupAddress, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                          pw.Divider(color: PdfColors.grey300, height: 1),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('To', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                pw.Text(ride.dropoffAddress, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 16),

                    // Fare Box
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      padding: const pw.EdgeInsets.all(16),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('FARE BREAKDOWN', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Text('AMOUNT (EUR)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.SizedBox(height: 12),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Base Fare'), pw.Text('EUR ${baseFare.toStringAsFixed(2)}')]),
                          pw.SizedBox(height: 8),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Distance Charges'), pw.Text('EUR ${distanceFare.toStringAsFixed(2)}')]),
                          if (timeFare > 0) ...[
                            pw.SizedBox(height: 8),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Wait Time Fee'), pw.Text('EUR ${timeFare.toStringAsFixed(2)}')]),
                          ],
                          pw.SizedBox(height: 8),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Booking Fee'), pw.Text('EUR ${bookingFee.toStringAsFixed(2)}')]),
                          
                          if (tip > 0) ...[
                            pw.SizedBox(height: 8),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Tip Added', style: const pw.TextStyle(color: PdfColors.green)), pw.Text('EUR ${tip.toStringAsFixed(2)}', style: const pw.TextStyle(color: PdfColors.green))]),
                          ],
                          if (extraFare > 0) ...[
                            pw.SizedBox(height: 8),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Extra Fare Added', style: const pw.TextStyle(color: PdfColors.green)), pw.Text('EUR ${extraFare.toStringAsFixed(2)}', style: const pw.TextStyle(color: PdfColors.green))]),
                          ],
                          
                          pw.SizedBox(height: 12),
                          pw.Divider(color: PdfColors.grey400),
                          pw.SizedBox(height: 12),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total Paid', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.Text('EUR ${totalPaid.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 16),

                    // Rewards
                    if ((ride.goCoinsEarned ?? 0) > 0) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFEEF8EA),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFD4EDCC)),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('REWARDS EARNED', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.Text('You earned ${ride.goCoinsEarned} coins from this ride', style: const pw.TextStyle(fontSize: 12)),
                              ],
                            ),
                            pw.Text('+${ride.goCoinsEarned}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 16),
                    ],

                    // Payment
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('PAYMENT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Text('${ride.paymentMethod ?? 'CASH'}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Text('PAID', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}

class ReceiptScreen extends ConsumerWidget {
  final String rideId;

  const ReceiptScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideDetailAsync = ref.watch(selectedRideDetailProvider(rideId));
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final passengerName = profile != null ? '${profile.firstName} ${profile.lastName}'.trim() : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ride Receipt'),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: rideDetailAsync.when(
        data: (ride) {
          return PdfPreview(
            build: (format) => generateInvoicePdf(ride, passengerName: passengerName),
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'Gozolt_Invoice_${ride.id.substring(0, 8)}.pdf',
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading receipt details',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => ref.refresh(selectedRideDetailProvider(rideId)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry'),
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
