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
  final sessionExpired = ValueNotifier<String?>(null);

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
  Future<void> rememberServerUrl(String url) async {}

  // ← ВАЖНО: добавлен rememberMe, иначе не совпадает с интерфейсом
  @override
  Future<AuthResult> login({
    required String serverUrl,
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    return AuthResult.failure('Тестовый отказ');
  }

  @override
  Future<bool> refreshAccessToken() async => false;

  @override
  Future<void> handleUnauthorized({String? reason}) async {}

  @override
  Future<void> setAdmin(bool value) async {}

  @override
  Future<void> continueOffline() async {}

  @override
  Future<void> requireLogin() async {}

  @override
  Future<void> restore() async {}

  @override
  Future<void> logout() async {}

  @override
  void dispose() {
    sessionExpired.dispose();
    super.dispose();
  }
}

class _FakeAdminService extends ChangeNotifier implements AdminService {
  @override
  Future<void> checkRole() async {}

  @override
  Future<void> loadUsers() async {}

  @override
  Future<void> loadAllCards() async {}

  @override
  Future<void> checkServerStatus() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  /// Размер экрана в тестах по умолчанию — 800×600, из-за чего
  /// кнопка «Войти» (после чекбокса) уезжает ниже экрана.
  /// Ставим размер реального телефона.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Widget _wrap({required AuthService auth, required AdminService admin}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<AdminService>.value(value: admin),
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(auth: auth, admin: admin),
        ),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('LoginScreen рендерит поля и кнопки', (tester) async {
    await tester.pumpWidget(
      _wrap(auth: _FakeAuthService(), admin: _FakeAdminService()),
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
    await tester.pumpWidget(
      _wrap(auth: _FakeAuthService(), admin: _FakeAdminService()),
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
    await tester.pumpWidget(
      _wrap(auth: _FakeAuthService(), admin: _FakeAdminService()),
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
