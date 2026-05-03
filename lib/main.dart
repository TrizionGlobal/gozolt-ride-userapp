import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  Stripe.publishableKey = AppConstants.stripePublishableKey;

  // Force dark status bar style for splash
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: GozoltApp()));
}
