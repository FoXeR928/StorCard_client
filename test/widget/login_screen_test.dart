import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../lib_old/data/services/auth_service.dart';
import '../../lib_old/views/login_screen.dart';

class MockAuth extends Mock implements AuthService {}

void main() {
  late MockAuth auth;

  setUp(() {
    auth = MockAuth();

    when(() => auth.addListener(any())).thenReturn(null);
    when(() => auth.removeListener(any())).thenReturn(null);

    when(
      () => auth.login(
        serverUrl: any(named: 'serverUrl'),
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResult.success());

    when(() => auth.continueOffline()).thenAnswer((_) async {
      return null;
    });
  });

  Widget wrap(Widget child) => MaterialApp(
    home: ChangeNotifierProvider<AuthService>.value(value: auth, child: child),
  );

  testWidgets('renders form', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    expect(find.text('Скидочные карты'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Продолжить без сервера'),
      findsOneWidget,
    );
  });

  testWidgets('empty fields → validation', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();

    expect(find.text('Укажи логин'), findsOneWidget);
    expect(find.text('Укажи пароль'), findsOneWidget);
  });

  testWidgets('URL without http → validation', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();

    expect(
      find.text('Должно начинаться с http:// или https://'),
      findsOneWidget,
    );
  });

  testWidgets('valid submit → login called', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'http://localhost:8000',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'user');
    await tester.enterText(find.byType(TextFormField).at(2), 'pass');

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();

    verify(
      () => auth.login(
        serverUrl: 'http://localhost:8000',
        username: 'user',
        password: 'pass',
      ),
    ).called(1);
  });

  testWidgets('login failure → error shown', (tester) async {
    when(
      () => auth.login(
        serverUrl: any(named: 'serverUrl'),
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResult.failure('Неверный пароль'));

    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'http://localhost:8000',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'user');
    await tester.enterText(find.byType(TextFormField).at(2), 'pass');

    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Неверный пароль'), findsOneWidget);
  });

  testWidgets('offline button', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Продолжить без сервера'),
    );
    await tester.pump();

    verify(() => auth.continueOffline()).called(1);
  });
}
