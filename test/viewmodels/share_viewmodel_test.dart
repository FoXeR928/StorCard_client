import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/data/models/server_user.dart';
import 'package:storcard_client/data/services/admin_service.dart';
import 'package:storcard_client/data/services/auth_service.dart';
import 'package:storcard_client/data/services/recipient_directory.dart';
import 'package:storcard_client/data/services/sharing_service.dart';
import 'package:storcard_client/viewmodels/share_viewmodel.dart';

class MockAuth extends Mock implements AuthService {}

class MockAdmin extends Mock implements AdminService {}

class MockSharing extends Mock implements SharingService {}

class MockDirectory extends Mock implements RecipientDirectory {}

void main() {
  late MockAuth auth;
  late MockAdmin admin;
  late MockSharing sharing;
  late MockDirectory directory;
  late ShareViewModel vm;

  setUp(() {
    auth = MockAuth();
    admin = MockAdmin();
    sharing = MockSharing();
    directory = MockDirectory();

    when(() => auth.username).thenReturn('me');
    when(() => auth.isAdmin).thenReturn(false);

    // По умолчанию пустые списки
    when(() => directory.recent).thenReturn(['recent_user']);
    when(() => admin.users).thenReturn([
      const ServerUser(login: 'admin_user', userName: 'Admin'),
      const ServerUser(login: 'me', userName: 'Me'), // Себя должны исключить
    ]);

    vm = ShareViewModel(
      auth: auth,
      admin: admin,
      sharing: sharing,
      directory: directory,
    );
  });

  test('candidates объединяет recent и users, исключая себя', () {
    final candidates = vm.candidates();

    expect(candidates.contains('recent_user'), true);
    expect(candidates.contains('admin_user'), true);
    expect(candidates.contains('me'), false); // Себя исключили
  });

  test('share возвращает null при успехе', () async {
    when(
      () => sharing.share(
        serverId: any(named: 'serverId'),
        targetLogin: any(named: 'targetLogin'),
        accessLevel: any(named: 'accessLevel'),
      ),
    ).thenAnswer((_) async => null);
    when(() => directory.remember(any())).thenAnswer((_) async {});

    final err = await vm.share(serverId: 'card1', targetLogin: 'user2');

    expect(err, isNull);
    verify(() => directory.remember('user2')).called(1);
  });
}
