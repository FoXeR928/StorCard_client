import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/services/app_info_service.dart';
import 'views/auth_gate.dart';

class DiscountCardsApp extends StatelessWidget {
  const DiscountCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final info = AppInfoService.instance.cached;
    return MaterialApp(
      title: info?.appName ?? 'Скидочные карты',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AuthGate(),
    );
  }
}
