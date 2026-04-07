---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart/Flutter Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Dart, Flutter, and common ecosystem-specific content.

## Project Structure (Clean Architecture)

```
lib/
├── core/                   # Shared utilities, constants, theme, extensions
│   ├── constants/
│   ├── extensions/
│   ├── theme/
│   └── utils/
├── domain/                 # Pure Dart — no Flutter, no external packages
│   ├── entities/
│   ├── repositories/       # Abstract interfaces
│   └── usecases/
├── data/                   # Implements domain interfaces
│   ├── datasources/
│   ├── models/             # DTOs with fromJson/toJson
│   └── repositories/
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
├── presentation/           # Flutter widgets + state management
│   ├── pages/
│   ├── widgets/
│   └── providers/ (or blocs/ or viewmodels/)
├── l10n/                   # Localization (ARB files)
└── main.dart
```

- Domain must not import `package:flutter` or any data-layer package
- Data layer maps DTOs to domain entities at repository boundaries
- Presentation calls use cases, not repositories directly

## Repository Pattern

```dart
abstract interface class UserRepository {
  Future<User?> getById(String id);
  Future<List<User>> getAll();
  Stream<List<User>> watchAll();
  Future<void> save(User user);
  Future<void> delete(String id);
}

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._remote, this._local);

  final UserRemoteDataSource _remote;
  final UserLocalDataSource _local;

  @override
  Future<User?> getById(String id) async {
    final local = await _local.getById(id);
    if (local != null) return local;
    final remote = await _remote.getById(id);
    if (remote != null) await _local.save(remote);
    return remote;
  }

  @override
  Future<List<User>> getAll() async {
    final remote = await _remote.getAll();
    for (final user in remote) {
      await _local.save(user);
    }
    return remote;
  }

  @override
  Stream<List<User>> watchAll() => _local.watchAll();

  @override
  Future<void> save(User user) => _local.save(user);

  @override
  Future<void> delete(String id) async {
    await _remote.delete(id);
    await _local.delete(id);
  }
}
```

For projects using `Either` types, return `Either<Failure, T>` (via `dartz`/`fpdart`) or custom sealed result types from repository methods:

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

## Dependency Injection

Constructor injection is preferred. Use `get_it` + `injectable` or Riverpod providers at composition root:

```dart
// get_it registration (in a setup file)
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

  // ViewModels
  sl.registerFactory(() => UserListViewModel(sl<UserRepository>()));
}
```

## State Management: BLoC/Cubit

```dart
// Cubit — simple state transitions
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

// BLoC — event-driven (auth example with freezed)
sealed class AuthEvent {}
class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});
  final String email;
  final String password;
}
class LogoutRequested extends AuthEvent {}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.error(String message) = _Error;
}

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

// BLoC — event-driven (cart example without freezed)
@immutable
sealed class CartEvent {}
class CartItemAdded extends CartEvent { CartItemAdded(this.item); final Item item; }
class CartItemRemoved extends CartEvent { CartItemRemoved(this.id); final String id; }
class CartCleared extends CartEvent {}

@immutable
class CartState {
  const CartState({this.items = const []});
  final List<Item> items;
  CartState copyWith({List<Item>? items}) => CartState(items: items ?? this.items);
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>((event, emit) =>
        emit(state.copyWith(items: [...state.items, event.item])));
    on<CartItemRemoved>((event, emit) =>
        emit(state.copyWith(items: state.items.where((i) => i.id != event.id).toList())));
    on<CartCleared>((_, emit) => emit(const CartState()));
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

## State Management: Riverpod

```dart
// Simple provider (code-gen style)
@riverpod
Future<List<User>> users(Ref ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getAll();
}

// Notifier for mutable state (code-gen style)
@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  List<Item> build() => [];

  void add(Item item) => state = [...state, item];
  void remove(String id) => state = state.where((i) => i.id != id).toList();
  void clear() => state = [];
}

// Manual provider style
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(dioProvider));
});

// AsyncNotifier (manual style)
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

// ConsumerWidget
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartNotifierProvider);
    return ListView(
      children: items.map((item) => CartItemTile(item: item)).toList(),
    );
  }
}

// Consuming auth state
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

## ViewModel Pattern (ChangeNotifier / Provider)

```dart
class UserListViewModel extends ChangeNotifier {
  UserListViewModel(this._repository);

  final UserRepository _repository;

  AsyncState<List<User>> _state = const Loading();
  AsyncState<List<User>> get state => _state;

  Future<void> load() async {
    _state = const Loading();
    notifyListeners();
    try {
      final users = await _repository.getAll();
      _state = Success(users);
    } on Exception catch (e) {
      _state = Failure(e);
    }
    notifyListeners();
  }
}

// For simpler projects or teams preferring MVVM over BLoC:
enum ViewState { idle, busy, error }

class BaseModel with ChangeNotifier {
  ViewState _state = ViewState.idle;

  ViewState get state => _state;

  set state(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }
}

class LoginViewModel extends BaseModel {
  final AuthRepository _repository;

  LoginViewModel({required AuthRepository repository})
      : _repository = repository;

  String? errorMessage;

  Future<bool> login(String email, String password) async {
    state = ViewState.busy;
    try {
      await _repository.login(email, password);
      state = ViewState.idle;
      return true;
    } catch (e) {
      errorMessage = e.toString();
      state = ViewState.error;
      return false;
    }
  }
}
```

### Consuming ViewModel in Widgets

```dart
Consumer<LoginViewModel>(
  builder: (context, model, child) {
    if (model.state == ViewState.busy) {
      return const CircularProgressIndicator();
    }
    if (model.state == ViewState.error) {
      return ErrorBanner(message: model.errorMessage ?? 'Unknown error');
    }
    return LoginForm(onSubmit: model.login);
  },
)
```

### Provider Registration

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LoginViewModel(repository: sl())),
    ChangeNotifierProvider(create: (_) => FeedViewModel(repository: sl())),
    StreamProvider<InternetConnectionStatus>(
      create: (_) => InternetConnectionChecker().onStatusChange,
      initialData: InternetConnectionStatus.connected,
    ),
  ],
  child: const App(),
)
```

## UseCase Pattern

```dart
class GetUserUseCase {
  const GetUserUseCase(this._repository);
  final UserRepository _repository;

  Future<User?> call(String id) => _repository.getById(id);
}

class CreateUserUseCase {
  const CreateUserUseCase(this._repository, this._idGenerator);
  final UserRepository _repository;
  final IdGenerator _idGenerator; // injected — domain layer must not depend on uuid package directly

  Future<void> call(CreateUserInput input) async {
    // Validate, apply business rules, then persist
    final user = User(id: _idGenerator.generate(), name: input.name, email: input.email);
    await _repository.save(user);
  }
}
```

## Immutable State with freezed

```dart
@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default([]) List<User> users,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _UserState;
}

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

## Navigation (GoRouter)

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/users/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UserDetailPage(userId: id);
      },
    ),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (_, __, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/items/:id',
          builder: (_, state) => ItemDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
  ],
  // refreshListenable re-evaluates redirect whenever auth state changes
  refreshListenable: GoRouterRefreshStream(authCubit.stream),
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthCubit>().state is AuthAuthenticated;
    if (!isLoggedIn && !state.matchedLocation.startsWith('/login')) {
      return '/login';
    }
    return null;
  },
);
```

## Alternative Directory Structure — MVVM

For projects using MVVM + Provider instead of Clean Architecture + BLoC:

```
lib/
├── core/
│   ├── network/               # Auth interceptor, session manager
│   ├── services/              # Session management, DI setup
│   └── di/                    # Service locator (get_it)
├── models/                    # Data classes with fromJson/toJson
├── services/                  # Repositories (API calls via APIBase)
├── viewmodels/                # Business logic (extend BaseModel)
│   └── base_model.dart
├── views/
│   ├── screens/               # Feature-organized screens
│   └── widgets/common/        # App-wide reusable components
├── shared/
│   ├── constants/
│   │   ├── api_constants.dart     # Centralized API routes
│   │   ├── color_constants.dart   # AppColor palette
│   │   └── style_constants.dart   # AppTextStyle (pre-built TextStyles)
│   └── enums/
│       └── view_state.dart
├── utils/
│   ├── routing/
│   │   ├── routes.dart        # Named route strings
│   │   └── router.dart        # Route generation
│   ├── device/responsive.dart # Responsive scaling
│   └── extensions/            # String, SizedBox extensions
└── main.dart
```

## Centralized Networking — Dio APIBase

```dart
class APIBase {
  final Dio _dio;

  APIBase(this._dio);

  Future<Response> getRequest(
    String url, {
    bool isAuthorizationRequired = true,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: isAuthorizationRequired
              ? {'Authorization': 'Bearer ${await _getToken()}'}
              : null,
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> postRequest(
    String url, {
    dynamic body,
    bool isAuthorizationRequired = true,
  }) async {
    try {
      return await _dio.post(
        url,
        data: body,
        options: Options(
          headers: isAuthorizationRequired
              ? {'Authorization': 'Bearer ${await _getToken()}'}
              : null,
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
```

### Centralized API Routes

```dart
class APIRoutes {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  static const String loginUser = '${baseUrl}auth/login';
  static const String profileApi = '${baseUrl}user/profile';
  static const String feed = '${baseUrl}feed';
  // All endpoints defined here — no hardcoded URLs in repositories
}
```

## Responsive Scaling Extensions

For consistent responsive sizing across phones and tablets, use scaling extensions based on a design baseline (e.g., iPhone 14 Pro Max — 430x932):

```dart
extension ResponsiveExtension on num {
  /// Width-scaled — for horizontal padding, widths, margins
  double get w => this * (screenWidth / designWidth);

  /// Height-scaled — for vertical padding, heights
  double get h => this * (screenHeight / designHeight);

  /// Radius-scaled — for BorderRadius, icon sizes, CircleAvatar
  double get r => this * _radiusScale;

  /// Font-size scaled — with max cap to prevent oversizing
  double get sp => this * min(_fontScale, 1.3);
}
```

### Usage

```dart
// GOOD — responsive dimensions
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h));
BorderRadius.circular(12.r);
Text('Hello', style: TextStyle(fontSize: 14.sp));
SizedBox(height: 20.h, width: 100.w);

// BAD — raw values
Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8));
```

Packages like `flutter_screenutil` provide this pattern out of the box.

## Centralized Design Tokens

### Color Constants

```dart
class AppColor {
  static const Color primary = Color(0xFF664E3E);
  static const Color background = Color(0xFFF4F4F4);
  static const Color accent = Color(0xFFD8F2E0);
  static const Color error = Color(0xFFE53935);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  // All project colors defined here — never use raw hex in widgets
}
```

### Text Style Constants

```dart
class AppTextStyle {
  static TextStyle heading = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColor.primary,
  );

  static TextStyle body = TextStyle(
    fontFamily: 'Avenir',
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: AppColor.textPrimary,
  );

  static TextStyle caption = TextStyle(
    fontFamily: 'Avenir',
    fontSize: 12.sp,
    fontWeight: FontWeight.w300,
    color: AppColor.textSecondary,
  );
  // Pre-built styles for consistency — never create inline TextStyle in widgets
}
```

## References

See skill: `flutter-patterns` for detailed widget composition, performance, and theming patterns.
See skill: `flutter-testing` for comprehensive testing patterns.
See skill: `flutter-dart-code-review` for the comprehensive review checklist.
See skill: `compose-multiplatform-patterns` for Kotlin Multiplatform/Flutter interop patterns.
