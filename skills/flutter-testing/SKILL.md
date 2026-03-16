---
name: flutter-testing
description: Flutter TDD workflow with widget tests, BLoC tests, golden tests, integration tests, mocktail fakes, test organization, and coverage enforcement. Use when writing new features, fixing bugs, or refactoring Flutter code.
---

# Flutter Testing Workflow

This skill ensures Flutter development follows TDD principles with comprehensive test coverage across widget, unit, BLoC, golden, and integration tests.

## When to Activate

- Writing new Flutter features or widgets
- Fixing bugs in Flutter applications
- Refactoring existing Flutter code
- Adding BLoC/Cubit business logic
- Creating reusable UI components

## Core Principles

### 1. Tests BEFORE Code
ALWAYS write tests first, then implement widgets and logic to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + widget + integration)
- All BLoC state transitions covered
- All error scenarios tested
- Edge cases and boundary conditions verified

### 3. Test Types (All Required)

| Type | What to Test | Tool |
|------|-------------|------|
| **Unit** | Use cases, repositories, utilities, models | `flutter_test` |
| **Widget** | Individual widgets, pages, user interaction | `flutter_test` + `testWidgets` |
| **BLoC** | State transitions, event handling | `bloc_test` |
| **Golden** | Visual regression for key components | `matchesGoldenFile` |
| **Integration** | Complete user flows, multi-screen navigation | `integration_test` |

## TDD Workflow Steps

### Step 1: Write the Test (RED)

```dart
// test/features/items/presentation/bloc/item_list_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetItemsUseCase extends Mock implements GetItemsUseCase {}

void main() {
  late MockGetItemsUseCase mockGetItems;

  setUp(() {
    mockGetItems = MockGetItemsUseCase();
  });

  group('ItemListBloc', () {
    blocTest<ItemListBloc, ItemListState>(
      'emits [loading, loaded] when LoadItems succeeds',
      build: () {
        when(() => mockGetItems()).thenAnswer(
          (_) async => Right([testItem]),
        );
        return ItemListBloc(getItems: mockGetItems);
      },
      act: (bloc) => bloc.add(const LoadItems()),
      expect: () => [
        const ItemListState.loading(),
        ItemListState.loaded([testItem]),
      ],
    );

    blocTest<ItemListBloc, ItemListState>(
      'emits [loading, error] when LoadItems fails',
      build: () {
        when(() => mockGetItems()).thenAnswer(
          (_) async => const Left(ServerFailure('Network error')),
        );
        return ItemListBloc(getItems: mockGetItems);
      },
      act: (bloc) => bloc.add(const LoadItems()),
      expect: () => [
        const ItemListState.loading(),
        const ItemListState.error('Network error'),
      ],
    );
  });
}
```

### Step 2: Run Tests (They Should Fail)

```bash
flutter test
# Tests should fail — BLoC not implemented yet
```

### Step 3: Implement Minimal Code (GREEN)

```dart
// lib/features/items/presentation/bloc/item_list_bloc.dart
class ItemListBloc extends Bloc<ItemListEvent, ItemListState> {
  ItemListBloc({required GetItemsUseCase getItems})
      : _getItems = getItems,
        super(const ItemListState.initial()) {
    on<LoadItems>(_onLoadItems);
  }

  final GetItemsUseCase _getItems;

  Future<void> _onLoadItems(LoadItems event, Emitter<ItemListState> emit) async {
    emit(const ItemListState.loading());
    final result = await _getItems();
    result.fold(
      (failure) => emit(ItemListState.error(failure.message)),
      (items) => emit(ItemListState.loaded(items)),
    );
  }
}
```

### Step 4: Run Tests Again (GREEN)

```bash
flutter test
# All tests should now pass
```

### Step 5: Add Widget Tests

```dart
testWidgets('ItemListPage shows loading indicator', (tester) async {
  final bloc = MockItemListBloc();
  when(() => bloc.state).thenReturn(const ItemListState.loading());
  whenListen(bloc, Stream<ItemListState>.empty());

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<ItemListBloc>.value(
        value: bloc,
        child: const ItemListPage(),
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('ItemListPage shows items when loaded', (tester) async {
  final bloc = MockItemListBloc();
  when(() => bloc.state).thenReturn(ItemListState.loaded([testItem]));
  whenListen(bloc, Stream<ItemListState>.empty());

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<ItemListBloc>.value(
        value: bloc,
        child: const ItemListPage(),
      ),
    ),
  );

  expect(find.text(testItem.name), findsOneWidget);
});
```

### Step 6: Refactor (IMPROVE)

Improve code quality while keeping tests green:
- Extract shared test helpers to `test/helpers/`
- Remove duplication in widget setup (create `pumpApp` helper)
- Improve naming and readability

### Step 7: Verify Coverage

```bash
flutter test --coverage
# Verify 80%+ coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Testing Patterns

### pumpApp Helper

Create a shared helper to avoid repeating `MaterialApp` wrapping:

```dart
// test/helpers/pump_app.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<BlocProvider> providers = const [],
  }) async {
    await pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: providers,
          child: Scaffold(body: widget),
        ),
      ),
    );
  }
}
```

### Mock BLoC with mocktail

```dart
class MockItemListBloc extends MockBloc<ItemListEvent, ItemListState>
    implements ItemListBloc {}

// Usage in tests
final bloc = MockItemListBloc();
when(() => bloc.state).thenReturn(const ItemListState.loading());
```

### Fake Repository

```dart
class FakeItemRepository implements ItemRepository {
  final List<Item> _items = [];
  Failure? nextError;

  @override
  Future<Either<Failure, List<Item>>> getAll() async {
    if (nextError != null) return Left(nextError!);
    return Right(List.unmodifiable(_items));
  }

  void seed(List<Item> items) {
    _items
      ..clear()
      ..addAll(items);
  }
}
```

### Golden Test Pattern

```dart
testWidgets('ItemCard golden test', (tester) async {
  await tester.pumpApp(
    const ItemCard(
      item: Item(id: '1', name: 'Golden Item', description: 'For snapshot'),
    ),
  );

  await expectLater(
    find.byType(ItemCard),
    matchesGoldenFile('goldens/item_card.png'),
  );
});
```

Update goldens: `flutter test --update-goldens`

### Integration Test Pattern

```dart
// integration_test/item_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can view and search items', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify list loads
    expect(find.byType(ItemCard), findsWidgets);

    // Search
    await tester.enterText(find.byKey(const Key('search_field')), 'test');
    await tester.pumpAndSettle();

    // Verify filtered results
    expect(find.text('No items found'), findsNothing);
  });
}
```

## Test Organization

```
test/
├── helpers/
│   ├── pump_app.dart          # Widget test helper
│   ├── fakes.dart             # Fake repositories
│   ├── mocks.dart             # Mock BLoCs and use cases
│   └── test_data.dart         # Shared test fixtures
├── core/
│   └── utils/
│       └── validators_test.dart
├── features/
│   └── items/
│       ├── data/
│       │   └── repositories/
│       │       └── item_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       └── get_items_usecase_test.dart
│       └── presentation/
│           ├── bloc/
│           │   └── item_list_bloc_test.dart
│           └── widgets/
│               ├── item_card_test.dart
│               └── goldens/
│                   └── item_card.png
integration_test/
└── item_flow_test.dart
```

## Common Mistakes to Avoid

### ❌ WRONG: Not pumping after state change
```dart
await tester.tap(find.byType(ElevatedButton));
expect(find.text('Result'), findsOneWidget); // Fails — widget hasn't rebuilt
```

### ✅ CORRECT: Pump after interaction
```dart
await tester.tap(find.byType(ElevatedButton));
await tester.pumpAndSettle(); // Wait for rebuild
expect(find.text('Result'), findsOneWidget);
```

### ❌ WRONG: Testing implementation details
```dart
expect(bloc.repository.cache.length, 5); // Testing internals
```

### ✅ CORRECT: Test observable behavior
```dart
expect(bloc.state, ItemListState.loaded(expectedItems));
```

### ❌ WRONG: Shared mutable state between tests
```dart
final items = <Item>[]; // Shared across tests — causes flakiness
```

### ✅ CORRECT: Fresh state per test
```dart
late List<Item> items;
setUp(() { items = []; }); // Reset each test
```

## CI/CD Integration

```yaml
# GitHub Actions
- name: Run Flutter tests with coverage
  run: flutter test --coverage
- name: Check coverage threshold
  run: |
    COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -o '[0-9.]*%')
    echo "Coverage: $COVERAGE"
```

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- BLoC state transitions fully covered
- Golden tests for key UI components
- Integration tests cover critical user flows
- Fast test execution (<60s for unit + widget tests)

---

**Remember**: In Flutter, widget tests are cheap and fast — write many of them. They catch layout issues, missing text, broken interactions, and regression bugs before they reach users.
