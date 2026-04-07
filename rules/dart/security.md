---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/AndroidManifest.xml"
  - "**/Info.plist"
---
# Dart/Flutter Security

> This file extends [common/security.md](../common/security.md) with Dart, Flutter, and mobile-specific content.

## Secrets Management

- Never hardcode API keys, tokens, or credentials in Dart source
- Use `--dart-define` or `--dart-define-from-file` for compile-time config (values are not truly secret — use a backend proxy for server-side secrets)
- Use `flutter_dotenv` or equivalent, with `.env` files listed in `.gitignore`
- Store runtime secrets in platform-secure storage: `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android)

```dart
// BAD
const apiKey = 'sk-abc123...';

// GOOD — compile-time config (not secret, just configurable)
const apiKey = String.fromEnvironment('API_KEY');

// GOOD — runtime secret from secure storage
final token = await secureStorage.read(key: 'auth_token');
```

## Network Security

- Enforce HTTPS — no `http://` calls in production
- Configure Android `network_security_config.xml` to block cleartext traffic
- Set `NSAppTransportSecurity` in `Info.plist` to disallow arbitrary loads
- Pin certificates for sensitive endpoints using `dio` interceptors or `http_certificate_pinning`
- Set request timeouts on all HTTP clients — never leave defaults
- Validate and sanitize all server responses before use

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
</network-security-config>
```

```dart
// Dio with timeout and HTTPS enforcement
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 15),
));
```

## Input Validation

- Validate and sanitize all user input before sending to API or storage
- Never pass unsanitized input to SQL queries — use parameterized queries (sqflite, drift)
- Sanitize deep link URLs before navigation — validate scheme, host, and path parameters
- Sanitize file paths from user input to prevent path traversal
- Validate and sanitize data before rendering in WebViews
- Use `Uri.tryParse` and validate before navigating

```dart
// BAD — SQL injection
await db.rawQuery("SELECT * FROM users WHERE email = '$userInput'");

// GOOD — parameterized
await db.query('users', where: 'email = ?', whereArgs: [userInput]);

// BAD — unvalidated deep link
final uri = Uri.parse(incomingLink);
context.go(uri.path); // could navigate to any route

// GOOD — validated deep link
final uri = Uri.tryParse(incomingLink);
if (uri != null && uri.host == 'myapp.com' && _allowedPaths.contains(uri.path)) {
  context.go(uri.path);
}
```

## Data Protection

- Store tokens, PII, and credentials only in `flutter_secure_storage`
- Never write sensitive data to `SharedPreferences` or local files in plaintext
- Encrypt sensitive local data at rest using `hive` with encryption or `sqflite_sqlcipher`
- Clear auth state on logout: tokens, cached user data, cookies
- Use biometric authentication (`local_auth`) for sensitive operations
- Avoid logging sensitive data — no `print(token)` or `debugPrint(password)`
- Use `@JsonKey(includeToJson: false)` to prevent sensitive fields from being serialized

```dart
// GOOD — secure storage for tokens
final storage = FlutterSecureStorage();
await storage.write(key: 'token', value: authToken);
final token = await storage.read(key: 'token');

// GOOD — clear on logout
await storage.deleteAll();
```

## Authentication

- Store tokens in `flutter_secure_storage`, never in `SharedPreferences`
- Implement token refresh with proper 401/403 handling via Dio interceptors
- Clear all auth state on logout (tokens, cached user data, cookies)
- Use biometric authentication (`local_auth`) for sensitive operations

```dart
// Dio interceptor for token refresh
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final newToken = await refreshToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      }
    }
    handler.next(err);
  }
}
```

## Android-Specific

- Declare only required permissions in `AndroidManifest.xml`
- Set `android:allowBackup="false"` in `AndroidManifest.xml` for apps with sensitive data
- Export Android components (`Activity`, `Service`, `BroadcastReceiver`) only when necessary; add `android:exported="false"` where not needed
- Review intent filters — exported components with implicit intent filters are accessible by any app
- Use `FLAG_SECURE` for screens displaying sensitive data (prevents screenshots)
- Implement jailbreak/root detection for high-security apps using `flutter_jailbreak_detection`

```xml
<!-- AndroidManifest.xml — restrict exported components -->
<activity android:name=".MainActivity" android:exported="true">
    <!-- Only the launcher activity needs exported=true -->
</activity>
<activity android:name=".SensitiveActivity" android:exported="false" />
```

## iOS-Specific

- Declare only required usage descriptions in `Info.plist` (`NSCameraUsageDescription`, etc.)
- Store secrets in Keychain — `flutter_secure_storage` uses Keychain on iOS
- Use App Transport Security (ATS) — disallow arbitrary loads
- Set appropriate `NSAppTransportSecurity` exceptions only when necessary
- Enable data protection entitlement for sensitive files

## WebView Security

- Use `webview_flutter` v4+ (`WebViewController` / `WebViewWidget`) — the legacy `WebView` widget is removed
- Disable JavaScript unless explicitly required (`JavaScriptMode.disabled`)
- Validate URLs before loading — whitelist allowed domains; never load arbitrary URLs from deep links
- Never expose Dart callbacks to JavaScript unless absolutely needed and carefully sandboxed
- Use `NavigationDelegate.onNavigationRequest` to intercept and validate navigation requests

```dart
// webview_flutter v4+ API (WebViewController + WebViewWidget)
final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.disabled) // disabled unless required
  ..setNavigationDelegate(
    NavigationDelegate(
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null || uri.host != 'trusted.example.com') {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ),
  );

// In your widget tree:
WebViewWidget(controller: controller)
```

## Deep Link Security

- Validate all incoming deep link parameters before processing
- Never auto-authenticate or auto-authorize based solely on deep link data
- Use App Links (Android) and Universal Links (iOS) instead of custom URL schemes for security-critical flows
- Sanitize deep link paths to prevent injection attacks

## Obfuscation and Build Security

- Enable obfuscation in release builds: `flutter build apk --obfuscate --split-debug-info=./debug-info/`
- Keep `--split-debug-info` output out of version control (used for crash symbolication only)
- Ensure ProGuard/R8 rules don't inadvertently expose serialized classes
- Run `flutter analyze` and address all warnings before release
