/// Flutter E2E Integration Test Example
///
/// This file demonstrates best practices for writing integration tests
/// for a complete user flow in a Flutter app.
///
/// Run with: flutter test integration_test/e2e_example_test.dart
///
/// Prerequisites:
/// - Device/emulator running
/// - pubspec.yaml contains:
///   - integration_test: ^0.0.1
///   - flutter_test: (from flutter SDK)

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Example 1: E-Commerce Cart Flow
  ///
  /// Tests a complete user journey:
  /// 1. Launch app
  /// 2. Browse products
  /// 3. Add items to cart
  /// 4. Proceed to checkout
  /// 5. Complete purchase
  group('E-Commerce App - Complete Purchase Flow', () {
    testWidgets(
      'User can add items and complete purchase',
      (WidgetTester tester) async {
        // Step 1: Launch the app
        await tester.pumpWidget(const MyECommerceApp());
        await tester.pumpAndSettle();

        // Verify home page loaded
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.text('Products'), findsOneWidget);

        // Step 2: Browse to product details
        // Tap on first product
        await tester.tap(find.byKey(const Key('product_0')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify product details page opened
        expect(find.byType(ProductDetailsPage), findsOneWidget);
        expect(find.text('Add to Cart'), findsOneWidget);

        // Step 3: Add item to cart
        await tester.tap(find.byKey(const Key('add_to_cart_btn')));
        await tester.pumpAndSettle();

        // Verify success message
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Added to cart'), findsOneWidget);

        // Step 4: Go to cart
        await tester.tap(find.byKey(const Key('cart_button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify cart page
        expect(find.byType(CartPage), findsOneWidget);
        expect(find.text('Proceed to Checkout'), findsOneWidget);

        // Take screenshot for documentation
        await tester.takeScreenshot('cart_page');

        // Step 5: Proceed to checkout
        await tester.tap(find.byKey(const Key('checkout_btn')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify checkout page
        expect(find.byType(CheckoutPage), findsOneWidget);
        expect(find.text('Shipping Address'), findsOneWidget);

        // Step 6: Fill shipping address
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

        // Step 7: Select shipping method
        await tester.tap(find.byKey(const Key('standard_shipping')));
        await tester.pumpAndSettle();

        // Step 8: Proceed to payment
        await tester.tap(find.byKey(const Key('continue_btn')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify payment page
        expect(find.byType(PaymentPage), findsOneWidget);

        // Step 9: Fill payment info
        await tester.enterText(
          find.byKey(const Key('card_number_field')),
          '4111111111111111',
        );
        await tester.enterText(
          find.byKey(const Key('expiry_field')),
          '12/25',
        );
        await tester.enterText(
          find.byKey(const Key('cvv_field')),
          '123',
        );

        await tester.pumpAndSettle();

        // Step 10: Complete purchase
        await tester.tap(find.byKey(const Key('place_order_btn')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify order confirmation
        expect(find.byType(OrderConfirmationPage), findsOneWidget);
        expect(find.text('Order Confirmed'), findsOneWidget);
        expect(find.byType(Finder), findsWidgets);

        // Take final screenshot
        await tester.takeScreenshot('order_confirmation');
      },
    );
  });

  /// Example 2: Authentication Flow
  ///
  /// Tests user login and session management
  group('Authentication Flow', () {
    testWidgets(
      'New user can register and log in',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MyAuthApp());
        await tester.pumpAndSettle();

        // Verify login page shown
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.text('Sign Up'), findsOneWidget);

        // Navigate to registration
        await tester.tap(find.byType(SignUpButton));
        await tester.pumpAndSettle();

        // Verify sign up page
        expect(find.byType(SignUpPage), findsOneWidget);

        // Fill registration form
        await tester.enterText(
          find.byKey(const Key('signup_name')),
          'John Doe',
        );
        await tester.enterText(
          find.byKey(const Key('signup_email')),
          'john@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('signup_password')),
          'SecurePassword123!',
        );
        await tester.enterText(
          find.byKey(const Key('signup_confirm_password')),
          'SecurePassword123!',
        );

        // Accept terms
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.byKey(const Key('signup_button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify email confirmation screen
        expect(find.text('Verify your email'), findsOneWidget);

        // Simulate email verification (in real app, user would click link)
        // For testing, we might have a test API endpoint
        await tester.tap(find.byKey(const Key('verify_button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify redirected to home
        expect(find.byType(HomePage), findsOneWidget);

        // Verify user is logged in
        expect(find.text('Welcome, John Doe'), findsOneWidget);
      },
    );

    testWidgets(
      'User can log out',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MyAuthApp());
        await tester.pumpAndSettle();

        // Assume user is already logged in
        // (handled by test setup/fixtures)

        // Open user menu
        await tester.tap(find.byKey(const Key('user_menu_button')));
        await tester.pumpAndSettle();

        // Tap logout
        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify back at login
        expect(find.byType(LoginPage), findsOneWidget);
      },
    );
  });

  /// Example 3: List and Search Flow
  ///
  /// Tests filtering and searching functionality
  group('Product Search and Filter', () {
    testWidgets(
      'User can search products and filter results',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MyECommerceApp());
        await tester.pumpAndSettle();

        // Verify on products page
        expect(find.byType(ProductsListPage), findsOneWidget);

        // Get initial product count
        int initialCount = find.byType(ProductTile).evaluate().length;
        expect(initialCount, greaterThan(0));

        // Step 1: Search for products
        await tester.tap(find.byKey(const Key('search_field')));
        await tester.enterText(
          find.byKey(const Key('search_field')),
          'laptop',
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify filtered results
        int searchCount = find.byType(ProductTile).evaluate().length;
        expect(searchCount, lessThan(initialCount));
        expect(find.text('Laptop'), findsOneWidget);

        // Step 2: Apply price filter
        await tester.tap(find.byKey(const Key('filter_button')));
        await tester.pumpAndSettle();

        // Set price range
        await tester.tap(find.byKey(const Key('price_range_slider')));
        // (Simulated slider interaction)

        await tester.tap(find.byKey(const Key('apply_filters_button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify further filtered
        int filteredCount = find.byType(ProductTile).evaluate().length;
        expect(filteredCount, lessThanOrEqualTo(searchCount));

        // Step 3: Clear filters
        await tester.tap(find.byKey(const Key('clear_filters_button')));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify back to original count
        int clearedCount = find.byType(ProductTile).evaluate().length;
        expect(clearedCount, equals(initialCount));
      },
    );
  });

  /// Example 4: Offline Behavior
  ///
  /// Tests app behavior when network is unavailable
  group('Offline Behavior', () {
    testWidgets(
      'App shows cached data when offline',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MyECommerceApp());
        await tester.pumpAndSettle();

        // Load products (should cache)
        expect(find.byType(ProductTile), findsWidgets);
        List<String> cachedTitles = [];
        for (int i = 0; i < 5; i++) {
          final title = (find.byType(ProductTile).at(i)
              .evaluate()
              .single
              .widget as ProductTile)
              .product
              .name;
          cachedTitles.add(title);
        }

        // Simulate going offline
        // (This would require some test helper or mock)
        // await setNetworkAvailable(false);

        // Restart app while offline
        // (Integration test framework would handle this)

        // Verify cached data still visible
        for (final title in cachedTitles) {
          expect(find.text(title), findsOneWidget);
        }

        // Verify offline indicator shown
        expect(find.byType(OfflineIndicator), findsOneWidget);
      },
    );
  });

  /// Example 5: Performance and Error Handling
  ///
  /// Tests error states and recovery
  group('Error Handling and Recovery', () {
    testWidgets(
      'User sees error when product fetch fails',
      (WidgetTester tester) async {
        // This would need to mock/stub the API to fail

        await tester.pumpWidget(const MyECommerceApp());
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify error state displayed
        expect(find.byType(ErrorWidget), findsOneWidget);
        expect(find.text('Failed to load products'), findsOneWidget);

        // Verify retry button present
        expect(find.byKey(const Key('retry_button')), findsOneWidget);

        // Tap retry
        await tester.tap(find.byKey(const Key('retry_button')));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify recovered to normal state
        expect(find.byType(ProductTile), findsWidgets);
      },
    );
  });
}

// ============================================================================
// Mock Classes for Testing
// ============================================================================

class MyECommerceApp extends StatelessWidget {
  const MyECommerceApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class MyAuthApp extends StatelessWidget {
  const MyAuthApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

// Placeholder widgets for examples
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: const SizedBox(),
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Add to Cart'),
          ElevatedButton(
            key: const Key('add_to_cart_btn'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart')),
              );
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: const Text('Proceed to Checkout'),
      floatingActionButton: FloatingActionButton(
        key: const Key('checkout_btn'),
        onPressed: () {},
        child: const Icon(Icons.checkout),
      ),
    );
  }
}

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            Text('Shipping Address'),
            TextField(key: Key('address_field')),
            TextField(key: Key('city_field')),
            TextField(key: Key('state_field')),
            TextField(key: Key('zip_field')),
          ],
        ),
      ),
    );
  }
}

class PaymentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            TextField(key: Key('card_number_field')),
            TextField(key: Key('expiry_field')),
            TextField(key: Key('cvv_field')),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Text('Order Confirmed'),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: const SizedBox(),
    );
  }
}

class SignUpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class ProductsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(key: const Key('search_field')),
          ElevatedButton(
            key: const Key('filter_button'),
            onPressed: () {},
            child: const Text('Filter'),
          ),
        ],
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final ProductModel product;

  const ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class ProductModel {
  final String name;
  ProductModel({required this.name});
}

class OfflineIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class ErrorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
