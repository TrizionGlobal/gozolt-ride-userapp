import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/ride_history_item.dart';

Future<Uint8List> generateInvoicePdf(RideHistoryItem ride) async {
  final format = PdfPageFormat.a4;
  final actualFare = ride.actualFare ?? ride.estimatedFare ?? 0.0;
  final baseFare = ride.baseFare ?? 0.0;
  final distanceFare = ride.distanceFare ?? 0.0;
  final timeFare = ride.timeFare ?? 0.0;
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
                    pw.Text('Hi there,', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
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
                          pw.SizedBox(height: 8),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Time Charges'), pw.Text('EUR ${timeFare.toStringAsFixed(2)}')]),
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

class ReceiptScreen extends StatelessWidget {
  final String rideId;

  const ReceiptScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
