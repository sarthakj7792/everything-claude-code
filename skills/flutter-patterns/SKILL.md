---
name: flutter-patterns
description: Flutter architecture patterns, widget composition, state management (BLoC, Provider, Riverpod), navigation with GoRouter, theming, responsive layouts, performance optimization, and platform channels.
---

# Flutter Patterns

Comprehensive Flutter patterns for building production-grade cross-platform applications. Covers widget composition, state management, navigation, theming, performance, and platform integration.

## When to Activate

- Building Flutter widgets and managing state
- Designing navigation flows with GoRouter
- Structuring features with clean architecture
- Optimizing widget rebuild performance
- Working with platform channels or plugins
- Building responsive and adaptive layouts

## Widget Composition

### StatelessWidget — Pure UI

Use when the widget depends only on its constructor arguments:

```dart
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});
  final Item item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        title: Text(item.name, style: theme.textTheme.titleMedium),
        subtitle: Text(item.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
```

### StatefulWidget — Local Mutable State

Use only when you need local UI state (animations, form controllers, scroll position):

```dart
class SearchBar extends StatefulWidget {
  const SearchBar({super.key, required this.onSearch});
  final ValueChanged<String> onSearch;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController _controller;
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _debouncer = Debouncer(duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        hintText: 'Search...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) => _debouncer.run(() => widget.onSearch(value)),
    );
  }
}
```

### Extract Subwidgets to Limit Rebuilds

Break large widgets into small, focused widgets. When state changes, only the subwidget reading that state rebuilds:

```dart
// GOOD — each section rebuilds independently
class OrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        OrderHeader(),    // Rebuilds only when header data changes
        OrderItemList(),  // Rebuilds only when items change
        OrderTotal(),     // Rebuilds only when total changes
      ],
    );
  }
}
```

## State Management Decision Guide

| Scenario | Recommended |
|----------|------------|
| Local UI state (toggle, animation) | `StatefulWidget` or `ValueNotifier` |
| Feature-level business logic | BLoC / Cubit |
| App-wide reactive state | Riverpod `AsyncNotifierProvider` |
| Simple shared state | `ChangeNotifier` + `Provider` |
| Form state | `TextEditingController` + local state |

## Theming

### Define a Consistent Theme

```dart
class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
```

### Access Theme in Widgets

```dart
// GOOD — use Theme.of and extension
final theme = Theme.of(context);
final colors = theme.colorScheme;
final textTheme = theme.textTheme;

Text('Title', style: textTheme.headlineMedium?.copyWith(color: colors.primary));
```

## Responsive Layouts

### Responsive Scaling Extensions

For pixel-perfect responsive design across device sizes, use scaling extensions based on a design baseline (e.g., iPhone 14 Pro Max — 430x932). Packages like `flutter_screenutil` provide this pattern, or implement custom extensions:

```dart
// Initialize once in the root widget
ScreenUtil.init(context, designSize: const Size(430, 932));

// Usage — all dimensions via extensions
Padding(
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  child: Column(
    children: [
      CircleAvatar(radius: 24.r),
      SizedBox(height: 12.h),
      Text('Hello', style: TextStyle(fontSize: 16.sp)),
      SizedBox(
        width: double.infinity,
        height: 44.h,
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Continue'),
        ),
      ),
    ],
  ),
);
```

| Extension | Purpose | Use For |
|-----------|---------|---------|
| `.w` | Width-scaled | Horizontal padding, widths, margins |
| `.h` | Height-scaled | Vertical padding, heights, SizedBox |
| `.r` | Radius-scaled | BorderRadius, icon sizes, CircleAvatar |
| `.sp` | Font-scaled (capped) | All text font sizes |

**Tablet dampening**: Use sqrt-based scaling on tablets to prevent UI from blowing up on large screens.

**Rule**: All dimensions must use these extensions in production code — raw `double` values are forbidden.

### Centralized Design Tokens

Define all visual constants centrally — never use raw hex values, inline TextStyles, or magic numbers in widgets:

```dart
// AppColor — all project colors
class AppColor {
  static const Color primary = Color(0xFF664E3E);
  static const Color background = Color(0xFFF4F4F4);
  static const Color accent = Color(0xFFD8F2E0);
  static const Color error = Color(0xFFE53935);
}

// AppTextStyle — pre-built text styles with responsive sizing
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
  );
}
```

Use `AppColor.primary` and `AppTextStyle.heading` in widgets — this ensures consistency and makes design changes a single-file edit.

### LayoutBuilder for Adaptive UI

```dart
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return WideLayout(child: child);
        } else if (constraints.maxWidth >= 600) {
          return MediumLayout(child: child);
        } else {
          return NarrowLayout(child: child);
        }
      },
    );
  }
}
```

### MediaQuery for Device Info

```dart
final size = MediaQuery.sizeOf(context);        // Preferred — only rebuilds on size change
final padding = MediaQuery.paddingOf(context);   // Safe area insets
final textScale = MediaQuery.textScalerOf(context);
```

Use `MediaQuery.sizeOf(context)` instead of `MediaQuery.of(context).size` — it scopes rebuild to size changes only.

## Performance

### const Constructors

Use `const` everywhere possible to avoid unnecessary rebuilds:

```dart
// GOOD — compile-time constant, never rebuilds
const SizedBox(height: 16);
const Divider();
const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
```

### RepaintBoundary

Isolate expensive painting from the rest of the tree:

```dart
RepaintBoundary(
  child: CustomPaint(
    painter: ChartPainter(data: chartData),
  ),
)
```

### ListView.builder for Large Lists

Never use `ListView(children: [...])` for dynamic or large lists:

```dart
// GOOD — lazily builds only visible items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(item: items[index]),
)
```

### Keys for Stateful Widgets in Lists

```dart
// GOOD — preserves state during reorder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(
    key: ValueKey(items[index].id), // Stable key
    item: items[index],
  ),
)
```

### Image Caching

Use `cached_network_image` for network images:

```dart
CachedNetworkImage(
  imageUrl: item.imageUrl,
  placeholder: (_, __) => const Shimmer(),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
)
```

## Platform Channels

### Method Channel

```dart
// Dart side
class NativeBridge {
  static const _channel = MethodChannel('com.app/native');

  Future<String> getPlatformVersion() async {
    final version = await _channel.invokeMethod<String>('getPlatformVersion');
    return version ?? 'Unknown';
  }
}

// Kotlin side (Android)
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.app/native")
            .setMethodCallHandler { call, result ->
                if (call.method == "getPlatformVersion") {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                } else {
                    result.notImplemented()
                }
            }
    }
}
```

## MVVM + Provider Pattern

An alternative to BLoC for teams preferring simpler state management:

### BaseModel with ViewState

```dart
enum ViewState { idle, busy, error }

class BaseModel with ChangeNotifier {
  ViewState _state = ViewState.idle;
  ViewState get state => _state;
  set state(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }
}
```

### ViewModel Pattern

```dart
class FeedViewModel extends BaseModel {
  final FeedRepository _repository;
  List<FeedItem> items = [];
  String? errorMessage;

  FeedViewModel({required FeedRepository repository})
      : _repository = repository;

  Future<void> loadFeed() async {
    state = ViewState.busy;
    try {
      items = await _repository.getFeed();
      state = ViewState.idle;
    } catch (e) {
      errorMessage = e.toString();
      state = ViewState.error;
    }
  }
}
```

### Widget Binding

```dart
Consumer<FeedViewModel>(
  builder: (context, model, child) => switch (model.state) {
    ViewState.busy => const Center(child: CircularProgressIndicator()),
    ViewState.error => ErrorWidget(message: model.errorMessage),
    ViewState.idle => ListView.builder(
      itemCount: model.items.length,
      itemBuilder: (_, i) => FeedCard(item: model.items[i]),
    ),
  },
)
```

## Shared Widget Library

Build a set of reusable widgets in `lib/views/widgets/common/` (or equivalent) to enforce UI consistency:

| Widget | Purpose | Key Props |
|--------|---------|-----------|
| `PrimaryButton` | Standard action button | `label`, `onPressed`, `isLoading`, `width` |
| `CustomTextField` | Styled text input | `hint`, `controller`, `validator` |
| `UserAvatar` | Profile image with fallback | `imageUrl`, `radius`, `initials` |
| `TagChip` | Selectable tag | `label`, `isSelected`, `onTap` |
| `SectionHeader` | Section title with optional action | `title`, `actionLabel`, `onAction` |
| `AppBottomSheet` | Reusable modal sheet | `child`, `title` |

**Rule**: Always check `common/` before building a new widget. Import and extend existing components first.

## Anti-Patterns to Avoid

- Using `setState` for complex business logic — use BLoC/Riverpod instead
- Putting async work in `build()` — use `FutureBuilder`, `BlocBuilder`, or load in `initState`
- Deep widget nesting (>10 levels) — extract subwidgets
- Using `MediaQuery.of(context)` when only size is needed — use `MediaQuery.sizeOf(context)`
- Mutable global state or singletons without DI — use `get_it` or Riverpod
- Using `GlobalKey` for state access — prefer callbacks or state management solutions

## References

See rule: `dart/patterns` for architectural patterns (BLoC, Riverpod, Repository).
See rule: `dart/testing` for testing strategies.
See skill: `flutter-testing` for comprehensive TDD workflow.
