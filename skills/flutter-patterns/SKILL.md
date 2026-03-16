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
