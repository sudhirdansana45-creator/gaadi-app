import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'core/router.dart';

import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
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
          builder: (context, routerChild) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF0F131D) : const Color(0xFFF6F8FC);
            final mediaQuery = MediaQuery.of(context);
            final clampedScaler = mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.35,
            );

            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: clampedScaler),
              child: Container(
                color: bg,
                child: SafeArea(
                  top: true,
                  bottom: false,
                  left: false,
                  right: false,
                  child: routerChild ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
