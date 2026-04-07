---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Dart/Flutter Testing

> This file extends [common/testing.md](../common/testing.md) with Dart and Flutter-specific content.

## Test Framework

- **flutter_test** / **dart:test** — built-in test runner
- **mockito** (with `@GenerateMocks`) or **mocktail** (no codegen) for mocking
- **bloc_test** for BLoC/Cubit unit tests
- **fake_async** for controlling time in unit tests
- **integration_test** for end-to-end device tests
- **golden_toolkit** or built-in `matchesGoldenFile` for golden (snapshot) tests

## Test Types

| Type | Tool | Location | When to Write |
|------|------|----------|---------------|
| Unit | `dart:test` | `test/unit/` | All domain logic, state managers, repositories |
| Widget | `flutter_test` | `test/widget/` | All widgets with meaningful behavior |
| Golden | `flutter_test` | `test/golden/` | Design-critical UI components |
| Integration | `integration_test` | `integration_test/` | Critical user flows on real device/emulator |

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

## Unit Tests: State Managers

### BLoC with `bloc_test`

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

  group('CartBloc', () {
    late CartBloc bloc;
    late MockCartRepository repository;

    setUp(() {
      repository = MockCartRepository();
      bloc = CartBloc(repository);
    });

    tearDown(() => bloc.close());

    blocTest<CartBloc, CartState>(
      'emits updated items when CartItemAdded',
      build: () => bloc,
      act: (b) => b.add(CartItemAdded(testItem)),
      expect: () => [CartState(items: [testItem])],
    );

    blocTest<CartBloc, CartState>(
      'emits empty cart when CartCleared',
      seed: () => CartState(items: [testItem]),
      build: () => bloc,
      act: (b) => b.add(CartCleared()),
      expect: () => [const CartState()],
    );
  });
}
```

### Riverpod with `ProviderContainer`

```dart
test('usersProvider loads users from repository', () async {
  final container = ProviderContainer(
    overrides: [userRepositoryProvider.overrideWithValue(FakeUserRepository())],
  );
  addTearDown(container.dispose);

  final result = await container.read(usersProvider.future);
  expect(result, isNotEmpty);
});
```

## Widget Tests

```dart
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

testWidgets('CartPage shows item count badge', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartNotifierProvider.overrideWith(() => FakeCartNotifier([testItem])),
      ],
      child: const MaterialApp(home: CartPage()),
    ),
  );

  await tester.pump();
  expect(find.text('1'), findsOneWidget);
  expect(find.byType(CartItemTile), findsOneWidget);
});

testWidgets('shows empty state when cart is empty', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [cartNotifierProvider.overrideWith(() => FakeCartNotifier([]))],
      child: const MaterialApp(home: CartPage()),
    ),
  );

  await tester.pump();
  expect(find.text('Your cart is empty'), findsOneWidget);
});
```

## Fakes Over Mocks

Prefer hand-written fakes for complex dependencies:

```dart
class FakeUserRepository implements UserRepository {
  final _users = <String, User>{};
  Object? fetchError;

  @override
  Future<User?> getById(String id) async {
    if (fetchError != null) throw fetchError!;
    return _users[id];
  }

  @override
  Future<List<User>> getAll() async {
    if (fetchError != null) throw fetchError!;
    return _users.values.toList();
  }

  @override
  Stream<List<User>> watchAll() => Stream.value(_users.values.toList());

  @override
  Future<void> save(User user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> delete(String id) async {
    _users.remove(id);
  }

  void addUser(User user) => _users[user.id] = user;
}

// Fakes for Either-based repositories
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

## Async Testing

```dart
// Use fake_async for controlling timers and Futures
test('debounce triggers after 300ms', () {
  fakeAsync((async) {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
    var callCount = 0;
    debouncer.run(() => callCount++);
    expect(callCount, 0);
    async.elapse(const Duration(milliseconds: 200));
    expect(callCount, 0);
    async.elapse(const Duration(milliseconds: 200));
    expect(callCount, 1);
  });
});
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

testWidgets('UserCard golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: UserCard(user: testUser)),
  );

  await expectLater(
    find.byType(UserCard),
    matchesGoldenFile('goldens/user_card.png'),
  );
});
```

Run `flutter test --update-goldens` when intentional visual changes are made.

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

## ViewModel Testing with Provider + mockito

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginViewModel viewModel;

  setUp(() {
    mockRepository = MockAuthRepository();
    viewModel = LoginViewModel(repository: mockRepository);
  });

  group('LoginViewModel', () {
    test('login sets state to busy then idle on success', () async {
      when(mockRepository.login(any, any))
          .thenAnswer((_) async => testUser);

      final states = <ViewState>[];
      viewModel.addListener(() => states.add(viewModel.state));

      final result = await viewModel.login('test@test.com', 'pass');

      expect(result, true);
      expect(states, [ViewState.busy, ViewState.idle]);
    });

    test('login sets state to error on failure', () async {
      when(mockRepository.login(any, any))
          .thenThrow(Exception('Invalid credentials'));

      final result = await viewModel.login('bad@test.com', 'wrong');

      expect(result, false);
      expect(viewModel.state, ViewState.error);
      expect(viewModel.errorMessage, isNotNull);
    });
  });
}
```

## Widget Testing with Provider

```dart
testWidgets('LoginForm shows loading when ViewModel is busy', (tester) async {
  final viewModel = LoginViewModel(repository: MockAuthRepository());

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider.value(
        value: viewModel,
        child: const Scaffold(body: LoginForm()),
      ),
    ),
  );

  // Initialize responsive scaling if used
  // Responsive.init(tester.element(find.byType(LoginForm)));

  viewModel.state = ViewState.busy;
  await tester.pump();

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## Test Naming

Use descriptive, behavior-focused names:

```dart
test('returns null when user does not exist', () { ... });
test('throws NotFoundException when id is empty string', () { ... });
test('getAll returns failure when remote throws ServerException', () async { });
test('copyWith preserves unchanged fields', () { });
test('empty query returns all items unfiltered', () async { });
testWidgets('disables submit button while form is invalid', (tester) async { ... });
```

## Test Organization

```
test/
├── unit/
│   ├── core/
│   │   └── utils/
│   │       └── validators_test.dart
│   ├── domain/
│   │   └── usecases/
│   │       └── login_usecase_test.dart
│   └── data/
│       └── repositories/
│           └── auth_repository_impl_test.dart
├── widget/
│   └── presentation/
│       └── pages/
│           └── login_page_test.dart
├── golden/
│   └── widgets/
└── helpers/              # Shared test utilities, fakes, fixtures
    ├── pump_app.dart     # Helper to wrap widgets in MaterialApp
    └── fakes.dart

integration_test/
└── flows/
    ├── login_flow_test.dart
    └── checkout_flow_test.dart
```

## Coverage

- Target 80%+ line coverage for business logic (domain + state managers)
- All state transitions must have tests: loading -> success, loading -> error, retry
- Minimum test coverage: BLoC/Cubit + UseCase + Repository for every feature
- Run `flutter test --coverage` and inspect `lcov.info` with a coverage reporter
- View report: `genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html`
- Coverage failures should block CI when below threshold
