import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final startupProvider = ChangeNotifierProvider<StartupNotifier>((ref) {
  return StartupNotifier();
});

class StartupNotifier extends ValueNotifier<bool> {
  StartupNotifier() : super(false);

  void markInitialized() {
    value = true;
  }
}
