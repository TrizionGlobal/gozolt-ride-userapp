import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/airport_transfer_draft.dart';

final airportTransferDraftProvider =
    StateNotifierProvider<AirportTransferDraftNotifier, AirportTransferDraft>(
        (ref) {
  return AirportTransferDraftNotifier();
});

class AirportTransferDraftNotifier extends StateNotifier<AirportTransferDraft> {
  AirportTransferDraftNotifier() : super(const AirportTransferDraft());

  void update(AirportTransferDraft draft) {
    state = draft;
  }

  void reset() {
    state = const AirportTransferDraft();
  }
}
