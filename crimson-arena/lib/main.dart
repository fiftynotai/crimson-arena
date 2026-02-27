import 'package:fifty_theme/fifty_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/bindings/app_bindings.dart';
import 'core/routing/app_pages.dart';
import 'core/routing/app_routes.dart';
import 'features/home/bindings/home_bindings.dart';
import 'features/home/views/home_page.dart';

Future<void> main() async {
  // Use path URL strategy for clean URLs on web.
  usePathUrlStrategy();

  // Initialize GetStorage for persistent key-value storage (project selector).
  await GetStorage.init();

  // Show error details visually in release mode (instead of grey screen).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            SelectableText(
              details.exceptionAsString(),
              style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            SelectableText(
              details.stack.toString().split('\n').take(10).join('\n'),
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  };

  runApp(const CrimsonArenaApp());
}

/// Root widget for the Crimson Arena dashboard.
///
/// Uses [GetMaterialApp] for routing and DI. Theme is driven by
/// [FiftyTheme.dark()] from the fifty_theme package (FDL v2).
/// Dark mode is the primary (and only) environment.
class CrimsonArenaApp extends StatelessWidget {
  const CrimsonArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CRIMSON ARENA',
      debugShowCheckedModeBanner: false,

      // FDL v2 dark theme from fifty_theme package.
      theme: FiftyTheme.dark(),
      darkTheme: FiftyTheme.dark(),
      themeMode: ThemeMode.dark,

      // Global service bindings (BrainApiService, WS, Cache, Pricing).
      initialBinding: AppBindings(),

      // Routing configuration.
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,

      // Catch unmatched routes (e.g. parameterized deep links) and redirect.
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const HomePage(),
        binding: HomeBindings(),
      ),

      // Transitions defined per-page in AppPages (slide from right).
      // FDL rule: NO FADES -- kinetic slide transitions only.
      defaultTransition: Transition.noTransition,
    );
  }
}
