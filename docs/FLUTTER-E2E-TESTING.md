# Flutter E2E Testing Guide

Complete end-to-end testing strategies for Flutter applications using both native Flutter test frameworks and integration patterns.

## Overview

This guide covers:
1. **Native Flutter Testing** — Unit, widget, and integration tests using `flutter test`
2. **E2E Testing Strategies** — Testing complete user flows across platforms
3. **Test Organization** — Best practices for test structure and artifacts
4. **Debugging** — Tools and techniques for flaky test investigation
5. **CI/CD Integration** — Running tests in GitHub Actions and other platforms

## Quick Start

### Run All Tests
```bash
# Unit + Widget + Integration tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/widgets/home_page_test.dart
```

### Run Tests by Type
```bash
# Only unit tests
flutter test --tags=unit

# Only widget tests
flutter test --tags=widget

# Only integration tests (requires device/emulator)
flutter test integration_test/

# Tests matching a pattern
flutter test --name "CartBloc"
```

### Generate Coverage Report
```bash
# Run with coverage
flutter test --coverage

# View coverage (macOS)
open coverage/lcov.html

# View coverage (Linux)
xdg-open coverage/lcov.html
```

## Test File Organization

```
project/
├── lib/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   ├── blocs/
│   └── screens/
├── test/
│   ├── unit/
│   │   ├── models/
│   │   ├── blocs/
│   │   ├── repositories/
│   │   └── services/
│   ├── widget/
│   │   ├── screens/
│   │   └── widgets/
│   ├── integration/
│   │   └── flows/
│   ├── fixtures/
│   │   ├── mocks.dart
│   │   └── test_data.dart
│   └── helpers/
│       └── test_utils.dart
└── integration_test/
    ├── app_test.dart
    └── auth_flow_test.dart
```

## Unit Testing

Test business logic in isolation.

### Testing BLoC/Cubit

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartCubit', () {
    late CartRepository mockRepository;
    late CartCubit cartCubit;

    setUp(() {
      mockRepository = MockCartRepository();
      cartCubit = CartCubit(mockRepository);
    });

    tearDown(() => cartCubit.close());

    blocTest<CartCubit, CartState>(
      'emits [Loading, Loaded] when items are added',
      build: () => cartCubit,
      act: (cubit) => cubit.addItem(testProduct),
      expect: () => [
        CartLoading(),
        CartLoaded(items: [testProduct]),
      ],
    );

    blocTest<CartCubit, CartState>(
      'emits [Loading, Error] when repository fails',
      setUp: () {
        when(mockRepository.addItem(any))
            .thenThrow(Exception('Network error'));
      },
      build: () => cartCubit,
      act: (cubit) => cubit.addItem(testProduct),
      expect: () => [
        CartLoading(),
        CartError(message: 'Failed to add item'),
      ],
    );
  });
}
```

### Testing Riverpod Providers

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userProvider', () {
    test('returns user from repository', () async {
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockUserRepository),
        ],
      );

      final user = await container.read(userProvider.future);
      expect(user.id, 'test-id');
      expect(user.name, 'Test User');
    });

    test('handles repository error', () async {
      when(mockUserRepository.getUser())
          .thenThrow(Exception('Not found'));

      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockUserRepository),
        ],
      );

      expect(
        () => container.read(userProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

## Widget Testing

Test UI components in isolation.

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartButton', () {
    testWidgets('displays cart count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartButton(itemCount: 5),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartButton(
              itemCount: 0,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CartButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
```

### Testing BLoC-Connected Widgets

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartPage', () {
    late CartCubit mockCartCubit;

    setUp(() {
      mockCartCubit = MockCartCubit();
    });

    testWidgets('shows loading when CartLoading state',
        (WidgetTester tester) async {
      when(mockCartCubit.state).thenReturn(CartLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CartCubit>.value(
            value: mockCartCubit,
            child: CartPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows items when CartLoaded state',
        (WidgetTester tester) async {
      final items = [testProduct1, testProduct2];
      when(mockCartCubit.state).thenReturn(CartLoaded(items: items));
      when(mockCartCubit.stream)
          .thenAnswer((_) => Stream.value(CartLoaded(items: items)));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CartCubit>.value(
            value: mockCartCubit,
            child: CartPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ProductTile), findsNWidgets(2));
      expect(find.text(testProduct1.name), findsOneWidget);
    });
  });
}
```

## Integration Testing

Test complete user flows with real dependencies (or mocked backend).

### Basic Integration Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow', () {
    testWidgets('User can log in with valid credentials',
        (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byKey(Key('email_input')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_input')), 'password123');

      // Tap login button
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify navigation to home screen
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('Error message shown with invalid credentials',
        (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(find.byKey(Key('email_input')), 'invalid@test.com');
      await tester.enterText(find.byKey(Key('password_input')), 'wrong');

      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
```

### Running Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/

# Run specific test
flutter test integration_test/auth_flow_test.dart

# Run with performance trace
flutter test integration_test/ --verbose --trace-startup

# Run on iOS
flutter test integration_test/ -d ios

# Run on Android
flutter test integration_test/ -d android
```

## Golden Testing

Test visual regressions with golden files.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Product Card Golden Tests', () {
    testWidgets('renders correctly on mobile',
        (WidgetTester tester) async {
      await tester.binding.window.physicalSizeTestValue = Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      await expectLater(
        find.byType(ProductCard),
        matchesGoldenFile('goldens/product_card_mobile.png'),
      );
    });

    testWidgets('renders correctly on tablet',
        (WidgetTester tester) async {
      await tester.binding.window.physicalSizeTestValue = Size(1024, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      await expectLater(
        find.byType(ProductCard),
        matchesGoldenFile('goldens/product_card_tablet.png'),
      );
    });
  });
}
```

### Updating Golden Files

When intentional UI changes are made:

```bash
# Update all golden files
flutter test --update-goldens

# Update specific test
flutter test test/goldens/product_card_test.dart --update-goldens
```

## Testing Patterns

### Using Test Fixtures

```dart
// test/fixtures/test_data.dart
final testUser = User(
  id: 'test-id',
  name: 'Test User',
  email: 'test@example.com',
);

final testProduct = Product(
  id: 'prod-1',
  name: 'Test Product',
  price: 99.99,
);

// test/fixtures/mocks.dart
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthService extends Mock implements AuthService {}
class MockCartCubit extends Mock implements CartCubit {}
```

### Helper Functions

```dart
// test/helpers/test_utils.dart
extension PumpApp on WidgetTester {
  Future<void> pumpMyApp({
    required Widget widget,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    binding.window.physicalSizeTestValue = Size(400, 800);
    binding.window.devicePixelRatioTestValue = 1.0;

    await pumpWidget(
      MaterialApp(
        home: Scaffold(body: widget),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Usage in tests
testWidgets('displays correctly', (tester) async {
  await tester.pumpMyApp(widget: MyWidget());
  expect(find.text('Hello'), findsOneWidget);
});
```

## Common Issues and Solutions

### Issue: `pumpAndSettle` Timeout
```dart
// Problem: Animation never settles
await tester.pumpAndSettle(); // TimeoutException!

// Solution: Use explicit pump with duration
await tester.pump(Duration(milliseconds: 500));
await tester.pump(Duration(milliseconds: 500));

// Or disable animations in tests
testWidgets('test', (tester) async {
  tester.binding.window.onBeginFrame = null;
  tester.binding.scheduleFrame();
  // ... test code
});
```

### Issue: Widget Not Found After State Change
```dart
// Problem: State changed but widget not found
final item = find.text('Hello');
expect(item, findsOneWidget); // Fails

// Solution: Pump and settle to apply changes
await tester.pumpAndSettle();
expect(item, findsOneWidget);

// Or pump with duration
await tester.pump(Duration(milliseconds: 300));
```

### Issue: Mock Not Working in Stream Tests
```dart
// Problem: Mock stream never emits
when(cubit.stream).thenReturn(Stream.empty());

// Solution: Create actual stream or use StreamController
final controller = StreamController<CartState>();
when(cubit.stream).thenAnswer((_) => controller.stream);

addTearDown(controller.close);
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Get dependencies
        run: flutter pub get

      - name: Run unit and widget tests
        run: flutter test --coverage

      - name: Generate coverage report
        run: |
          pub global activate coverage
          pub global run coverage:format_coverage \
            --packages=.packages \
            --report-on=lib \
            --in=coverage \
            --out=coverage/coverage.json

      - name: Upload coverage to codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.json

      - name: Run integration tests
        run: flutter test integration_test/ --dart-define=CI=true
```

## Test Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage summary
cat coverage/lcov.info

# Minimum coverage check
flutter test --coverage
coverage_percent=$(grep -o 'LF:[0-9]*' coverage/lcov.info | cut -d: -f2)
covered=$(grep -o 'LH:[0-9]*' coverage/lcov.info | cut -d: -f2)
percentage=$((covered * 100 / coverage_percent))
echo "Coverage: $percentage%"

if [ $percentage -lt 80 ]; then
  echo "Coverage below 80% threshold"
  exit 1
fi
```

## Best Practices

1. **Test Naming** — Use descriptive names that read like sentences
   ```dart
   test('user_can_add_items_to_cart')  // ✓ Clear intent
   test('add_to_cart')                 // ✗ Vague
   ```

2. **Arrange-Act-Assert** — Keep test structure clear
   ```dart
   testWidgets('shows empty state', (tester) async {
     // Arrange
     await tester.pumpMyApp(widget: CartPage());

     // Act
     await tester.tap(find.byKey(Key('clear_all')));
     await tester.pumpAndSettle();

     // Assert
     expect(find.text('Your cart is empty'), findsOneWidget);
   });
   ```

3. **Avoid Implementation Details** — Test behavior, not implementation
   ```dart
   // ✓ Test the behavior
   expect(find.text('Error'), findsOneWidget);

   // ✗ Don't test internal state
   expect(cartCubit.state.hasError, isTrue);
   ```

4. **Use Test Tags** — Organize tests by type
   ```dart
   test('calculates total', tags: ['unit'], () { ... });
   testWidgets('shows total', tags: ['widget'], () { ... });
   testWidgets('flow works end-to-end', tags: ['integration'], () { ... });
   ```

## Related Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [BLoC Testing Guide](https://bloclibrary.dev/#/fluttertodostesting)
- [Riverpod Testing Guide](https://riverpod.dev/docs/essentials/testing)
- [Golden Toolkit](https://pub.dev/packages/golden_toolkit)
- **ECC Skills**
  - `/flutter-patterns` — State management and widget patterns
  - `/flutter-dart-code-review` — Code review checklist
  - `/e2e-testing` — Playwright and E2E patterns
- **ECC Agents**
  - `flutter-reviewer` — Code review for Flutter
  - `dart-build-resolver` — Fix build errors
  - `e2e-runner` — Generate and run E2E tests
