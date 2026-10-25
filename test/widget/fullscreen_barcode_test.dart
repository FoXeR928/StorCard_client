import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storcard_client/data/services/display_settings.dart';
import 'package:storcard_client/views/widgets/fullscreen_barcode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Каналы для мока системных вызовов
  const brightnessChannel = MethodChannel(
    'github.com/aaassseee/screen_brightness',
  );
  const wakelockChannel = MethodChannel('dev.fluttercommunity.plus/wakelock');

  setUp(() {
    // Мок яркости: отвечаем, что системная яркость = 0.5
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(brightnessChannel, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'getSystemScreenBrightness') {
            return 0.5;
          }
          return null;
        });

    // Мок WakelockPlus (чтобы не падало)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(wakelockChannel, (
          MethodCall methodCall,
        ) async {
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(brightnessChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(wakelockChannel, null);
  });

  testWidgets('FullscreenBarcode рендерится и показывает кнопку копирования', (
    tester,
  ) async {
    final settings = DisplaySettings();

    await tester.pumpWidget(
      ChangeNotifierProvider<DisplaySettings>.value(
        value: settings,
        child: const MaterialApp(
          home: FullscreenBarcode(
            name: 'Лента',
            barcode: '1234567890',
            codeType: 'code128',
          ),
        ),
      ),
    );

    // Даем время на инициализацию яркости
    await tester.pumpAndSettle();

    // Проверяем, что UI отрисовался
    expect(find.text('Лента'), findsOneWidget); // Имя в AppBar
    expect(find.text('1234567890'), findsOneWidget); // Сам штрихкод
    expect(find.text('Скопировать код'), findsOneWidget);
  });
}
