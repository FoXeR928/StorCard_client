import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib_old/data/services/recipient_directory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('empty on first load', () async {
    final dir = RecipientDirectory();
    await dir.load();
    expect(dir.recent, isEmpty);
  });

  test('remember adds login', () async {
    final dir = RecipientDirectory();
    await dir.load();
    await dir.remember('alice');
    expect(dir.recent, ['alice']);
  });

  test('remember moves existing to top', () async {
    final dir = RecipientDirectory();
    await dir.load();
    await dir.remember('alice');
    await dir.remember('bob');
    await dir.remember('alice');
    expect(dir.recent, ['alice', 'bob']);
  });

  test('remember ignores empty', () async {
    final dir = RecipientDirectory();
    await dir.load();
    await dir.remember('  ');
    expect(dir.recent, isEmpty);
  });

  test('caps at 30 items', () async {
    final dir = RecipientDirectory();
    await dir.load();
    for (var i = 0; i < 40; i++) {
      await dir.remember('user$i');
    }
    expect(dir.recent.length, 30);
    expect(dir.recent.first, 'user39');
  });

  test('forget removes login', () async {
    final dir = RecipientDirectory();
    await dir.load();
    await dir.remember('alice');
    await dir.remember('bob');
    await dir.forget('alice');
    expect(dir.recent, ['bob']);
  });

  test('persists across instances', () async {
    final dir1 = RecipientDirectory();
    await dir1.load();
    await dir1.remember('alice');

    final dir2 = RecipientDirectory();
    await dir2.load();
    expect(dir2.recent, ['alice']);
  });
}
