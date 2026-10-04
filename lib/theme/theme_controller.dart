import 'package:flutter/material.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static ThemeMode get themeMode => themeModeNotifier.value;

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  static void setThemeModeFromString(String modeStr) {
    switch (modeStr) {
      case 'Light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'Dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      case 'System':
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }
  }

  static String get modeString {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
