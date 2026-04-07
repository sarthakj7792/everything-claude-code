# Master Guide: Using Everything Claude Code for Flutter

A practical, step-by-step guide to getting maximum value from ECC when building Flutter applications.

---

## 1. Installation

### Quick Start

```bash
# Clone ECC (if not already done)
git clone https://github.com/sarthakj7792/everything-claude-code.git
cd everything-claude-code

# Install using language shorthand (any of these work)
./install.sh dart              # Dart rules + Flutter skills + agents + commands
./install.sh flutter           # Same as above (flutter is an alias for dart)
./install.sh dart flutter      # Also works (deduplicated)

# Or install with other languages
./install.sh dart python typescript

# Or install via manifest components
./install.sh --with framework:flutter

# Or install everything
./install.sh --profile full
```

This installs:
- **5 Dart rules** → `~/.claude/rules/dart/`
- **3 Flutter skills** → `~/.claude/skills/`
- **1 Flutter agent** → `~/.claude/agents/`
- **Generic agents** (planner, tdd-guide, code-reviewer, etc.) → `~/.claude/agents/`
- **Slash commands** (/tdd, /plan, /code-review, etc.) → `~/.claude/commands/`

### Verify Installation

```bash
ls ~/.claude/rules/dart/         # 5 files: coding-style, testing, patterns, security, hooks
ls ~/.claude/skills/flutter-*    # 3 dirs: flutter-patterns, flutter-testing, flutter-dart-code-review
ls ~/.claude/agents/flutter-*    # 1 file: flutter-reviewer.md
```

### IDE Targets

```bash
./install.sh --target cursor dart flutter     # For Cursor
./install.sh --target antigravity dart flutter # For Antigravity
```

---

## 2. What You Get

### Rules (Always Active)

Rules are loaded automatically in every Claude Code session. They enforce standards without you asking.

| File | What It Enforces |
|------|-----------------|
| `dart/coding-style.md` | `dart format`, immutability, null safety, naming conventions, responsive sizing extensions |
| `dart/patterns.md` | Clean Architecture, BLoC/Riverpod/Provider patterns, MVVM, Dio networking, design tokens |
| `dart/testing.md` | 80% coverage minimum, TDD workflow, unit/widget/BLoC/golden/integration test patterns |
| `dart/security.md` | Secrets via `--dart-define`, HTTPS enforcement, secure storage, token refresh, deep link validation |
| `dart/hooks.md` | Auto-run `dart format`, `dart analyze`, `flutter test` after edits |

### Skills (Activated On-Demand)

Skills provide deep reference material. Claude activates them when your task matches their trigger conditions.

| Skill | Triggers When |
|-------|--------------|
| `flutter-patterns` | Building widgets, designing navigation, structuring features, optimizing performance |
| `flutter-testing` | Writing tests, setting up TDD, configuring CI/CD coverage |
| `flutter-dart-code-review` | Reviewing code quality, state management, accessibility, security |

### Agents (Delegated Work)

Agents are specialized sub-processes Claude can spawn for focused tasks.

| Agent | What It Does |
|-------|-------------|
| `flutter-reviewer` | Reviews your Flutter code for widget best practices, state management, performance, accessibility, security |
| `planner` | Creates implementation plans for complex features |
| `tdd-guide` | Enforces write-tests-first workflow |
| `code-reviewer` | General code quality review |
| `build-error-resolver` | Fixes build/compile errors |
| `security-reviewer` | Flags vulnerabilities before commit |

---

## 3. Daily Workflow

### Starting a New Feature

```
You: Build a user profile screen with edit functionality

Claude will automatically:
1. Use the planner agent to break down the task
2. Reference flutter-patterns for architecture guidance
3. Follow the MVVM or BLoC pattern based on your project
4. Apply responsive sizing rules (.w, .h, .r, .sp)
5. Use centralized AppColor/AppTextStyle tokens
```

Or be explicit with slash commands:

```
You: /plan Build a user profile screen with avatar upload, form validation, and API integration
```

### TDD Workflow

```
You: /tdd Add a FeedViewModel that fetches paginated feed items

Claude will:
1. Write tests FIRST (RED) — ViewModel state transitions, error handling
2. Run tests — verify they fail
3. Implement FeedViewModel (GREEN)
4. Run tests — verify they pass
5. Refactor (IMPROVE)
6. Check coverage ≥ 80%
```

### Code Review

After writing code, Claude automatically runs the flutter-reviewer agent. You can also trigger it manually:

```
You: /code-review
```

The reviewer checks 13+ categories including:
- Architecture violations (business logic in widgets)
- State management anti-patterns (boolean flag soup, missing error states)
- Widget composition (oversized build methods, missing const)
- Performance (unnecessary rebuilds, expensive work in build())
- Security (hardcoded secrets, insecure storage)
- Accessibility (missing semantic labels, small tap targets)

### Fixing Build Errors

```
You: /build-fix
```

This runs the build-error-resolver agent to analyze and fix compilation errors incrementally.

---

## 4. State Management Patterns

ECC supports all major Flutter state management solutions. The rules and skills are library-agnostic.

### If Your Project Uses BLoC/Cubit

The `dart/patterns.md` rule and `flutter-patterns` skill provide:
- Event → State pattern with sealed classes
- `bloc_test` testing patterns with `mocktail`
- BlocProvider/BlocBuilder widget binding

### If Your Project Uses Provider + ChangeNotifier (MVVM)

Added from real-world production app patterns:
- `BaseModel` with `ViewState` enum (idle, busy, error)
- ViewModel pattern with `notifyListeners()`
- `Consumer<ViewModel>` widget binding
- Testing with `mockito` and `ChangeNotifierProvider`

### If Your Project Uses Riverpod

The patterns cover:
- `AsyncNotifier` providers
- `ConsumerWidget` binding
- `ref.watch()` / `ref.read()` patterns

### Decision Guide

| Approach | Best For |
|----------|---------|
| **BLoC/Cubit** | Large teams, complex event flows, strict separation |
| **Riverpod** | Compile-safe DI, flexible scoping, modern projects |
| **Provider + MVVM** | Simpler projects, smaller teams, rapid prototyping |
| **StatefulWidget** | Local-only state (animations, form fields) |

---

## 5. Responsive Design

ECC enforces responsive sizing via rules. All dimensions must use scaling extensions:

| Extension | Purpose | Example |
|-----------|---------|---------|
| `.w` | Horizontal (padding, width, margins) | `EdgeInsets.symmetric(horizontal: 16.w)` |
| `.h` | Vertical (padding, height) | `SizedBox(height: 20.h)` |
| `.r` | Radius (BorderRadius, icons) | `BorderRadius.circular(12.r)` |
| `.sp` | Font size (capped at 1.3x) | `TextStyle(fontSize: 14.sp)` |

**Setup**: Use `flutter_screenutil` or implement custom extensions with a design baseline (e.g., 430x932 for iPhone 14 Pro Max).

**Rule**: Raw `double` values for dimensions are flagged during code review.

---

## 6. Design Tokens

ECC enforces centralized constants — no inline colors, fonts, or magic numbers in widgets.

```
lib/shared/constants/
├── color_constants.dart     # AppColor.primary, AppColor.background, etc.
├── style_constants.dart     # AppTextStyle.heading, AppTextStyle.body, etc.
└── api_constants.dart       # APIRoutes.login, APIRoutes.feed, etc.
```

**Rule**: Using `Color(0xFF...)` or inline `TextStyle(...)` in widgets is flagged during code review.

---

## 7. Networking

ECC provides patterns for centralized HTTP client setup:

- **APIBase** class wrapping Dio with `getRequest()`, `postRequest()`, etc.
- **AuthInterceptor** for automatic Bearer token attachment and 401 refresh
- **Centralized API routes** — all endpoints in `APIRoutes` class
- **Security**: HTTPS-only, certificate pinning, 30s timeouts, response validation

---

## 8. Testing Strategy

### Coverage Targets

| Test Type | Target | Tools |
|-----------|--------|-------|
| Unit | 80%+ | `flutter_test`, `mockito`/`mocktail` |
| Widget | Key screens | `testWidgets`, `pumpWidget` |
| BLoC | All cubits/blocs | `bloc_test` |
| Golden | Critical UI | `golden_toolkit` |
| Integration | Happy paths | `integration_test` |

### Test Organization

```
test/
├── helpers/           # pumpApp, mock factories
├── unit/
│   ├── models/        # JSON serialization, fromJson/toJson
│   └── viewmodels/    # State transitions, error handling
├── widgets/           # Widget rendering, interaction
├── blocs/             # BLoC event → state tests
└── goldens/           # Visual regression snapshots

integration_test/
└── app_test.dart      # End-to-end user flows
```

### Key Testing Rules

1. **Tests before code** — TDD is mandatory
2. **Never test implementation details** — test behavior and outputs
3. **Initialize responsive system in tests** — call `Responsive.init(context)` before assertions
4. **Use `pump()` after state changes** — don't forget to rebuild the widget tree
5. **No shared mutable state** — fresh setUp for each test

---

## 9. Security Checklist

Before every commit, ECC enforces:

- [ ] No hardcoded API keys, tokens, or secrets (use `--dart-define` or `flutter_secure_storage`)
- [ ] All user inputs validated before processing
- [ ] HTTPS enforced for all network requests
- [ ] Tokens stored in `flutter_secure_storage`, not `SharedPreferences`
- [ ] Token refresh flow handles 401 correctly
- [ ] WebViews restrict JavaScript and navigation
- [ ] Deep links validate and sanitize parameters
- [ ] Android: `allowBackup: false`, `FLAG_SECURE` for sensitive screens
- [ ] iOS: ATS enabled, keychain for sensitive data

---

## 10. Slash Commands Reference

| Command | What It Does |
|---------|-------------|
| `/plan` | Create implementation plan for a feature |
| `/tdd` | Start TDD workflow (RED → GREEN → IMPROVE) |
| `/code-review` | Run code quality review |
| `/build-fix` | Fix build/compilation errors |
| `/e2e` | Generate and run E2E tests |
| `/refactor-clean` | Remove dead code, consolidate duplicates |
| `/verify` | Run full verification loop |
| `/learn` | Extract reusable patterns from session |
| `/skill-create` | Generate a new skill from git history |

---

## 11. Project Setup Checklist

When starting a new Flutter project with ECC:

1. **Install ECC**: `./install.sh dart flutter`
2. **Create CLAUDE.md** in your project root with:
   - Architecture pattern (MVVM, BLoC, Clean Architecture)
   - State management choice
   - Directory structure
   - Key file reference table
   - Build/run commands
3. **Set up analysis_options.yaml** with strict lints (`very_good_analysis` or `flutter_lints`)
4. **Create shared constants**:
   - `lib/shared/constants/color_constants.dart`
   - `lib/shared/constants/style_constants.dart`
   - `lib/shared/constants/api_constants.dart`
5. **Set up responsive scaling** (flutter_screenutil or custom)
6. **Create shared widgets** in `lib/views/widgets/common/`
7. **Configure Dio** with auth interceptor and centralized API routes
8. **Set up test helpers** in `test/helpers/`

---

## 12. Tips for Maximum Effectiveness

### Let Claude Lead with Planning

For any feature that touches 3+ files, start with `/plan`. Claude will create a phased implementation plan with dependencies and risks identified upfront.

### Use TDD — It's Enforced

ECC's rules require tests first. Don't fight it — the `/tdd` command makes it painless. You get better architecture as a side effect because testable code is well-structured code.

### Trust the Reviewer

After writing code, the flutter-reviewer agent runs automatically. Pay attention to CRITICAL and HIGH severity findings — they catch real bugs (missing dispose, BuildContext after await, state management leaks).

### Keep CLAUDE.md Updated

Your project's CLAUDE.md is the most important file for Claude Code. Keep it current with:
- Architecture decisions
- File reference table (key files and their purpose)
- Build commands
- Any project-specific conventions

### Use Parallel Agents

For complex tasks, Claude will automatically parallelize work:
- Security review + code review + performance analysis running simultaneously
- Multiple file explorations in parallel
- Test execution while reviewing other code

### Responsive Sizing from Day One

Adopt `.w`/`.h`/`.r`/`.sp` extensions immediately. Retrofitting responsive sizing later is painful. ECC will flag raw double values during review.

---

## 13. Supported State Management Solutions

ECC's flutter-dart-code-review skill covers all major solutions:

| Solution | Review Coverage |
|----------|----------------|
| BLoC / Cubit | Event/state design, value equality, stream subscriptions |
| Riverpod | Provider scoping, ref lifecycle, AsyncValue handling |
| Provider + ChangeNotifier | Consumer scope, notifyListeners, ViewState pattern |
| GetX | Reactive mutations, lifecycle, Obx rebuilds |
| MobX | Observable/action separation, computed derivations |
| Signals | Signal creation, effect cleanup, computed chains |
| Built-in (StatefulWidget) | setState scope, lifecycle methods |

---

## Quick Reference Card

```
INSTALL:     ./install.sh dart flutter
PLAN:        /plan <feature description>
TDD:         /tdd <what to implement>
REVIEW:      /code-review
BUILD FIX:   /build-fix
E2E:         /e2e <user flow>
VERIFY:      /verify

RULES:       ~/.claude/rules/dart/          (5 files, always active)
SKILLS:      ~/.claude/skills/flutter-*     (3 skills, on-demand)
AGENTS:      ~/.claude/agents/flutter-*     (1 agent, delegated)
```
