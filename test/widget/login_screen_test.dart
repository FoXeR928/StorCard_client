import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storcard_client/data/models/auth_result.dart';
import 'package:storcard_client/data/services/admin_service.dart';
import 'package:storcard_client/data/services/auth_service.dart';
import 'package:storcard_client/viewmodels/login_viewmodel.dart';
import 'package:storcard_client/views/login_screen.dart';

class _FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  String? get lastServerUrl => 'https://test.example.com';

  @override
  String? get serverUrl => null;

  @override
  String? get token => null;

  @override
  String? get username => null;

  @override
  bool get isLoggedIn => false;

  @override
  bool get offlineMode => false;

  @override
  bool get isAdmin => false;

  @override
  bool get isReady => false;

  @override
  final sessionExpired = ValueNotifier<String?>(null);

  @override
  Future<void> rememberServerUrl(String url) async {}

  @override
  Future<AuthResult> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    return AuthResult.failure('Тестовый отказ');
  }

  @override
  Future<void> continueOffline() async {}

  @override
  Future<void> requireLogin() async {}

  @override
  Future<void> restore() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> handleUnauthorized({String? reason}) async {}

  @override
  Future<void> setAdmin(bool value) async {}

  @override
  Future<bool> refreshAccessToken() async => false;

  @override
  void dispose() {
    sessionExpired.dispose();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdminService extends ChangeNotifier implements AdminService {
  @override
  Future<void> checkRole() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('LoginScreen рендерит поля и кнопки', (tester) async {
    final auth = _FakeAuthService();
    final admin = _FakeAdminService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<AdminService>.value(value: admin),
          ChangeNotifierProvider(
            create: (_) => LoginViewModel(auth: auth, admin: admin),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Скидочные карты'), findsOneWidget);
    expect(find.text('Адрес сервера'), findsOneWidget);
    expect(find.text('Логин'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Продолжить без сервера'),
      findsOneWidget,
    );
  });

  testWidgets('валидация пустых полей не отправляет форму', (tester) async {
    final auth = _FakeAuthService();
    final admin = _FakeAdminService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<AdminService>.value(value: admin),
          ChangeNotifierProvider(
            create: (_) => LoginViewModel(auth: auth, admin: admin),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Очищаем URL (в initState подставляется lastServerUrl)
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Укажи адрес'), findsOneWidget);
    expect(find.text('Укажи логин'), findsOneWidget);
    expect(find.text('Укажи пароль'), findsOneWidget);
  });

  testWidgets('показывает баннер ошибки после неудачного входа', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    final admin = _FakeAdminService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<AdminService>.value(value: admin),
          ChangeNotifierProvider(
            create: (_) => LoginViewModel(auth: auth, admin: admin),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://test.example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'user');
    await tester.enterText(find.byType(TextFormField).at(2), 'pass');

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Тестовый отказ'), findsOneWidget);
  });
}
