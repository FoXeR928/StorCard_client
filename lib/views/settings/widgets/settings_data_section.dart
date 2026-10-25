import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/dialogs.dart';
import '../../../data/services/sync_service.dart';
import '../../../viewmodels/cards_viewmodel.dart';

class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardsViewModel>();
    final sync = context.watch<SyncService>();
    final theme = Theme.of(context);
    final busy = sync.state == SyncState.syncing;
    final failed = sync.state == SyncState.error;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.credit_card_outlined),
          title: Text('Всего карт: ${vm.cards.length}'),
          subtitle: const Text('Локальная база SQLite'),
          trailing: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : failed
              ? Icon(Icons.sync_problem, color: theme.colorScheme.error)
              : const Icon(Icons.check_circle_outline, color: Colors.green),
          onTap: () {
            if (sync.state != SyncState.error) return;
            showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Ошибка синхронизации'),
                content: Text(sync.lastError ?? 'Неизвестная ошибка'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await sync.sync();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Экспорт карт в файл'),
          subtitle: const Text('Создать защищенный резервный файл'),
          onTap: () async {
            final pass = await promptDialog(
              context,
              title: 'Защита файла',
              label: 'Придумайте пароль для файла',
              obscure: true,
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Минимум 4 символа' : null,
            );
            if (pass != null && pass.isNotEmpty && context.mounted) {
              final err = await vm.exportToFile(pass);
              if (context.mounted) {
                if (err != null) {
                  showSnack(context, err, error: true);
                } else {
                  showSnack(context, 'Файл сформирован');
                }
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.download_for_offline),
          title: const Text('Импорт карт (JSON)'),
          subtitle: const Text('Вставить JSON из буфера обмена'),
          onTap: () async {
            final text = await promptDialog(
              context,
              title: 'Импорт',
              label: 'Вставьте JSON',
              maxLines: 5,
            );
            if (text != null && text.isNotEmpty && context.mounted) {
              final count = await vm.importFromJson(text);
              if (context.mounted)
                showSnack(context, 'Импортировано карт: $count');
            }
          },
        ),
      ],
    );
  }
}
