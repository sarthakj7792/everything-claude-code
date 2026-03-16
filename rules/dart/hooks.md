---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Dart / Flutter Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Dart and Flutter-specific content.

## PostToolUse Hooks

Configure in `~/.claude/settings.json`:

- **dart format**: Auto-format `.dart` files after edit
- **dart analyze**: Run static analysis after editing Dart files
- **flutter test**: Run tests after implementation changes
- **dart fix --apply**: Auto-apply lint fixes after editing Dart files
- **dart run build_runner build**: Regenerate code after editing freezed/json_serializable models
