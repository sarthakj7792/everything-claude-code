---
paths:
  - "**/*.dart"
---
# Dart / Flutter Testing

> This file extends [common/testing.md](../common/testing.md) with Dart and Flutter-specific content.

## Test Framework

- **flutter_test** for widget and unit tests
- **bloc_test** for BLoC/Cubit-specific testing
- **mocktail** (preferred) or **mockito** for mocking
- **integration_test** for full-app integration tests
- **golden_toolkit** or built-in `matchesGoldenFile` for golden (snapshot) tests

## Unit Testing

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Item', () {
    test('copyWith creates new instance with updated field', () {
      const item = Item(id: '1', name: 'Original', description: 'desc');
      final updated = item.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.id, '1'); // unchanged
      expect(identical(item, updated), isFalse);
    });

    test('fromJson parses valid JSON correctly', () {
      final json = {'id': '1', 'name': 'Test', 'description': 'desc'};
      final item = Item.fromJson(json);

      expect(item.id, '1');
      expect(item.name, 'Test');
    });
  });
}
```

## Widget Testing

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginForm shows error on empty submit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoginForm())),
    );

    // Tap submit without filling fields
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify validation error shown
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('ItemCard displays item name and description', (tester) async {
    const item = Item(id: '1', name: 'Test Item', description: 'A description');

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ItemCard(item: item))),
    );

    expect(find.text('Test Item'), findsOneWidget);
    expect(find.text('A description'), findsOneWidget);
  });
}
```

## BLoC Testing with bloc_test

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] on successful login',
      build: () {
        when(() => mockLoginUseCase(any(), any()))
            .thenAnswer((_) async => Right(testUser));
        return AuthBloc(loginUseCase: mockLoginUseCase);
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'test@test.com', password: 'pass'),
      ),
      expect: () => [
        const AuthState.loading(),
        AuthState.authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failed login',
      build: () {
        when(() => mockLoginUseCase(any(), any()))
            .thenAnswer((_) async => const Left(ServerFailure('Invalid')));
        return AuthBloc(loginUseCase: mockLoginUseCase);
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'bad@test.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('Invalid'),
      ],
    );
  });
}
```

## Fakes Over Mocks

Prefer hand-written fakes for repositories:

```dart
class FakeItemRepository implements ItemRepository {
  final List<Item> _items = [];
  Failure? fetchError;

  @override
  Future<Either<Failure, List<Item>>> getAll() async {
    if (fetchError != null) return Left(fetchError!);
    return Right(List.unmodifiable(_items));
  }

  @override
  Stream<List<Item>> watchAll() => Stream.value(List.unmodifiable(_items));

  void addItem(Item item) => _items.add(item);
}
```

## Golden Tests

```dart
testWidgets('ItemCard matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: const Scaffold(
        body: ItemCard(item: Item(id: '1', name: 'Golden', description: 'Test')),
      ),
    ),
  );

  await expectLater(
    find.byType(ItemCard),
    matchesGoldenFile('goldens/item_card.png'),
  );
});
```

Update goldens with: `flutter test --update-goldens`

## Integration Tests

Place in `integration_test/` directory:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full login flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(find.byKey(const Key('email_field')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Verify navigation to home
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

## Test Organization

```
test/
├── core/
│   └── utils/
│       └── validators_test.dart
├── features/
│   └── auth/
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       └── login_usecase_test.dart
│       └── presentation/
│           ├── bloc/
│           │   └── auth_bloc_test.dart
│           └── pages/
│               └── login_page_test.dart
├── helpers/              # Shared test utilities, fakes, fixtures
│   ├── pump_app.dart     # Helper to wrap widgets in MaterialApp
│   └── fakes.dart
└── goldens/              # Golden test reference images
integration_test/
└── app_test.dart
```

## Test Naming

Use descriptive names that explain the scenario:

```dart
test('getAll returns failure when remote throws ServerException', () async { });
test('copyWith preserves unchanged fields', () { });
test('empty query returns all items unfiltered', () async { });
```

## Coverage

Run coverage: `flutter test --coverage`
View report: `genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html`

Minimum test coverage: BLoC/Cubit + UseCase + Repository for every feature.
