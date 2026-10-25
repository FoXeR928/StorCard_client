import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/data/local/app_database.dart';
import 'package:storcard_client/data/services/card_repository.dart';
import 'package:storcard_client/data/services/auth_service.dart';
import 'package:storcard_client/data/services/image_service.dart';
import 'package:storcard_client/data/remote/api_client.dart';
import 'package:storcard_client/data/services/sync_service.dart';
import 'package:storcard_client/viewmodels/cards_viewmodel.dart';

class MockRepo extends Mock implements CardRepository {}

class MockAuth extends Mock implements AuthService {}

class MockImageService extends Mock implements ImageService {}

class MockApiClient extends Mock implements ApiClient {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockRepo mockRepo;
  late MockAuth mockAuth;
  late CardsViewModel viewModel;

  setUp(() {
    mockRepo = MockRepo();
    mockAuth = MockAuth();

    // Настраиваем моки
    when(() => mockAuth.username).thenReturn('test_user');
    when(() => mockAuth.addListener(any())).thenReturn(null);
    when(() => mockRepo.watchVisibleCards(any()))
        .thenAnswer((_) => Stream.value([]));

    viewModel = CardsViewModel(
      mockRepo,
      mockAuth,
      MockImageService(),
      MockApiClient(),
      MockSyncService(),
    );
  });

  Cards buildCard(int id, String name, bool isFavorite, DateTime createdAt) {
    return Cards(
      id: id,
      name: name,
      barcode: '123',
      codeType: 'code128',
      isFavorite: isFavorite,
      isDirty: false,
      pendingDelete: false,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  final cardsList = [
    buildCard(1, 'Лента', false, DateTime(2023, 1, 1)),
    buildCard(2, 'Ашан', true, DateTime(2023, 1, 2)), // Избранная
    buildCard(3, 'Магнит', false, DateTime(2023, 1, 3)),
  ];

  test('Сортировка: Сначала избранные', () async {
    when(() => mockRepo.watchVisibleCards(any()))
        .thenAnswer((_) => Stream.value(cardsList));
    // Пересоздаем VM, чтобы применился стрим
    viewModel = CardsViewModel(
      mockRepo,
      mockAuth,
      MockImageService(),
      MockApiClient(),
      MockSyncService(),
    );

    // Ждем инициализации
    await Future.delayed(Duration.zero);

    viewModel.setSort(CardSort.favoriteFirst);
    final sorted = viewModel.cards;

    expect(sorted[0].name, 'Ашан'); // Первая избранная
    expect(sorted[1].name, 'Лента'); // Дальше по алфавиту
    expect(sorted[2].name, 'Магнит');
  });

  test('Сортировка: По алфавиту (А-Я)', () async {
    when(() => mockRepo.watchVisibleCards(any()))
        .thenAnswer((_) => Stream.value(cardsList));
    viewModel = CardsViewModel(
      mockRepo,
      mockAuth,
      MockImageService(),
      MockApiClient(),
      MockSyncService(),
    );
    await Future.delayed(Duration.zero);

    viewModel.setSort(CardSort.nameAsc);
    final sorted = viewModel.cards;

    expect(sorted[0].name, 'Ашан');
    expect(sorted[1].name, 'Лента');
    expect(sorted[2].name, 'Магнит');
  });

  test('Сортировка: Сначала новые', () async {
    when(() => mockRepo.watchVisibleCards(any()))
        .thenAnswer((_) => Stream.value(cardsList));
    viewModel = CardsViewModel(
      mockRepo,
      mockAuth,
      MockImageService(),
      MockApiClient(),
      MockSyncService(),
    );
    await Future.delayed(Duration.zero);

    viewModel.setSort(CardSort.newest);
    final sorted = viewModel.cards;

    expect(sorted[0].name, 'Магнит'); // Самая новая дата
    expect(sorted[1].name, 'Ашан');
    expect(sorted[2].name, 'Лента');
  });

  test('Поиск (Query) фильтрует по названию', () async {
    when(() => mockRepo.watchVisibleCards(any()))
        .thenAnswer((_) => Stream.value(cardsList));
    viewModel = CardsViewModel(
      mockRepo,
      mockAuth,
      MockImageService(),
      MockApiClient(),
      MockSyncService(),
    );
    await Future.delayed(Duration.zero);

    viewModel.setQuery('лент');
    final filtered = viewModel.cards;

    expect(filtered.length, 1);
    expect(filtered[0].name, 'Лента');
  });

  test('importFromJson создает карты из JSON', () async {
    final json = '[{"name": "Test", "barcode": "123", "codeType": "ean13"}]';

    // Настраиваем мок репозитория для проверки вызова
    when(
      () => mockRepo.createCard(
        name: any(named: 'name'),
        barcode: any(named: 'barcode'),
        codeType: any(named: 'codeType'),
        ownerLogin: any(named: 'ownerLogin'),
        about: any(named: 'about'),
      ),
    ).thenAnswer((_) async => 1);

    final count = await viewModel.importFromJson(json);

    expect(count, 1);
    verify(
      () => mockRepo.createCard(
        name: 'Test',
        barcode: '123',
        codeType: 'ean13',
        ownerLogin: 'test_user',
        about: null,
      ),
    ).called(1);
  });

  test('assignLocalCardsToCurrentUser очищает счетчик', () async {
    when(() => mockRepo.assignLocalCardsTo('test_user'))
        .thenAnswer((_) async => 5);

    await viewModel.assignLocalCardsToCurrentUser();
    expect(viewModel.pendingLocalCardsCount, 0);
  });
}
