import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/services/app_info_service.dart';
import 'views/auth/auth_gate.dart';

class DiscountCardsApp extends StatelessWidget {
  const DiscountCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final info = AppInfoService.instance.cached;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // dynamic_color отдаёт ColorScheme из material_ui, а ThemeData
        // ждёт ColorScheme из flutter/material. Извлекаем seed-цвет
        // и пересобираем схему в нужном типе.
        final lightScheme = lightDynamic != null
            ? ColorScheme.fromSeed(
                seedColor: lightDynamic.primary,
                brightness: Brightness.light,
              )
            : null;
        final darkScheme = darkDynamic != null
            ? ColorScheme.fromSeed(
                seedColor: darkDynamic.primary,
                brightness: Brightness.dark,
              )
            : null;

        return MaterialApp(
          title: info?.appName ?? 'StorCard',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          theme: AppTheme.light(lightScheme),
          darkTheme: AppTheme.dark(darkScheme),
          home: const AuthGate(),
        );
      },
    );
  }
}
