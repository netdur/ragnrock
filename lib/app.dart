import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macos_window_utils/widgets/titlebar_safe_area.dart';
import 'package:macos_window_utils/widgets/transparent_macos_sidebar.dart';
import 'features/search/search_binding.dart';
import 'features/search/search_screen.dart';
import 'features/sessions/sessions_binding.dart';
import 'features/settings/settings_binding.dart';
import 'features/settings/settings_screen.dart';
import 'widgets/splash_screen.dart';
class RagnrockApp extends StatelessWidget {
  const RagnrockApp({super.key});
  @override
  Widget build(BuildContext context) {
    return TransparentMacOSSidebar(
      child: GetMaterialApp(
        title: 'Ragnrock',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        initialRoute: '/splash',
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen()),
          GetPage(
            name: '/search',
            page: () => const TitlebarSafeArea(child: SearchScreen()),
            bindings: [SessionsBinding(), SearchBinding()],
          ),
          GetPage(
            name: '/settings',
            page: () => const TitlebarSafeArea(child: SettingsScreen()),
            binding: SettingsBinding(),
          ),
        ],
      ),
    );
  }
}