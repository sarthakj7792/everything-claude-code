---
paths:
  - "**/*.dart"
---
# Dart / Flutter Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Dart and Flutter-specific content.

## Project Structure (Clean Architecture)

```
lib/
├── core/                   # Shared utilities, constants, theme, extensions
│   ├── constants/
│   ├── extensions/
│   ├── theme/
│   └── utils/
├── features/               # Feature-first organization
│   └── auth/
│       ├── data/           # Repositories, data sources, models (DTOs)
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/         # Entities, repository interfaces, use cases
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/   # Widgets, pages, BLoCs/controllers
│           ├── bloc/
│           ├── pages/
│           └── widgets/
├── l10n/                   # Localization (ARB files)
└── main.dart
```

## Dependency Injection

Use `get_it` + `injectable` or manual service locator:

```dart
// Manual service locator with get_it
final sl = GetIt.instance;

void setupDependencies() {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerFactory(() => LoginUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(loginUseCase: sl()));
}
```

## State Management — BLoC / Cubit

### Cubit (simple state)

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```

### BLoC (event-driven state)

```dart
// Events
sealed class AuthEvent {}
class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});
  final String email;
  final String password;
}
class LogoutRequested extends AuthEvent {}

// State
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.error(String message) = _Error;
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase,
        super(const AuthState.initial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  final LoginUseCase _loginUseCase;

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await _loginUseCase(event.email, event.password);
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.initial());
  }
}
```

### Consuming BLoC in Widgets

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) => switch (state) {
    AuthState.initial() => const LoginForm(),
    AuthState.loading() => const CircularProgressIndicator(),
    AuthState.authenticated(:final user) => HomeScreen(user: user),
    AuthState.error(:final message) => ErrorBanner(message: message),
  },
)
```

## State Management — Riverpod

```dart
// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(dioProvider));
});

// AsyncNotifier
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }
}

// Consuming in widget
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return authState.when(
      data: (user) => user != null ? const HomeScreen() : const LoginForm(),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorBanner(message: e.toString()),
    );
  }
}
```

## Repository Pattern

- Abstract interface in `domain/repositories/`
- Concrete implementation in `data/repositories/`
- Return `Either<Failure, T>` (via `dartz`/`fpdart`) or custom sealed result types

```dart
// Domain — abstract contract
abstract class ItemRepository {
  Future<Either<Failure, List<Item>>> getAll();
  Future<Either<Failure, Item>> getById(String id);
  Stream<List<Item>> watchAll();
}

// Data — implementation
class ItemRepositoryImpl implements ItemRepository {
  const ItemRepositoryImpl(this._remoteDataSource, this._localDataSource);
  final ItemRemoteDataSource _remoteDataSource;
  final ItemLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, List<Item>>> getAll() async {
    try {
      final models = await _remoteDataSource.fetchItems();
      await _localDataSource.cacheItems(models);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

## Navigation — GoRouter

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).valueOrNull != null;
      if (!isLoggedIn && !state.matchedLocation.startsWith('/login')) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/items/:id',
            builder: (_, state) => ItemDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
});
```

## Data Models with Freezed

```dart
@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String name,
    required String description,
    @Default(false) bool isCompleted,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
}
```

## References

See skill: `flutter-patterns` for detailed widget composition, performance, and theming patterns.
See skill: `flutter-testing` for comprehensive testing patterns.
