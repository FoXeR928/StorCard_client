import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'views/auth_gate.dart';

class DiscountCardsApp extends StatelessWidget {
  const DiscountCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Скидочные карты',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AuthGate(),
    );
  }
}
