import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/app_state.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/theme/app_theme.dart';
import 'package:trulura/services/database_service/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.initialize();
  final appProvider = AppProvider();
  await appProvider.initialize();
  runApp(ProviderScope(child: MyApp(appProvider: appProvider)));
}

class MyApp extends StatelessWidget {
  final AppProvider appProvider;

  const MyApp({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter(appProvider: appProvider);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuraStateController()..initialize()),
        ChangeNotifierProvider(create: (_) => TruLuraModeController(TruLuraMode.aura)),
        ChangeNotifierProvider(create: (_) => ExperienceModeController(appProvider: appProvider)..initialize()),
      ],
      child: Builder(
        builder: (context) {
          final app = context.watch<AppProvider>();
          final themeData = switch (app.appearanceMode) {
            'light' => lightTheme,
            'neutral' => neutralTheme,
            'dark' => plainDarkTheme,
            _ => darkTheme,
          };
          return MaterialApp.router(
            title: 'TruLura',
            debugShowCheckedModeBanner: false,
            theme: themeData,
            darkTheme: themeData,
            themeMode: ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
