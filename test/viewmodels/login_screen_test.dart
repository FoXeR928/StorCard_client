import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/data/models/auth_result.dart';
import 'package:storcard_client/data/services/admin_service.dart';
import 'package:storcard_client/data/services/auth_service.dart';
import 'package:storcard_client/viewmodels/login_viewmodel.dart';

class MockAuthService extends Mock implements AuthService {}

class MockAdminService extends Mock implements AdminService {}

void main() {
  late MockAuthService auth;
  late MockAdminService admin;
  late LoginViewModel vm;

  setUp(() {
    auth = MockAuthService();
    admin = MockAdminService();
    vm = LoginViewModel(auth: auth, admin: admin);
  });

  test('успешный вход возвращает true и дергает checkRole', () async {
    when(() => auth.rememberServerUrl(any())).thenAnswer((_) async {});
    when(
      () => auth.login(
        serverUrl: any(named: 'serverUrl'),
        username: any(named: 'username'),
        password: any(named: 'password'),
        rememberMe: any(named: 'rememberMe'),
      ),
    ).thenAnswer((_) async => AuthResult.success());
    when(() => admin.checkRole()).thenAnswer((_) async {});

    final ok = await vm.submit(
      serverUrl: 'https://test.com',
      username: 'user',
      password: 'pass',
    );

    expect(ok, true);
    expect(vm.loading, false);
    expect(vm.error, isNull);
    verify(() => admin.checkRole()).called(1);
  });

  test('неудачный вход возвращает false и пишет ошибку', () async {
    when(() => auth.rememberServerUrl(any())).thenAnswer((_) async {});
    when(
      () => auth.login(
        serverUrl: any(named: 'serverUrl'),
        username: any(named: 'username'),
        password: any(named: 'password'),
        rememberMe: any(named: 'rememberMe'),
      ),
    ).thenAnswer((_) async => AuthResult.failure('Неверный пароль'));

    final ok = await vm.submit(
      serverUrl: 'https://test.com',
      username: 'user',
      password: 'wrong',
    );

    expect(ok, false);
    expect(vm.loading, false);
    expect(vm.error, 'Неверный пароль');
    verifyNever(() => admin.checkRole());
  });

  test('setRememberMe обновляет состояние', () {
    expect(vm.rememberMe, false);
    vm.setRememberMe(true);
    expect(vm.rememberMe, true);
  });
}
