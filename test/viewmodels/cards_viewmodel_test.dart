import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storcard_client/data/local/app_database.dart';
import 'package:storcard_client/data/repositories/card_repository.dart';
import 'package:storcard_client/data/services/auth_service.dart';
import 'package:storcard_client/viewmodels/cards_viewmodel.dart';

class _MockRepo extends Mock implements CardRepository {}

class _MockAuth extends Mock implements AuthService {}

void main() {
  late _MockRepo repo;
  late _MockAuth auth;

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();

    when(() => auth.username).thenReturn(null);
    when(() => auth.addListener(any())).thenReturn(null);
    when(() => auth.removeListener(any())).thenReturn(null);
    when(() => repo.watchVisibleCards(any()))
        .thenAnswer((_) => const Stream<List<Cards>>.empty());
    when(() => repo.countLocalOnlyCards()).thenAnswer((_) async => 0);
  });

  Cards fakeCard({
    required int id,
    required String name,
    String barcode = '0',
    String? about,
    String? ownerLogin,
  }) {
    return Cards(
      id: id,
      name: name,
      barcode: barcode,
      about: about,
      image: null,
      codeType: 'code128',
      ownerLogin: ownerLogin,
      isDirty: false,
      pendingDelete: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  test('стартует с loading=true, потом false', () async {
    when(() => repo.watchVisibleCards(null))
        .thenAnswer((_) => Stream.value([]));

    final vm = CardsViewModel(repo, auth);
    expect(vm.loading, true);

    await Future<void>.delayed(Duration.zero);
    expect(vm.loading, false);
    expect(vm.cards, isEmpty);
  });

  test('карты приходят из стрима', () async {
    final list = [fakeCard(id: 1, name: 'A'), fakeCard(id: 2, name: 'B')];
    when(() => repo.watchVisibleCards(null))
        .thenAnswer((_) => Stream.value(list));

    final vm = CardsViewModel(repo, auth);
    await Future<void>.delayed(Duration.zero);

    expect(vm.cards.length, 2);
  });

  test('ошибка стрима попадает в error', () async {
    when(() => repo.watchVisibleCards(null))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    final vm = CardsViewModel(repo, auth);
    await Future<void>.delayed(Duration.zero);

    expect(vm.error, isNotNull);
    expect(vm.loading, false);
  });

  group('setQuery', () {
    setUp(() {
      when(() => repo.watchVisibleCards(null)).thenAnswer(
        (_) => Stream.value([
          fakeCard(id: 1, name: 'Пятёрочка', barcode: '123'),
          fakeCard(id: 2, name: 'Лента', barcode: '456'),
          fakeCard(id: 3, name: 'Магнит', about: 'продукты рядом'),
        ]),
      );
    });

    test('фильтрует по имени (регистронезависимо)', () async {
      final vm = CardsViewModel(repo, auth);
      await Future<void>.delayed(Duration.zero);

      vm.setQuery('лент');
      expect(vm.cards.map((c) => c.id), [2]);
    });

    test('фильтрует по barcode', () async {
      final vm = CardsViewModel(repo, auth);
      await Future<void>.delayed(Duration.zero);

      vm.setQuery('123');
      expect(vm.cards.map((c) => c.id), [1]);
    });

    test('фильтрует по about', () async {
      final vm = CardsViewModel(repo, auth);
      await Future<void>.delayed(Duration.zero);

      vm.setQuery('продукт');
      expect(vm.cards.map((c) => c.id), [3]);
    });

    test('пустой запрос → все карты', () async {
      final vm = CardsViewModel(repo, auth);
      await Future<void>.delayed(Duration.zero);

      vm.setQuery('');
      expect(vm.cards.length, 3);
    });

    test('без совпадений → пусто', () async {
      final vm = CardsViewModel(repo, auth);
      await Future<void>.delayed(Duration.zero);

      vm.setQuery('zzz');
      expect(vm.cards, isEmpty);
    });

    test('уведомляет слушателей', () async {
      final vm = CardsViewModel(repo, auth);
      await Future<void>.delayed(Duration.zero);

      var notified = false;
      vm.addListener(() => notified = true);

      vm.setQuery('x');
      expect(notified, true);
    });
  });

  group('addCard', () {
    test('передаёт ownerLogin текущего пользователя', () async {
      when(() => auth.username).thenReturn('user1');
      when(() => repo.watchVisibleCards('user1'))
          .thenAnswer((_) => Stream.value([]));
      when(
        () => repo.createCard(
          name: any(named: 'name'),
          barcode: any(named: 'barcode'),
          codeType: any(named: 'codeType'),
          ownerLogin: any(named: 'ownerLogin'),
          about: any(named: 'about'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => 1);

      final vm = CardsViewModel(repo, auth);
      await vm.addCard(name: 'X', barcode: '1', codeType: 'code128');

      verify(
        () => repo.createCard(
          name: 'X',
          barcode: '1',
          codeType: 'code128',
          ownerLogin: 'user1',
          about: null,
          image: null,
        ),
      ).called(1);
    });

    test('при ошибке пишет error', () async {
      when(() => repo.watchVisibleCards(any()))
          .thenAnswer((_) => Stream.value([]));
      when(
        () => repo.createCard(
          name: any(named: 'name'),
          barcode: any(named: 'barcode'),
          codeType: any(named: 'codeType'),
          ownerLogin: any(named: 'ownerLogin'),
          about: any(named: 'about'),
          image: any(named: 'image'),
        ),
      ).thenThrow(Exception('db'));

      final vm = CardsViewModel(repo, auth);
      await vm.addCard(name: 'X', barcode: '1', codeType: 'code128');

      expect(vm.error, isNotNull);
    });
  });

  group('updateCard', () {
    test('вызывает repo.updateCard с параметрами', () async {
      when(() => repo.watchVisibleCards(any()))
          .thenAnswer((_) => Stream.value([]));
      when(
        () => repo.updateCard(
          any(),
          name: any(named: 'name'),
          barcode: any(named: 'barcode'),
          codeType: any(named: 'codeType'),
          about: any(named: 'about'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async {});

      final vm = CardsViewModel(repo, auth);
      await vm.updateCard(id: 5, name: 'N', barcode: '2', codeType: 'qr');

      verify(
        () => repo.updateCard(
          5,
          name: 'N',
          barcode: '2',
          codeType: 'qr',
          about: null,
          image: null,
        ),
      ).called(1);
    });
  });

  group('deleteCard', () {
    test('делегирует в softDeleteCard', () async {
      when(() => repo.watchVisibleCards(any()))
          .thenAnswer((_) => Stream.value([]));
      when(() => repo.softDeleteCard(any())).thenAnswer((_) async {});

      final vm = CardsViewModel(repo, auth);
      await vm.deleteCard(42);

      verify(() => repo.softDeleteCard(42)).called(1);
    });
  });

  group('миграция локальных карт', () {
    test('checkLocalCardsAfterLogin ничего не делает в offline', () async {
      when(() => auth.username).thenReturn(null);

      final vm = CardsViewModel(repo, auth);
      await vm.checkLocalCardsAfterLogin();

      expect(vm.pendingLocalCardsCount, 0);
      verifyNever(() => repo.countLocalOnlyCards());
    });

    test('checkLocalCardsAfterLogin считает при логине', () async {
      when(() => auth.username).thenReturn('user1');
      when(() => repo.watchVisibleCards('user1'))
          .thenAnswer((_) => Stream.value([]));
      when(() => repo.countLocalOnlyCards()).thenAnswer((_) async => 3);

      final vm = CardsViewModel(repo, auth);
      await vm.checkLocalCardsAfterLogin();

      expect(vm.pendingLocalCardsCount, 3);
    });

    test(
      'assignLocalCardsToCurrentUser привязывает и сбрасывает счётчик',
      () async {
        when(() => auth.username).thenReturn('user1');
        when(() => repo.watchVisibleCards('user1'))
            .thenAnswer((_) => Stream.value([]));
        when(() => repo.assignLocalCardsTo('user1')).thenAnswer((_) async => 2);

        final vm = CardsViewModel(repo, auth);
        await vm.assignLocalCardsToCurrentUser();

        verify(() => repo.assignLocalCardsTo('user1')).called(1);
        expect(vm.pendingLocalCardsCount, 0);
      },
    );

    test('assignLocalCardsToCurrentUser в offline — no-op', () async {
      when(() => auth.username).thenReturn(null);

      final vm = CardsViewModel(repo, auth);
      await vm.assignLocalCardsToCurrentUser();

      verifyNever(() => repo.assignLocalCardsTo(any()));
    });

    test('dismissLocalCardsDialog сбрасывает счётчик', () async {
      when(() => auth.username).thenReturn('user1');
      when(() => repo.watchVisibleCards('user1'))
          .thenAnswer((_) => Stream.value([]));
      when(() => repo.countLocalOnlyCards()).thenAnswer((_) async => 5);

      final vm = CardsViewModel(repo, auth);
      await vm.checkLocalCardsAfterLogin();
      expect(vm.pendingLocalCardsCount, 5);

      vm.dismissLocalCardsDialog();
      expect(vm.pendingLocalCardsCount, 0);
    });
  });

  group('смена пользователя', () {
    test('пересоздаёт подписку при смене username', () async {
      // Начинаем как offline
      var username = null as String?;
      when(() => auth.username).thenAnswer((_) => username);
      when(() => repo.watchVisibleCards(any()))
          .thenAnswer((_) => Stream.value([]));

      final vm = CardsViewModel(repo, auth);
      await Future<void>.delayed(Duration.zero);

      // Отписываемся / подписываемся заново через listener
      username = 'user1';
      // Симулируем notifyListeners от auth:
      for (final listener in _capturedListeners) {
        listener();
      }
      await Future<void>.delayed(Duration.zero);

      // Должны были вызвать watchVisibleCards('user1')
      verify(() => repo.watchVisibleCards('user1')).called(greaterThan(0));
    });
  });
  group('shouldShowLocalCardsDialog', () {
    test('false когда карт нет', () async {
      when(() => auth.username).thenReturn('u1');
      when(() => repo.watchVisibleCards('u1'))
          .thenAnswer((_) => Stream.value([]));
      when(() => repo.countLocalOnlyCards()).thenAnswer((_) async => 0);

      final vm = CardsViewModel(repo, auth);
      await vm.checkLocalCardsAfterLogin();

      expect(vm.shouldShowLocalCardsDialog, false);
    });

    test('true когда есть карты и не показывали', () async {
      when(() => auth.username).thenReturn('u1');
      when(() => repo.watchVisibleCards('u1'))
          .thenAnswer((_) => Stream.value([]));
      when(() => repo.countLocalOnlyCards()).thenAnswer((_) async => 3);

      final vm = CardsViewModel(repo, auth);
      await vm.checkLocalCardsAfterLogin();

      expect(vm.shouldShowLocalCardsDialog, true);
    });

    test('false после markLocalCardsDialogShown', () async {
      when(() => auth.username).thenReturn('u1');
      when(() => repo.watchVisibleCards('u1'))
          .thenAnswer((_) => Stream.value([]));
      when(() => repo.countLocalOnlyCards()).thenAnswer((_) async => 3);

      final vm = CardsViewModel(repo, auth);
      await vm.checkLocalCardsAfterLogin();
      vm.markLocalCardsDialogShown();

      expect(vm.shouldShowLocalCardsDialog, false);
    });

    test('false после dismissLocalCardsDialog', () async {
      when(() => auth.username).thenReturn('u1');
      when(() => repo.watchVisibleCards('u1'))
          .thenAnswer((_) => Stream.value([]));
      when(() => repo.countLocalOnlyCards()).thenAnswer((_) async => 3);

      final vm = CardsViewModel(repo, auth);
      await vm.checkLocalCardsAfterLogin();
      vm.dismissLocalCardsDialog();

      expect(vm.shouldShowLocalCardsDialog, false);
    });
  });
}

// Хак для симуляции notifyListeners от mocktail
final _capturedListeners = <void Function()>[];

// Переопределяем addListener чтобы запоминать колбэки — используем в setUp
