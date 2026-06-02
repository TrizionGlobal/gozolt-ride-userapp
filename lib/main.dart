import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (for Push Notifications, but NOT for Phone Auth now)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Stripe
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  Stripe.urlScheme = 'com.gozolt';
  await Stripe.instance.applySettings();

  // Force dark status bar style for splash
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(sharedPrefs),
    ],
  );
  
  // Initialize Notification Service
  await container.read(notificationServiceProvider).initialize();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const GozoltApp(),
  ));
}
