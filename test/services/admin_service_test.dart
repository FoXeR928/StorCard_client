import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/data/remote/admin_api.dart';
import 'package:storcard_client/data/remote/public_api.dart';
import 'package:storcard_client/data/remote/user_api.dart';
import 'package:storcard_client/data/services/admin_service.dart';
import 'package:storcard_client/data/services/auth_service.dart';

class MockAdminApi extends Mock implements AdminApi {}

class MockUserApi extends Mock implements UserApi {}

class MockPublicApi extends Mock implements PublicApi {}

class MockAuth extends Mock implements AuthService {}

void main() {
  late MockAdminApi adminApi;
  late MockUserApi userApi;
  late MockPublicApi publicApi;
  late MockAuth auth;
  late AdminService admin;

  setUp(() {
    adminApi = MockAdminApi();
    userApi = MockUserApi();
    publicApi = MockPublicApi();
    auth = MockAuth();

    when(() => auth.isLoggedIn).thenReturn(true);
    when(() => auth.addListener(any())).thenReturn(null);
    when(() => auth.removeListener(any())).thenReturn(null);

    admin = AdminService(
      adminApi: adminApi,
      userApi: userApi,
      publicApi: publicApi,
      auth: auth,
    );
  });

  test(
    'checkRole выставляет isAdmin=true, если API вернул список юзеров',
    () async {
      when(() => auth.setAdmin(any())).thenAnswer((_) async {});
      when(() => adminApi.getUsers()).thenAnswer((_) async => []);

      await admin.checkRole();

      verify(() => auth.setAdmin(true)).called(1);
      expect(admin.roleChecked, true);
    },
  );

  test('checkRole выставляет isAdmin=false при ошибке 403', () async {
    when(() => auth.setAdmin(any())).thenAnswer((_) async {});
    when(() => adminApi.getUsers()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/users/'),
        response: Response(
          requestOptions: RequestOptions(path: '/users/'),
          statusCode: 403,
        ),
      ),
    );

    await admin.checkRole();

    verify(() => auth.setAdmin(false)).called(1);
    expect(admin.roleChecked, true);
  });
}
