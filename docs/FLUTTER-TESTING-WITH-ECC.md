# Flutter Testing with Everything Claude Code

Complete workflow for testing Flutter applications using ECC commands, agents, and skills.

## Quick Reference

| Task | Command/Skill |
|------|---------------|
| Run all tests | `/flutter-test` or `flutter test` |
| Fix test failures | `/flutter-test` (auto-fixes incrementally) |
| Review Flutter code | `/flutter-review` or `flutter-reviewer` agent |
| E2E test setup | `/e2e` skill or `/e2e-testing` skill |
| Build issues | `/flutter-build` or `dart-build-resolver` agent |
| Learn patterns | `/flutter-patterns` skill |
| TDD workflow | `/tdd` command |

## Workflow: Test-Driven Development

### Step 1: Plan Your Feature
```bash
/plan
# OR use the planner agent to design implementation
```

### Step 2: Write Tests First
Before implementing any feature, write your tests.

#### Unit Test Example
```dart
// test/unit/blocs/product_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';

void main() {
  group('ProductBloc', () {
    late ProductRepository mockRepository;
    late ProductBloc productBloc;

    setUp(() {
      mockRepository = MockProductRepository();
      productBloc = ProductBloc(mockRepository);
    });

    blocTest<ProductBloc, ProductState>(
      'emits [ProductLoading, ProductLoaded] when products are fetched',
      build: () => productBloc,
      act: (bloc) => bloc.add(FetchProducts()),
      expect: () => [
        ProductLoading(),
        ProductLoaded(products: [testProduct1, testProduct2]),
      ],
    );
  });
}
```

#### Widget Test Example
```dart
// test/widget/product_card_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductCard', () {
    testWidgets('displays product name and price', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text(testProduct.name), findsOneWidget);
      expect(find.text('\$${testProduct.price}'), findsOneWidget);
    });
  });
}
```

### Step 3: Run Tests (RED Phase)
```bash
/flutter-test
# OR
flutter test --coverage
```

Expected output:
```
FAILED - test/unit/blocs/product_bloc_test.dart
FAILED - test/widget/product_card_test.dart
Coverage: 0% (no implementation yet)
```

### Step 4: Implement Feature (GREEN Phase)
Now implement the minimum code to make tests pass:

```dart
// lib/models/product.dart
class Product {
  final String name;
  final double price;

  Product({required this.name, required this.price});
}

// lib/widgets/product_card.dart
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(product.name),
          Text('\$${product.price}'),
        ],
      ),
    );
  }
}
```

Run tests again:
```bash
/flutter-test
```

Expected:
```
✓ All tests passed
Coverage: 85% (exceeds 80% threshold)
```

### Step 5: Code Review
After implementation, use the Flutter reviewer:

```bash
/flutter-review
# OR invoke manually:
# flutter-reviewer agent
```

The reviewer will check for:
- ✅ Widget best practices (const constructors, immutability)
- ✅ State management patterns (no BLoC anti-patterns)
- ✅ Null safety compliance
- ✅ Performance issues (unnecessary rebuilds)
- ✅ Accessibility (semantic labels, contrast)
- ✅ Error handling (no silently swallowed errors)

### Step 6: Refactor (IMPROVE Phase)
Apply reviewer feedback and optimize:

```dart
// Before: Widget can be optimized
class ProductCard extends StatelessWidget {
  final Product product;

  ProductCard({required this.product}); // Missing const

  @override
  Widget build(BuildContext context) {
    return Column( // Missing Card
      children: [
        Text(product.name),
        Text('\$${product.price}'),
      ],
    );
  }
}

// After: Following best practices
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product}); // Now const

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(
            product.name,
            semanticLabel: 'Product name: ${product.name}',
          ),
          Text(
            '\$${product.price}',
            semanticLabel: 'Price: \$${product.price}',
          ),
        ],
      ),
    );
  }
}
```

Re-run tests to ensure refactoring didn't break anything:
```bash
/flutter-test
```

## Workflow: Debugging Test Failures

When tests fail, use the `/flutter-test` command which automatically:
1. Runs all tests and captures failures
2. Analyzes root cause
3. Fixes issues incrementally
4. Re-runs to verify fixes

### Manual Debugging

If needed, debug specific test:

```bash
# Run single test file
flutter test test/widget/product_card_test.dart

# Run tests matching pattern
flutter test --name "ProductCard"

# Run with verbose output
flutter test -v

# Run with debug output
flutter test --verbose --verbosity=all
```

### Common Failures and Fixes

#### `WidgetNotFound` Exception
```dart
// Problem
testWidgets('shows product', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Product'), findsOneWidget); // FAILS
});

// Solution 1: Pump and settle
testWidgets('shows product', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle(); // Wait for animations
  expect(find.text('Product'), findsOneWidget);
});

// Solution 2: Use proper finder
testWidgets('shows product', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(
    find.byKey(const Key('product_name')),
    findsOneWidget,
  );
});
```

#### `AsyncError` or `TimeoutException`
```dart
// Problem: Animation never completes
testWidgets('taps button', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle(); // Timeout!
});

// Solution: Use explicit pumps
testWidgets('taps button', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pump(); // Single frame
  await tester.pump(Duration(milliseconds: 500));
  // Now interact
});
```

#### Mock Not Working
```dart
// Problem: Mock.stream never emits
testWidgets('displays bloc state', (tester) async {
  when(bloc.stream).thenReturn(Stream.empty());
  // ... test never sees state change
});

// Solution: Use StreamController
StreamController<BlocState> controller;

setUp(() {
  controller = StreamController<BlocState>();
  when(bloc.stream).thenAnswer((_) => controller.stream);
});

tearDown(() => controller.close());

testWidgets('displays bloc state', (tester) async {
  controller.add(BlocStateLoaded());
  // ... now test sees state
});
```

## Workflow: Integration Testing

For end-to-end testing of complete flows:

### 1. Set Up Integration Tests
```
integration_test/
├── auth_flow_test.dart
├── checkout_flow_test.dart
└── fixtures/
    └── test_data.dart
```

### 2. Run on Device
```bash
# Run on connected device/emulator
flutter test integration_test/

# Run specific flow
flutter test integration_test/auth_flow_test.dart

# Run on iOS
flutter test integration_test/ -d ios

# Run with verbose output
flutter test integration_test/ --verbose
```

### 3. Verify with E2E Skill
For web versions or Playwright-based tests:

```bash
/e2e
# Ask for: "Create E2E test for Flutter checkout flow"
```

The e2e-runner agent will:
1. Generate Playwright tests for your web version
2. Run tests and capture artifacts
3. Report failures and flakes
4. Suggest improvements

## Best Practices for Flutter Testing

### 1. Test Organization
```
test/
├── unit/                 # Pure Dart tests
│   ├── models/
│   ├── blocs/
│   └── repositories/
├── widget/               # UI component tests
│   ├── screens/
│   └── widgets/
├── integration/          # Multi-component flows
│   └── flows/
├── fixtures/             # Test data and mocks
│   ├── mocks.dart
│   └── test_data.dart
└── helpers/              # Test utilities
    └── test_utils.dart
```

### 2. Naming Conventions
```dart
// ✓ Clear, descriptive names
void testUserCanAddProductToCart() { }
void testEmptyCartShowsEmptyState() { }
void testNetworkErrorShowsRetryButton() { }

// ✗ Vague names
void testAddProduct() { }
void testUI() { }
void testError() { }
```

### 3. Use Fixtures for Reusable Data
```dart
// test/fixtures/test_data.dart
final testProduct = Product(
  id: 'test-1',
  name: 'Test Product',
  price: 99.99,
);

final testUser = User(
  id: 'test-user',
  name: 'Test User',
  email: 'test@example.com',
);

// Usage in tests
testWidgets('shows product', (tester) async {
  await tester.pumpWidget(ProductCard(product: testProduct));
  expect(find.text(testProduct.name), findsOneWidget);
});
```

### 4. Mock External Dependencies
```dart
// test/fixtures/mocks.dart
class MockProductRepository extends Mock implements ProductRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthService extends Mock implements AuthService {}
class MockCartCubit extends Mock implements CartCubit {}

// Usage
setUp(() {
  mockRepository = MockProductRepository();
  when(mockRepository.getProducts())
      .thenAnswer((_) async => [testProduct]);
});
```

### 5. Test Key User Flows
Focus on critical paths:
- ✅ Authentication (login, signup, logout)
- ✅ Core features (add to cart, checkout, create post)
- ✅ Error states (network failure, invalid input)
- ✅ Edge cases (empty list, max quantity)

**Don't test:**
- ✗ Framework internals (unless you're modifying them)
- ✗ Library behavior (assume it works)
- ✗ Trivial getters/setters
- ✗ Implementation details

## Performance Tips

### Coverage Optimization
```bash
# Generate coverage only for lib/
flutter test --coverage \
  --coverage-path=coverage/lcov.info

# Exclude generated files
# Add to pubspec.yaml:
coverage:
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - '**/generated/**'
```

### Test Execution Speed
```bash
# Run tests in parallel (up to 4 shards)
flutter test --shard=1/4
flutter test --shard=2/4
flutter test --shard=3/4
flutter test --shard=4/4

# Run only unit tests (fastest)
flutter test --tags=unit

# Skip slow integration tests in CI
flutter test --exclude-tags=integration
```

## CI/CD with GitHub Actions

```yaml
name: Flutter Tests

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
        run: |
          flutter test --coverage --exclude-tags=integration

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: flutter

      - name: Check coverage threshold
        run: |
          threshold=80
          coverage=$(grep 'LH:' coverage/lcov.info | cut -d: -f2 | paste -sd+ - | bc)
          total=$(grep 'LF:' coverage/lcov.info | cut -d: -f2 | paste -sd+ - | bc)
          percent=$((coverage * 100 / total))
          if [ $percent -lt $threshold ]; then
            echo "Coverage $percent% is below $threshold% threshold"
            exit 1
          fi
```

## Related Commands and Skills

| Tool | Purpose |
|------|---------|
| `/flutter-test` | Run Flutter tests and fix failures |
| `/flutter-build` | Fix Flutter build errors |
| `/flutter-review` | Code review for Flutter |
| `/flutter-patterns` | State management and widget patterns |
| `/flutter-dart-code-review` | Detailed code review checklist |
| `/e2e` or `/e2e-testing` | End-to-end Playwright tests |
| `/tdd` | Test-driven development workflow |
| `flutter-reviewer` agent | Comprehensive code review |
| `dart-build-resolver` agent | Fix Dart/build errors |
| `e2e-runner` agent | Generate and run E2E tests |

## Troubleshooting

### Tests Won't Run
```bash
# Check Flutter setup
flutter doctor

# Get dependencies
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get

# Run with verbose output
flutter test --verbose
```

### Coverage Not Generated
```bash
# Coverage requires lcov (macOS)
brew install lcov

# Linux
sudo apt-get install lcov

# Generate and view
flutter test --coverage
open coverage/lcov.html
```

### Golden Tests Failing
```bash
# Update golden files
flutter test --update-goldens

# Or for specific files
flutter test test/goldens/ --update-goldens
```

## Further Reading

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [BLoC Testing](https://bloclibrary.dev/testing)
- [Riverpod Testing](https://riverpod.dev/docs/essentials/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- **ECC Skills:** `/flutter-patterns`, `/dart-flutter-patterns`, `/e2e-testing`
