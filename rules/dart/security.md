---
paths:
  - "**/*.dart"
---
# Dart / Flutter Security

> This file extends [common/security.md](../common/security.md) with Dart and Flutter-specific content.

## Secrets Management

- Never hardcode API keys, tokens, or credentials in source code
- Use `--dart-define` or `--dart-define-from-file` for build-time secrets
- Use `flutter_secure_storage` for runtime secret storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- Use `.env` files with `flutter_dotenv` for local development (git-ignored)

```dart
// BAD
const apiKey = 'sk-abc123...';

// GOOD — from build-time define
const apiKey = String.fromEnvironment('API_KEY');

// GOOD — from secure storage at runtime
final token = await secureStorage.read(key: 'auth_token');
```

## Network Security

- Use HTTPS exclusively — configure `network_security_config.xml` (Android) and ATS (iOS) to block cleartext
- Pin certificates for sensitive endpoints using `dio` interceptors or `http_certificate_pinning`
- Set timeouts on all HTTP clients — never leave defaults
- Validate and sanitize all server responses before use

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
</network-security-config>
```

```dart
// Dio with timeout
final dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
  sendTimeout: const Duration(seconds: 15),
));
```

## Input Validation

- Validate all user input before processing or sending to API
- Use parameterized queries for local databases (sqflite, drift) — never concatenate user input into SQL
- Sanitize file paths from user input to prevent path traversal
- Validate and sanitize data before rendering in WebViews

```dart
// BAD — SQL injection
await db.rawQuery("SELECT * FROM items WHERE name = '$input'");

// GOOD — parameterized
await db.query('items', where: 'name = ?', whereArgs: [input]);
```

## Data Protection

- Use `flutter_secure_storage` for tokens and credentials, not `SharedPreferences`
- Encrypt sensitive local data at rest using `hive` with encryption or `sqflite_sqlcipher`
- Clear sensitive data from memory when no longer needed
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

## WebView Security

- Use `flutter_inappwebview` or `webview_flutter` with restricted settings
- Disable JavaScript unless explicitly needed
- Validate URLs before loading — whitelist allowed domains
- Never expose JavaScript channels that access sensitive native data
- Implement `NavigationDelegate` to control navigation

## Deep Link Security

- Validate all incoming deep link parameters before processing
- Never auto-authenticate or auto-authorize based solely on deep link data
- Use App Links (Android) and Universal Links (iOS) instead of custom URL schemes for security-critical flows
- Sanitize deep link paths to prevent injection attacks

## Platform-Specific Security

- **Android**: Set `android:allowBackup="false"` in `AndroidManifest.xml` for apps with sensitive data
- **Android**: Use `FLAG_SECURE` to prevent screenshots of sensitive screens
- **iOS**: Set appropriate `NSAppTransportSecurity` exceptions only when necessary
- **Both**: Implement jailbreak/root detection for high-security apps using `flutter_jailbreak_detection`
