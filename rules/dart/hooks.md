---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Dart/Flutter Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Dart and Flutter-specific content.

## PostToolUse Hooks

Configure in `~/.claude/settings.json`:

- **dart format**: Auto-format `.dart` files after edit
- **dart analyze**: Run static analysis after editing Dart files and surface warnings
- **flutter test**: Run tests after implementation changes
- **dart fix --apply**: Auto-apply lint fixes after editing Dart files
- **dart run build_runner build**: Regenerate code after editing freezed/json_serializable models

## PreToolUse Validation Hooks

Consider adding pre-tool-use validation for:
- **Responsive sizing**: Warn when raw `double` values are used for widget dimensions (should use `.w`, `.h`, `.r`, `.sp`)
- **Hardcoded colors**: Warn when `Color(0x...)` or `Colors.` appears outside of constant definitions (should use `AppColor.`)
- **Hardcoded text styles**: Warn when inline `TextStyle(fontSize: ...)` appears outside constant definitions (should use `AppTextStyle.`)

## Recommended Hook Configuration

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": { "tool_name": "Edit", "file_paths": ["**/*.dart"] },
        "hooks": [
          { "type": "command", "command": "dart format $CLAUDE_FILE_PATHS" }
        ]
      }
    ]
  }
}
```

## Pre-commit Checks

Run before committing Dart/Flutter changes:

```bash
dart format --set-exit-if-changed .
dart analyze --fatal-infos
flutter test
```

## Useful One-liners

```bash
# Format all Dart files
dart format .

# Analyze and report issues
dart analyze

# Run all tests with coverage
flutter test --coverage

# Regenerate code-gen files
dart run build_runner build --delete-conflicting-outputs

# Check for outdated packages
flutter pub outdated

# Upgrade packages within constraints
flutter pub upgrade
```
