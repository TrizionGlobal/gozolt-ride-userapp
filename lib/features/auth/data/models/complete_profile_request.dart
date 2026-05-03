class CompleteProfileRequest {
  final String firstName;
  final String lastName;
  final String language;
  final String country;
  final String city;
  final String? homeAddress;
  final double? homeLatitude;
  final double? homeLongitude;
  final bool termsAccepted;
  final bool marketingConsent;

  const CompleteProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.language,
    required this.country,
    required this.city,
    this.homeAddress,
    this.homeLatitude,
    this.homeLongitude,
    required this.termsAccepted,
    required this.marketingConsent,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'language': language,
      'country': country,
      'city': city,
      if (homeAddress != null) 'homeAddress': homeAddress,
      if (homeLatitude != null) 'homeLatitude': homeLatitude,
      if (homeLongitude != null) 'homeLongitude': homeLongitude,
      'termsAccepted': termsAccepted,
      'marketingConsent': marketingConsent,
    };
  }
}
