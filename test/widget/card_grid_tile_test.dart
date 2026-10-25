import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storcard_client/data/local/app_database.dart';
import 'package:storcard_client/views/widgets/card_grid_tile.dart';

void main() {
  testWidgets('CardGridTile показывает звезду для избранного', (tester) async {
    final card = Cards(
      id: 1,
      name: 'Test',
      barcode: '123',
      codeType: 'code128',
      isFavorite: true,
      isDirty: false,
      pendingDelete: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardGridTile(card: card, onTap: () {}, onLongPress: () {}),
        ),
      ),
    );

    // Проверяем, что звезда избранного отрисовалась
    expect(find.byIcon(Icons.star), findsOneWidget);
    // Проверяем, что название карты на месте
    expect(find.text('Test'), findsOneWidget);
  });
}
