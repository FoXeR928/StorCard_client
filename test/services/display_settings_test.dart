import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storcard_client/data/services/display_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Загружает дефолтные настройки', () async {
    final settings = DisplaySettings();
    await settings.load();

    expect(settings.mode, BrightnessMode.automatic);
    expect(settings.manualBrightness, 1.0);
  });

  test('Сохраняет и загружает режим и яркость', () async {
    final settings = DisplaySettings();
    await settings.setMode(BrightnessMode.manual);
    await settings.setManualBrightness(0.5);

    // Создаем новый инстанс (симуляция перезапуска)
    final settings2 = DisplaySettings();
    await settings2.load();

    expect(settings2.mode, BrightnessMode.manual);
    expect(settings2.manualBrightness, 0.5);
  });
}
