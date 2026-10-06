class AirportTransferPassengerDetails {
  const AirportTransferPassengerDetails({
    this.fullName = '',
    this.phoneNumber = '',
    this.email = '',
    this.whatsAppNumber = '',
    this.nationality = '',
    this.flightNumber = '',
    this.airline = '',
    this.arrivalTerminal = '',
    this.meetAndGreetRequired = false,
    this.welcomeSignName = '',
    this.meetAndGreetInstructions = '',
    this.specialAssistance = '',
  });

  final String fullName;
  final String phoneNumber;
  final String email;
  final String whatsAppNumber;
  final String nationality;

  final String flightNumber;
  final String airline;
  final String arrivalTerminal;

  final bool meetAndGreetRequired;
  final String welcomeSignName;
  final String meetAndGreetInstructions;
  final String specialAssistance;

  AirportTransferPassengerDetails copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? whatsAppNumber,
    String? nationality,
    String? flightNumber,
    String? airline,
    String? arrivalTerminal,
    bool? meetAndGreetRequired,
    String? welcomeSignName,
    String? meetAndGreetInstructions,
    String? specialAssistance,
  }) {
    return AirportTransferPassengerDetails(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
      nationality: nationality ?? this.nationality,
      flightNumber: flightNumber ?? this.flightNumber,
      airline: airline ?? this.airline,
      arrivalTerminal: arrivalTerminal ?? this.arrivalTerminal,
      meetAndGreetRequired: meetAndGreetRequired ?? this.meetAndGreetRequired,
      welcomeSignName: welcomeSignName ?? this.welcomeSignName,
      meetAndGreetInstructions:
          meetAndGreetInstructions ?? this.meetAndGreetInstructions,
      specialAssistance: specialAssistance ?? this.specialAssistance,
    );
  }
}
