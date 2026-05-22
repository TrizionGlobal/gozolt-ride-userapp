import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRedirectNotifier extends ChangeNotifier {
  void triggerRedirect() {
    notifyListeners();
  }
}

final authRedirectProvider = ChangeNotifierProvider<AuthRedirectNotifier>((ref) {
  return AuthRedirectNotifier();
});
