import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storcard_client/data/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logout очищает токены и переводит в offline', () async {
    final auth = AuthService();
    // Симулируем сохранение токенов (вручную через SharedPreferences)
    final p = await SharedPreferences.getInstance();
    await p.setString('auth_token', 'test_token');
    await p.setString('server_url', 'https://test.com');

    await auth.restore();
    expect(auth.isLoggedIn, true);

    await auth.logout();
    expect(auth.isLoggedIn, false);
    expect(auth.offlineMode, true);
    expect(await p.getString('auth_token'), isNull);
  });

  test(
    'handleUnauthorized сбрасывает сессию и вызывает sessionExpired',
    () async {
      final auth = AuthService();
      final p = await SharedPreferences.getInstance();
      await p.setString('auth_token', 'test_token');
      await auth.restore();

      await auth.handleUnauthorized(reason: 'Токен протух');

      expect(auth.isLoggedIn, false);
      expect(auth.sessionExpired.value, 'Токен протух');
    },
  );
}
