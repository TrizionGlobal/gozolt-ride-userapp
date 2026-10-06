import '../../../ride/data/models/location_data.dart';

enum AirportTransferType {
  oneWay,
  roundTrip,
}

class AirportTransferDraft {
  const AirportTransferDraft({
    this.transferType = AirportTransferType.oneWay,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupDate,
    this.pickupTime,
    this.flightNumber = '',
    this.returnDate,
    this.returnTime,
    this.returnFlightNumber = '',
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.standardLuggage = 0,
    this.largeLuggage = 0,
  });

  final AirportTransferType transferType;
  final LocationData? pickupLocation;
  final LocationData? dropoffLocation;

  final DateTime? pickupDate;
  final String? pickupTime;
  final String flightNumber;

  final DateTime? returnDate;
  final String? returnTime;
  final String returnFlightNumber;

  final int adults;
  final int children;
  final int infants;
  final int standardLuggage;
  final int largeLuggage;

  bool get isRoundTrip => transferType == AirportTransferType.roundTrip;

  int get totalPassengers => adults + children + infants;

  int get totalLuggage => standardLuggage + largeLuggage;

  AirportTransferDraft copyWith({
    AirportTransferType? transferType,
    LocationData? pickupLocation,
    LocationData? dropoffLocation,
    DateTime? pickupDate,
    String? pickupTime,
    String? flightNumber,
    DateTime? returnDate,
    String? returnTime,
    String? returnFlightNumber,
    int? adults,
    int? children,
    int? infants,
    int? standardLuggage,
    int? largeLuggage,
  }) {
    return AirportTransferDraft(
      transferType: transferType ?? this.transferType,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      flightNumber: flightNumber ?? this.flightNumber,
      returnDate: returnDate ?? this.returnDate,
      returnTime: returnTime ?? this.returnTime,
      returnFlightNumber: returnFlightNumber ?? this.returnFlightNumber,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      standardLuggage: standardLuggage ?? this.standardLuggage,
      largeLuggage: largeLuggage ?? this.largeLuggage,
    );
  }
}
