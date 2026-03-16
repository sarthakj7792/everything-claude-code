---
paths:
  - "**/*.dart"
---
# Dart Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Dart and Flutter-specific content.

## Formatting

- **dart format** for all Dart files — enforce via CI and pre-commit hooks
- Use `analysis_options.yaml` with `flutter_lints` or `very_good_analysis` for strict lint rules
- Line length: 80 characters (Dart default)

## Immutability

- Prefer `final` over `var` — default to `final` and only use `var` when reassignment is required
- Use `const` constructors wherever possible for compile-time constants and widget trees
- Use `freezed` or hand-written `copyWith` for immutable data classes
- Use `UnmodifiableListView` / `List.unmodifiable()` for public collection APIs

```dart
// BAD
var name = 'Alice';
var items = [1, 2, 3];

// GOOD
final name = 'Alice';
final items = List.unmodifiable([1, 2, 3]);

// GOOD — const widget tree
const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
);
```

## Naming

Follow Effective Dart conventions:
- `lowerCamelCase` for variables, functions, parameters, and named constants
- `UpperCamelCase` for classes, enums, type aliases, and extensions
- `lowercase_with_underscores` for file names, library names, and package names
- `_leadingUnderscore` for private members (library-private in Dart)
- Prefix boolean getters/properties with `is`, `has`, `can`, `should`

## Null Safety

- Never use `!` (bang operator) unless you can guarantee non-null — prefer `?.`, `??`, or null checks
- Use `late` only when initialization is guaranteed before access (e.g., `late final` in `initState`)
- Return nullable types from functions that can legitimately have no result
- Use `required` keyword for mandatory named parameters

```dart
// BAD — bang operator
final name = user!.name;

// GOOD — null-aware operators
final name = user?.name ?? 'Unknown';

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

## Enums and Sealed Classes

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

Use `sealed class` (Dart 3+) for closed type hierarchies with exhaustive pattern matching:

```dart
sealed class UiState<T> {}
class Loading<T> extends UiState<T> {}
class Success<T> extends UiState<T> {
  const Success(this.data);
  final T data;
}
class Failure<T> extends UiState<T> {
  const Failure(this.message);
  final String message;
}

// Exhaustive switch
String describe(UiState<String> state) => switch (state) {
  Loading() => 'Loading...',
  Success(:final data) => 'Got: $data',
  Failure(:final message) => 'Error: $message',
};
```

## Error Handling

- Use custom exception classes for domain errors
- Use `Result` types (via `fpdart`, `dartz`, or custom sealed classes) for expected failures
- Reserve `try-catch` for truly unexpected errors
- Never catch `Error` subtypes (e.g., `StackOverflowError`, `OutOfMemoryError`)

```dart
// BAD — using exceptions for control flow
try {
  final user = await repository.getUser(id);
} on NotFoundException {
  return null;
}

// GOOD — nullable return
final user = await repository.findUser(id); // returns User?
```

## Extension Methods

Use extensions for utility operations, but keep them discoverable:
- Place in a file named after the receiver type (`string_extensions.dart`, `context_extensions.dart`)
- Keep scope limited — don't add extensions to `Object` or overly generic types
- Prefer named extensions over anonymous ones for discoverability
