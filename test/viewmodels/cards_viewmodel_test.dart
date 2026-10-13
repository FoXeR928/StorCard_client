import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../lib_old/data/repositories/card_repository.dart';
import '../../lib_old/models/cards.dart';
import '../../lib_old/viewmodels/cards_viewmodel.dart';

class MockRepo extends Mock implements CardRepository {}

class FakeCards extends Fake implements Cards {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCards());
  });

  late MockRepo repo;
  late StreamController<List<Cards>> controller;
  late CardsViewModel vm;

  setUp(() {
    repo = MockRepo();
    controller = StreamController<List<Cards>>.broadcast();

    when(() => repo.watchVisibleCards()).thenAnswer((_) => controller.stream);

    vm = CardsViewModel(repo);
  });

  tearDown(() async {
    vm.dispose();
    await controller.close();
  });

  Cards makeCard(String name, {String barcode = '1'}) =>
      Cards(name: name, barcode: barcode);

  test('loading=true before first emit', () {
    expect(vm.loading, isTrue);
    expect(vm.cards, isEmpty);
  });

  test('loading=false after emit', () async {
    controller.add([makeCard('A')]);
    await Future.delayed(Duration.zero);

    expect(vm.loading, isFalse);
    expect(vm.cards.length, 1);
  });

  group('query filter', () {
    setUp(() async {
      controller.add([
        Cards(name: 'Магнит', barcode: '111'),
        Cards(name: 'Пятёрочка', barcode: '222', about: 'скидка 5%'),
        Cards(name: 'Лента', barcode: '333'),
      ]);
      await Future.delayed(Duration.zero);
    });

    test('empty query → all', () {
      expect(vm.cards.length, 3);
    });

    test('by name', () {
      vm.setQuery('маг');
      expect(vm.cards.map((c) => c.name), ['Магнит']);
    });

    test('by barcode', () {
      vm.setQuery('222');
      expect(vm.cards.map((c) => c.name), ['Пятёрочка']);
    });

    test('by about', () {
      vm.setQuery('скидка');
      expect(vm.cards.map((c) => c.name), ['Пятёрочка']);
    });

    test('case-insensitive', () {
      vm.setQuery('МАГНИТ');
      expect(vm.cards.length, 1);
    });

    test('no match', () {
      vm.setQuery('xyz');
      expect(vm.cards, isEmpty);
    });

    test('setQuery notifies', () {
      var notified = 0;
      vm.addListener(() => notified++);
      vm.setQuery('лента');
      expect(notified, 1);
    });
  });

  group('addCard', () {
    test('calls repo.createCard', () async {
      when(
        () => repo.createCard(
          name: any(named: 'name'),
          barcode: any(named: 'barcode'),
          codeType: any(named: 'codeType'),
          about: any(named: 'about'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => 1);

      await vm.addCard(
        name: 'Магнит',
        barcode: '111',
        codeType: 'ean13',
        about: 'заметка',
      );

      verify(
        () => repo.createCard(
          name: 'Магнит',
          barcode: '111',
          codeType: 'ean13',
          about: 'заметка',
          image: null,
        ),
      ).called(1);
    });

    test('error → sets error', () async {
      when(
        () => repo.createCard(
          name: any(named: 'name'),
          barcode: any(named: 'barcode'),
          codeType: any(named: 'codeType'),
          about: any(named: 'about'),
          image: any(named: 'image'),
        ),
      ).thenThrow(Exception('boom'));

      await vm.addCard(name: 'X', barcode: '1', codeType: 'code128');
      expect(vm.error, contains('boom'));
    });
  });

  group('updateCard', () {
    test('delegates to repository', () async {
      final card = makeCard('A');
      when(() => repo.updateCard(any())).thenAnswer((_) async {
        return null;
      });

      await vm.updateCard(card);
      verify(() => repo.updateCard(card)).called(1);
    });

    test('error → sets error', () async {
      when(() => repo.updateCard(any())).thenThrow(Exception('fail'));

      await vm.updateCard(makeCard('A'));
      expect(vm.error, contains('fail'));
    });
  });

  group('deleteCard', () {
    test('delegates to repository', () async {
      when(() => repo.softDeleteCard(any())).thenAnswer((_) async {
        return null;
      });

      await vm.deleteCard(42);
      verify(() => repo.softDeleteCard(42)).called(1);
    });

    test('error → sets error', () async {
      when(() => repo.softDeleteCard(any())).thenThrow(Exception('no'));

      await vm.deleteCard(1);
      expect(vm.error, contains('no'));
    });
  });
}
