import 'package:flutter/material.dart';

/// Универсальный confirm-диалог. Возвращает true/false.
/// Заменяет ~10 копий одного и того же AlertDialog в проекте.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? content,
  String confirmLabel = 'OK',
  String cancelLabel = 'Отмена',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: destructive
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Диалог ввода строки (пароль, URL, логин для подтверждения и т.п.).
Future<String?> promptDialog(
  BuildContext context, {
  required String title,
  String? label,
  String? hint,
  String? initial,
  String confirmLabel = 'OK',
  bool obscure = false,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  final ctrl = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          obscureText: obscure,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: validator,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? true) {
              Navigator.pop(dialogCtx, ctrl.text.trim());
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).whenComplete(ctrl.dispose);
}

/// Короткий SnackBar. `error: true` → красный фон.
void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
}
