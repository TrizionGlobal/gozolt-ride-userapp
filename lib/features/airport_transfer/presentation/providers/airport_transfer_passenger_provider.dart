import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/airport_transfer_passenger_details.dart';

final airportTransferPassengerDetailsProvider = StateNotifierProvider<
    AirportTransferPassengerDetailsNotifier, AirportTransferPassengerDetails>(
  (ref) {
    return AirportTransferPassengerDetailsNotifier();
  },
);

class AirportTransferPassengerDetailsNotifier
    extends StateNotifier<AirportTransferPassengerDetails> {
  AirportTransferPassengerDetailsNotifier()
      : super(
          const AirportTransferPassengerDetails(),
        );

  void update(
    AirportTransferPassengerDetails details,
  ) {
    state = details;
  }

  void updateMeetAndGreet(bool required) {
    state = state.copyWith(
      meetAndGreetRequired: required,
    );
  }

  void reset() {
    state = const AirportTransferPassengerDetails();
  }
}
