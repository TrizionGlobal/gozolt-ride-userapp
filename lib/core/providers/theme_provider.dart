import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the app's ThemeMode (dark by default).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
