---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Dart/Flutter Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Dart and Flutter-specific content.

## Formatting

- **dart format** for all `.dart` files — enforced in CI (`dart format --set-exit-if-changed .`)
- Use `analysis_options.yaml` with `flutter_lints` or `very_good_analysis` for strict lint rules
- Line length: 80 characters (dart format default)
- Trailing commas on multi-line argument/parameter lists to improve diffs and formatting

## Immutability

- Prefer `final` for local variables and `const` for compile-time constants
- Use `const` constructors wherever all fields are `final`
- Use `freezed` or hand-written `copyWith` for immutable data classes
- Return unmodifiable collections from public APIs (`List.unmodifiable`, `Map.unmodifiable`)
- Use `copyWith()` for state mutations in immutable state classes

```dart
// BAD
var count = 0;
List<String> items = ['a', 'b'];

// GOOD
final count = 0;
const items = ['a', 'b'];

// GOOD — const widget tree
const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
);
```

## Naming

Follow Dart conventions:
- `camelCase` for variables, parameters, and named constructors
- `PascalCase` for classes, enums, typedefs, and extensions
- `snake_case` for file names and library names
- `SCREAMING_SNAKE_CASE` for constants declared with `const` at top level
- Prefix private members with `_`
- Prefix boolean getters/properties with `is`, `has`, `can`, `should`
- Extension names describe the type they extend: `StringExtensions`, not `MyHelpers`

## Null Safety

- Avoid `!` (bang operator) — prefer `?.`, `??`, `if (x != null)`, or Dart 3 pattern matching; reserve `!` only where a null value is a programming error and crashing is the right behaviour
- Avoid `late` unless initialization is guaranteed before first use (prefer nullable or constructor init)
- Use `required` for constructor parameters that must always be provided
- Return nullable types from functions that can legitimately have no result

```dart
// BAD — crashes at runtime if user is null
final name = user!.name;

// GOOD — null-aware operators
final name = user?.name ?? 'Unknown';

// GOOD — Dart 3 pattern matching (exhaustive, compiler-checked)
final name = switch (user) {
  User(:final name) => name,
  null => 'Unknown',
};

// GOOD — early-return null guard
String getUserName(User? user) {
  if (user == null) return 'Unknown';
  return user.name; // promoted to non-null after the guard
}

// GOOD — null check with flow analysis
if (user != null) {
  print(user.name); // promoted to non-null
}
```

## Type Annotations

- Omit type annotations when the type is obvious from the right-hand side
- Always annotate function return types and parameter types in public APIs
- Use `dynamic` only when interfacing with untyped data (e.g., JSON); prefer `Object?` otherwise

```dart
// GOOD — type is obvious
final controller = TextEditingController();
final items = <String>[];

// GOOD — explicit return type on public API
List<Item> getFilteredItems(String query) { ... }
```

## Sealed Types and Pattern Matching (Dart 3+)

Use sealed classes to model closed state hierarchies:

```dart
sealed class AsyncState<T> {
  const AsyncState();
}

final class Loading<T> extends AsyncState<T> {
  const Loading();
}

final class Success<T> extends AsyncState<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends AsyncState<T> {
  const Failure(this.error);
  final Object error;
}
```

Always use exhaustive `switch` with sealed types — no default/wildcard:

```dart
// BAD
if (state is Loading) { ... }

// GOOD
return switch (state) {
  Loading() => const CircularProgressIndicator(),
  Success(:final data) => DataWidget(data),
  Failure(:final error) => ErrorWidget(error.toString()),
};
```

Use enhanced enums for closed value sets:

```dart
enum OrderStatus {
  pending('Pending'),
  processing('Processing'),
  completed('Completed');

  const OrderStatus(this.label);
  final String label;
}
```

## Error Handling

- Use custom exception classes for domain errors
- Specify exception types in `on` clauses — never use bare `catch (e)`
- Never catch `Error` subtypes — they indicate programming bugs
- Use `Result`-style types (via `fpdart`, `dartz`, or custom sealed classes) for recoverable/expected failures
- Reserve `try-catch` for truly unexpected errors
- Avoid using exceptions for control flow

```dart
// BAD
try {
  await fetchUser();
} catch (e) {
  log(e.toString());
}

// GOOD
try {
  await fetchUser();
} on NetworkException catch (e) {
  log('Network error: ${e.message}');
} on NotFoundException {
  handleNotFound();
}

// GOOD — nullable return instead of exception for control flow
final user = await repository.findUser(id); // returns User?
```

## Responsive Sizing

When using responsive scaling (e.g., `flutter_screenutil` or custom extensions):

- Use `.w` for horizontal dimensions, `.h` for vertical, `.r` for radius/icon sizes, `.sp` for font sizes
- Never use raw `double` values for dimensions in production widgets
- Initialize the responsive system once in the root widget before use
- Cap font scaling (e.g., max 1.3x) to prevent oversized text on tablets
- Use sqrt-dampened scaling for tablets to prevent UI blowup

```dart
// BAD — raw values
Padding(padding: EdgeInsets.all(16));
Text('Hello', style: TextStyle(fontSize: 14));

// GOOD — responsive extensions
Padding(padding: EdgeInsets.all(16.w));
Text('Hello', style: TextStyle(fontSize: 14.sp));
```

## Async / Futures

- Always `await` Futures or explicitly call `unawaited()` to signal intentional fire-and-forget
- Never mark a function `async` if it never `await`s anything
- Use `Future.wait` / `Future.any` for concurrent operations
- Check `context.mounted` before using `BuildContext` after any `await` (Flutter 3.7+)

```dart
// BAD — ignoring Future
fetchData(); // fire-and-forget without marking intent

// GOOD
unawaited(fetchData()); // explicit fire-and-forget
await fetchData();      // or properly awaited
```

## Imports

- Use `package:` imports throughout — never relative imports (`../`) for cross-feature or cross-layer code
- Order: `dart:` → external `package:` → internal `package:` (same package)
- No unused imports — `dart analyze` enforces this with `unused_import`

## Extension Methods

Use extensions for utility operations, but keep them discoverable:
- Place in a file named after the receiver type (`string_extensions.dart`, `context_extensions.dart`)
- Keep scope limited — don't add extensions to `Object` or overly generic types
- Prefer named extensions over anonymous ones for discoverability

## Code Generation

- Generated files (`.g.dart`, `.freezed.dart`, `.gr.dart`) must be committed or gitignored consistently — pick one strategy per project
- Never manually edit generated files
- Keep generator annotations (`@JsonSerializable`, `@freezed`, `@riverpod`, etc.) on the canonical source file only
