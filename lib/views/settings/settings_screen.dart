import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/section_header.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/sync_service.dart';
import 'widgets/settings_account_section.dart';
import 'widgets/settings_admin_section.dart';
import 'widgets/settings_app_section.dart';
import 'widgets/settings_sync_section.dart';
import 'widgets/settings_display_section.dart';
import 'widgets/settings_data_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final sync = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SectionHeader('Аккаунт'),
          SettingsAccountSection(auth: auth),

          const SectionHeader('Синхронизация'),
          SettingsSyncSection(sync: sync, auth: auth),

          const SectionHeader('Данные'),
          const SettingsDataSection(),

          const SectionHeader('Отображение'),
          const SettingsDisplaySection(),

          if (auth.isAdmin) ...[
            const SectionHeader('Администратору', accent: true),
            const SettingsAdminSection(),
          ],

          const SectionHeader('О приложении'),
          const SettingsAppSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
