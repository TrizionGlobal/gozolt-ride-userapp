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

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  try {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Initialize Firebase (for Push Notifications, but NOT for Phone Auth now)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set the background messaging handler early on, as a named top-level function
    // Skip on iOS in debug mode to prevent "FlutterEngine already invoked" hot restart crashes
    if (!kDebugMode || defaultTargetPlatform != TargetPlatform.iOS) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    // Initialize Stripe
    Stripe.publishableKey = AppConstants.stripePublishableKey;
    Stripe.urlScheme = 'com.gozolt';
    await Stripe.instance.applySettings();

    // Force dark status bar style and transparent navigation bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Initialize SharedPreferences
    final sharedPrefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sharedPrefs),
      ],
    );

    // Initialize notifications early so they work even if splash screen is bypassed
    container.read(notificationServiceProvider).initialize();

    runApp(UncontrolledProviderScope(
      container: container,
      child: const GozoltApp(),
    ));
  } catch (e, stack) {
    // If anything fails during startup, show the error on screen instead of freezing the splash!
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'CRASH DURING STARTUP:\n\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
