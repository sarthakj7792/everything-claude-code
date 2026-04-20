---
name: flutter-e2e-testing
description: Flutter E2E testing patterns covering integration tests, golden files, mocking strategies, test organization, CI/CD setup, and complete user flow testing for iOS, Android, and web platforms.
origin: ECC
---

# Flutter E2E Testing

Production-ready patterns for end-to-end testing in Flutter applications across all platforms (iOS, Android, Web).

## When to Use

Use this skill when:
- Building E2E tests that validate complete user journeys (login → action → logout)
- Testing Flutter apps on real devices or emulators
- Ensuring critical flows work across iOS and Android
- Setting up integration tests in CI/CD pipelines
- Implementing golden/snapshot tests for UI regression detection
- Mocking external dependencies (API, auth, databases)
- Testing offline behavior and error states
- Validating platform-specific behaviors

## How It Works

This skill provides production-ready Flutter E2E testing patterns organized by:
1. **Test Structure** — File organization, naming conventions, fixtures
2. **Integration Testing** — Real device testing, async handling, finders
3. **Mocking Strategies** — Mocking APIs, services, platform channels
4. **Golden Testing** — Visual regression detection, multi-device testing
5. **Test Utilities** — Custom helpers, PumpApp extensions, test data
6. **CI/CD Integration** — GitHub Actions, coverage enforcement, artifact management
7. **Common Patterns** — Authentication flows, list operations, error handling

---

## Test Organization

```
project/
├── lib/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   ├── blocs/
│   ├── screens/
│   └── widgets/
├── test/
│   ├── unit/
│   │   ├── models/
│   │   │   └── user_model_test.dart
│   │   ├── blocs/
│   │   │   └── auth_bloc_test.dart
│   │   └── repositories/
│   │       └── user_repository_test.dart
│   ├── widget/
│   │   ├── screens/
│   │   │   └── login_screen_test.dart
│   │   └── widgets/
│   │       └── product_card_test.dart
│   ├── integration/
│   │   ├── auth_flow_test.dart
│   │   ├── checkout_flow_test.dart
│   │   └── search_flow_test.dart
│   ├── fixtures/
│   │   ├── mocks.dart
│   │   ├── test_data.dart
│   │   └── mock_server.dart
│   └── helpers/
│       └── test_utils.dart
├── integration_test/
│   ├── app_test.dart
│   ├── auth_test.dart
│   └── e2e_flows/
│       ├── login_signup_test.dart
│       └── purchase_flow_test.dart
└── test/goldens/
    ├── product_card_mobile.png
    ├── product_card_tablet.png
    └── product_card_web.png
```

---

## Integration Testing Fundamentals

### Basic Integration Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication E2E Flow', () {
    testWidgets(
      'User can log in with valid credentials',
      (WidgetTester tester) async {
        // 1. Launch the app
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // 2. Verify login screen
        expect(find.byType(LoginScreen), findsOneWidget);

        // 3. Enter credentials
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );

        // 4. Tap login button
        await tester.tap(find.byKey(const Key('login_btn')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 5. Verify navigation to home
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });
}
```

### Running Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/

# Run specific test file
flutter test integration_test/auth_test.dart

# Run on iOS
flutter test integration_test/ -d ios

# Run on Android
flutter test integration_test/ -d android

# Run with specific orientation
flutter test integration_test/ --dart-define=ORIENTATION=portrait

# Verbose output for debugging
flutter test integration_test/ --verbose
```

---

## Complete User Flow Testing

### E-Commerce Checkout Flow

```dart
testWidgets(
  'User can complete purchase end-to-end',
  (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Step 1: Browse products
    expect(find.byType(ProductsScreen), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);

    // Step 2: Open product details
    await tester.tap(find.byKey(const Key('product_0')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(ProductDetailScreen), findsOneWidget);

    // Step 3: Add to cart
    await tester.tap(find.byKey(const Key('add_to_cart_btn')));
    await tester.pumpAndSettle();

    // Verify success message
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Added to cart'), findsOneWidget);

    // Step 4: Navigate to cart
    await tester.tap(find.byKey(const Key('cart_icon')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(CartScreen), findsOneWidget);

    // Step 5: Proceed to checkout
    await tester.tap(find.byKey(const Key('checkout_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(CheckoutScreen), findsOneWidget);

    // Step 6: Fill shipping info
    await _fillShippingForm(tester);

    // Step 7: Complete payment
    await tester.tap(find.byKey(const Key('place_order_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Step 8: Verify order confirmation
    expect(find.byType(OrderConfirmationScreen), findsOneWidget);
    expect(find.text('Order Confirmed'), findsOneWidget);

    // Take screenshot for documentation
    await tester.takeScreenshot('order_confirmation');
  },
)

Future<void> _fillShippingForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('address_field')),
    '123 Main St',
  );
  await tester.enterText(
    find.byKey(const Key('city_field')),
    'Springfield',
  );
  await tester.enterText(
    find.byKey(const Key('state_field')),
    'IL',
  );
  await tester.enterText(
    find.byKey(const Key('zip_field')),
    '62701',
  );
  await tester.pumpAndSettle();
}
```

### Authentication Flow

```dart
testWidgets(
  'New user signup and login flow',
  (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Navigate to signup
    await tester.tap(find.byKey(const Key('signup_link')));
    await tester.pumpAndSettle();

    // Fill signup form
    await tester.enterText(
      find.byKey(const Key('name_input')),
      'John Doe',
    );
    await tester.enterText(
      find.byKey(const Key('email_input')),
      'john@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_input')),
      'SecurePass123!',
    );

    // Accept terms
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Submit signup
    await tester.tap(find.byKey(const Key('signup_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify email verification screen
    expect(find.byType(EmailVerificationScreen), findsOneWidget);

    // Mock email verification (in real app, user clicks link)
    await tester.tap(find.byKey(const Key('verify_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify logged in and on home screen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Welcome, John Doe'), findsOneWidget);
  },
)
```

---

## Mocking Strategies

### Mocking HTTP Requests

```dart
// test/fixtures/mocks.dart
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

class MockDio extends Mock implements Dio {}

// In your test
testWidgets('displays products from API', (tester) async {
  final mockDio = MockDio();

  // Mock successful response
  when(mockDio.get(any)).thenAnswer((_) async => Response(
    data: [
      {'id': '1', 'name': 'Product 1', 'price': 99.99},
      {'id': '2', 'name': 'Product 2', 'price': 149.99},
    ],
    statusCode: 200,
    requestOptions: RequestOptions(path: ''),
  ));

  final repository = ProductRepository(mockDio);

  await tester.pumpWidget(
    MyApp(productRepository: repository),
  );
  await tester.pumpAndSettle();

  expect(find.text('Product 1'), findsOneWidget);
  expect(find.text('Product 2'), findsOneWidget);
});
```

### Mocking Authentication Service

```dart
class MockAuthService extends Mock implements AuthService {
  @override
  Future<AuthResult> login(String email, String password) async {
    if (email == 'test@example.com' && password == 'password123') {
      return AuthResult(
        success: true,
        user: User(
          id: 'test-id',
          name: 'Test User',
          email: email,
        ),
        token: 'mock-jwt-token',
      );
    }
    throw AuthException('Invalid credentials');
  }
}

// Usage in test
setUp(() {
  mockAuthService = MockAuthService();
});

testWidgets('login succeeds with correct credentials', (tester) async {
  // ... test code
});
```

### Mocking Database

```dart
class MockLocalDatabase extends Mock implements LocalDatabase {
  @override
  Future<List<Product>> getProducts() async {
    return [testProduct1, testProduct2];
  }

  @override
  Future<void> saveProduct(Product product) async {
    // Mock implementation
  }
}

testWidgets('shows cached products when offline', (tester) async {
  final mockDb = MockLocalDatabase();

  await tester.pumpWidget(
    MyApp(database: mockDb),
  );
  await tester.pumpAndSettle();

  final products = await mockDb.getProducts();
  expect(products.length, 2);
});
```

### Mocking Platform Channels

```dart
testWidgets('handles platform channel calls', (tester) async {
  // Mock the method channel
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.example.app/native'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getDeviceInfo') {
        return {'os': 'iOS', 'version': '16.0'};
      }
      return null;
    },
  );

  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  // Test code that triggers platform channel calls
  expect(find.text('iOS 16.0'), findsOneWidget);
});
```

---

## Golden/Snapshot Testing

### Basic Golden Test

```dart
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Product Card Golden Tests', () {
    testWidgets('renders correctly on mobile', (tester) async {
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

    testWidgets('renders correctly on tablet', (tester) async {
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

### Multi-Device Golden Testing

```dart
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('login screen on multiple devices', (tester) async {
    final builder = GoldenBuilder.grid(columns: 2, widthToHeightRatio: 1.0)
      ..addScenario(
        'Mobile Portrait',
        const LoginScreen(),
        size: const Size(400, 800),
      )
      ..addScenario(
        'Mobile Landscape',
        const LoginScreen(),
        size: const Size(800, 400),
      )
      ..addScenario(
        'Tablet',
        const LoginScreen(),
        size: const Size(1024, 600),
      )
      ..addScenario(
        'Desktop',
        const LoginScreen(),
        size: const Size(1920, 1080),
      );

    await tester.pumpWidgetBuilder(builder.build());
    await expectLater(
      find.byType(GoldenBuilder),
      matchesGoldenFile('goldens/login_screen_all_devices.png'),
    );
  });
}
```

### Updating Golden Files

```bash
# Update all golden files
flutter test --update-goldens

# Update specific golden test
flutter test test/goldens/product_card_test.dart --update-goldens

# Compare goldens (on macOS)
open test/goldens/product_card_mobile.png
```

---

## Test Utilities and Helpers

### Custom PumpApp Extension

```dart
// test/helpers/test_utils.dart
extension PumpApp on WidgetTester {
  Future<void> pumpMyApp({
    required Widget widget,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    binding.window.physicalSizeTestValue = const Size(400, 800);
    binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(binding.window.clearPhysicalSizeTestValue);

    await pumpWidget(
      MaterialApp(
        home: Scaffold(body: widget),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  Future<void> pumpWithOverrides({
    required Widget widget,
    required List<Override> overrides,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}

// Usage
testWidgets('displays product', (tester) async {
  await tester.pumpMyApp(widget: const ProductCard(product: testProduct));
  expect(find.text(testProduct.name), findsOneWidget);
});
```

### Test Fixtures

```dart
// test/fixtures/test_data.dart
const testProduct = Product(
  id: 'prod-1',
  name: 'Test Product',
  price: 99.99,
  imageUrl: 'https://example.com/image.jpg',
);

const testUser = User(
  id: 'user-1',
  name: 'Test User',
  email: 'test@example.com',
);

const testCart = Cart(
  id: 'cart-1',
  items: [testProduct],
  total: 99.99,
);

// Batch test data
final testProducts = List.generate(
  10,
  (i) => Product(
    id: 'prod-$i',
    name: 'Product $i',
    price: 99.99 + i,
  ),
);
```

### Mock Factories

```dart
// test/fixtures/mocks.dart
class MockRepository extends Mock implements ProductRepository {
  Future<List<Product>> mockGetProducts([List<Product>? products]) async {
    return products ?? [testProduct];
  }

  Future<Product> mockGetProduct(String id, [Product? product]) async {
    return product ?? testProduct;
  }
}

// Usage
setUp(() {
  mockRepository = MockRepository();
  when(mockRepository.getProducts()).thenAnswer(
    (_) => mockRepository.mockGetProducts([testProduct1, testProduct2]),
  );
});
```

---

## Common Test Patterns

### Testing Lists with Pagination

```dart
testWidgets('loads more products on scroll', (tester) async {
  final products = List.generate(
    25,
    (i) => Product(id: 'prod-$i', name: 'Product $i', price: 9.99),
  );

  await tester.pumpWidget(MyApp(products: products));
  await tester.pumpAndSettle();

  // Verify initial batch loaded
  expect(find.byType(ProductTile), findsNWidgets(10));

  // Scroll to bottom
  await tester.drag(
    find.byType(ListView),
    const Offset(0, -500),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // Verify more products loaded
  expect(find.byType(ProductTile), findsWidgets);
});
```

### Testing Search Functionality

```dart
testWidgets('filters products by search query', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  // Enter search query
  await tester.enterText(
    find.byKey(const Key('search_field')),
    'laptop',
  );
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verify filtered results
  expect(find.byType(ProductTile), findsWidgets);
  expect(find.text('Laptop'), findsOneWidget);

  // Clear search
  await tester.tap(find.byKey(const Key('clear_search')));
  await tester.pumpAndSettle();

  // Verify all products shown again
  expect(find.byType(ProductTile), findsWidgets);
});
```

### Testing Dialogs and Overlays

```dart
testWidgets('shows confirmation dialog on delete', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  // Trigger delete action
  await tester.tap(find.byIcon(Icons.delete));
  await tester.pumpAndSettle();

  // Verify dialog shown
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('Delete this item?'), findsOneWidget);

  // Tap confirm
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  // Verify item removed
  expect(find.byType(AlertDialog), findsNothing);
});
```

### Testing Form Validation

```dart
testWidgets('validates form inputs', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  // Try to submit empty form
  await tester.tap(find.byKey(const Key('submit_btn')));
  await tester.pumpAndSettle();

  // Verify error messages
  expect(find.text('Email is required'), findsOneWidget);
  expect(find.text('Password is required'), findsOneWidget);

  // Fill form correctly
  await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(const Key('password')), 'password123');
  await tester.pumpAndSettle();

  // Error messages gone
  expect(find.text('Email is required'), findsNothing);

  // Can submit
  await tester.tap(find.byKey(const Key('submit_btn')));
  await tester.pumpAndSettle();
});
```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Flutter E2E Tests

on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        device:
          - android

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Get dependencies
        run: flutter pub get

      - name: Run integration tests
        run: flutter test integration_test/ --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: integration-tests

  golden-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Get dependencies
        run: flutter pub get

      - name: Run golden tests
        run: flutter test test/goldens/

      - name: Upload golden diffs on failure
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: golden-diffs
          path: test/goldens/failures/
```

### Coverage Enforcement

```bash
#!/bin/bash

# Run tests with coverage
flutter test --coverage

# Extract coverage percentage
coverage=$(grep -oP '(?<=LH:)\d+' coverage/lcov.info | paste -sd+ - | bc)
total=$(grep -oP '(?<=LF:)\d+' coverage/lcov.info | paste -sd+ - | bc)
percent=$((coverage * 100 / total))

echo "Coverage: $percent%"

# Enforce minimum threshold
if [ $percent -lt 80 ]; then
  echo "Coverage below 80% threshold!"
  exit 1
fi
```

---

## Debugging Tips

### Enable Verbose Logging

```bash
flutter test --verbose integration_test/auth_test.dart
```

### Screenshot on Failure

```dart
testWidgets('user flow', (tester) async {
  try {
    await tester.pumpWidget(const MyApp());
    // ... test code
  } catch (e) {
    // Take screenshot on failure
    await tester.takeScreenshot('failure_screenshot');
    rethrow;
  }
});
```

### Use debugPrintBeginFrame

```dart
debugPrintBeginFrame = true; // Enable frame logging
debugPrintEndFrame = true;

testWidgets('performance test', (tester) async {
  await tester.pumpWidget(const MyApp());
  // ... check console output for frame times
});
```

### Mock Clock for Time-Based Tests

```dart
testWidgets('refreshes data after timeout', (tester) async {
  final clock = FakeClock();

  await tester.pumpWidget(MyApp(clock: clock));
  await tester.pumpAndSettle();

  // Advance clock by 5 minutes
  clock.elapse(const Duration(minutes: 5));
  await tester.pumpAndSettle();

  // Verify refresh was triggered
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

---

## Best Practices

✅ **DO:**
- Use descriptive test names
- Test complete user flows end-to-end
- Mock external dependencies
- Use test fixtures for reusable data
- Keep tests fast and isolated
- Capture screenshots for documentation
- Enforce coverage thresholds in CI/CD
- Test error states and edge cases

❌ **DON'T:**
- Test framework internals
- Depend on timing (use `pumpAndSettle`)
- Create tight coupling between tests
- Hardcode test data in test code
- Ignore flaky tests
- Test implementation details
- Use `wait` loops instead of `pump`

---

## Related Skills

- `flutter-patterns` — State management and widget patterns
- `dart-flutter-patterns` — Dart idioms and null safety
- `flutter-dart-code-review` — Code review checklist
- `e2e-testing` — Playwright web E2E patterns

## Related Tools

- `/flutter-test` — Run Flutter tests
- `/flutter-build` — Fix build errors
- `/flutter-review` — Code review
- `/tdd` — Test-driven development
