import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'core/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GaadiManagerApp());
}

class GaadiManagerApp extends StatelessWidget {
  const GaadiManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          title: 'Gaadi Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
