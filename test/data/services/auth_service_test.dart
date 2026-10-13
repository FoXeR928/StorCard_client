import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib_old/data/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService restore', () {
    test('empty prefs', () async {
      final auth = AuthService();
      await auth.restore();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.offlineMode, isFalse);
      expect(auth.isReady, isFalse);
      expect(auth.isAdmin, isFalse);
    });

    test('with token', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token',
        'server_url': 'http://test.com',
        'auth_username': 'user',
        'offline_mode': false,
        'is_admin': false,
      });

      final auth = AuthService();
      await auth.restore();

      expect(auth.isLoggedIn, isTrue);
      expect(auth.username, 'user');
      expect(auth.serverUrl, 'http://test.com');
      expect(auth.isReady, isTrue);
    });

    test('offline mode', () async {
      SharedPreferences.setMockInitialValues({'offline_mode': true});

      final auth = AuthService();
      await auth.restore();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.offlineMode, isTrue);
      expect(auth.isReady, isTrue);
    });
  });

  group('continueOffline', () {
    test('sets offline mode', () async {
      final auth = AuthService();
      await auth.continueOffline();

      expect(auth.offlineMode, isTrue);
      expect(auth.isReady, isTrue);
    });
  });

  group('logout', () {
    test('clears session, keeps offline', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token',
        'server_url': 'http://test.com',
        'auth_username': 'user',
        'offline_mode': false,
        'is_admin': true,
      });

      final auth = AuthService();
      await auth.restore();
      expect(auth.isLoggedIn, isTrue);

      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.offlineMode, isTrue);
      expect(auth.isAdmin, isFalse);
    });
  });

  group('requireLogin', () {
    test('clears offline mode', () async {
      SharedPreferences.setMockInitialValues({'offline_mode': true});

      final auth = AuthService();
      await auth.restore();
      expect(auth.offlineMode, isTrue);

      await auth.requireLogin();

      expect(auth.offlineMode, isFalse);
      expect(auth.isReady, isFalse);
    });
  });

  group('handleUnauthorized', () {
    test('clears token, keeps offline', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token',
        'server_url': 'http://test.com',
        'auth_username': 'user',
      });

      final auth = AuthService();
      await auth.restore();
      expect(auth.isLoggedIn, isTrue);

      await auth.handleUnauthorized();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.offlineMode, isTrue);
      expect(auth.isAdmin, isFalse);
    });
  });

  group('setAdmin', () {
    test('updates isAdmin', () async {
      final auth = AuthService();
      await auth.setAdmin(true);
      expect(auth.isAdmin, isTrue);

      await auth.setAdmin(false);
      expect(auth.isAdmin, isFalse);
    });
  });

  group('login validation', () {
    test('empty URL → failure', () async {
      final auth = AuthService();
      final result = await auth.login(
        serverUrl: '',
        username: 'user',
        password: 'pass',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
    });

    test('URL without http → failure', () async {
      final auth = AuthService();
      final result = await auth.login(
        serverUrl: 'example.com',
        username: 'user',
        password: 'pass',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('http'));
    });
  });
}
