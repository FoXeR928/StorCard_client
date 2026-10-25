import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/viewmodels/cards_viewmodel.dart';
import 'package:storcard_client/views/cards/card_editor_screen.dart';

class MockCardsViewModel extends Mock implements CardsViewModel {}

void main() {
  testWidgets('показывает ошибки валидации при пустых полях', (tester) async {
    final vm = MockCardsViewModel();

    // Настраиваем экран
    await tester.pumpWidget(
      ChangeNotifierProvider<CardsViewModel>.value(
        value: vm,
        child: const MaterialApp(home: CardEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Жмем "Добавить", ничего не вводя
    await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
    await tester.pumpAndSettle();

    // Ожидаем увидеть ошибки
    expect(find.text('Укажи название'), findsOneWidget);
    expect(find.text('Укажи код'), findsOneWidget);
  });
}
