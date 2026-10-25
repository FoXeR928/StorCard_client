import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/viewmodels/cards_viewmodel.dart';
import 'package:storcard_client/data/services/auth_service.dart';
import 'package:storcard_client/data/services/sync_service.dart';
import 'package:storcard_client/views/cards/cards_screen.dart';

class MockCardsViewModel extends Mock implements CardsViewModel {}

class MockAuthService extends Mock implements AuthService {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  testWidgets('Показывает "нет карт", если список пуст', (tester) async {
    final vm = MockCardsViewModel();
    final auth = MockAuthService();
    final sync = MockSyncService();

    // Моки для ViewModel
    when(() => vm.loading).thenReturn(false);
    when(() => vm.error).thenReturn(null);
    when(() => vm.cards).thenReturn([]);
    when(() => vm.query).thenReturn('');

    when(() => vm.shouldShowLocalCardsDialog).thenReturn(false);
    when(() => vm.pendingLocalCardsCount).thenReturn(0);
    when(() => vm.addListener(any())).thenReturn(null);
    when(() => vm.removeListener(any())).thenReturn(null);

    // Моки для AuthService (AccountButton спрашивает isLoggedIn)
    when(() => auth.isLoggedIn).thenReturn(false);
    when(() => auth.username).thenReturn(null);

    // Моки для SyncService
    when(() => sync.state).thenReturn(SyncState.idle);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CardsViewModel>.value(value: vm),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<SyncService>.value(value: sync),
        ],
        child: const MaterialApp(home: CardsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пока нет ни одной карты'), findsOneWidget);
  });
}
