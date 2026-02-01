# Contributing to Fallout 1 Rebirth

Thanks for your interest in contributing! This guide explains how to contribute effectively.

## Table of Contents

- [Project Scope](#project-scope)
- [Getting Started](#getting-started)
- [Code Style Requirements](#code-style-requirements)
- [Before Submitting](#before-submitting)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)

---

## Project Scope

Fallout 1 Rebirth is an **Apple-only fork**. Contributions should focus on:

### In Scope

- macOS and iOS/iPadOS improvements
- iPad touch control optimization
- Engine bug fixes (especially Fallout 1-specific)
- Quality of life features
- Performance optimizations for Apple hardware
- Documentation improvements

### Out of Scope

- Windows, Linux, or Android support (use upstream for these)
- New game content or mods
- Features that break compatibility with original save files
- Changes that require original game assets in the repo

---

## Getting Started

### Prerequisites

1. **Development Environment**:
   - macOS with Xcode installed
   - CMake 3.13 or later
   - clang-format (`brew install clang-format`)
   - cppcheck (`brew install cppcheck`)

2. **Game Assets** (for testing):
   - Purchase Fallout from [GOG](https://www.gog.com/game/fallout) or [Steam](https://store.steampowered.com/app/38400)
   - Extract game data to `GOG/Fallout1/` or set `GAME_DATA` environment variable

### Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/fallout1-rebirth.git
cd fallout1-rebirth

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/fallout1-rebirth.git

# Create a feature branch
git checkout -b feature/your-feature-name
```

### Build and Test

```bash
# Build for macOS
./scripts/build-macos.sh

# Run pre-commit checks
./scripts/dev-check.sh

# Test on iPad Simulator
./scripts/test-ios-simulator.sh
```

---

## Code Style Requirements

### Formatting

The project uses a WebKit-based style (defined in `.clang-format`). Format all code before submission:

```bash
# Format all source files
./scripts/dev-format.sh

# Check formatting without modifying
./scripts/dev-format.sh --check
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | lowercase with underscores | `my_new_file.cc` |
| Header guards | `FALLOUT_<PATH>_H_` | `FALLOUT_GAME_COMBAT_H_` |
| Functions | camelCase | `myFunction()` |
| Constants | UPPER_SNAKE_CASE | `MAX_PARTY_MEMBERS` |
| Macros | UPPER_SNAKE_CASE | `#define MY_MACRO 42` |

### Code Organization

```cpp
// Header file: src/game/my_feature.h

#ifndef FALLOUT_GAME_MY_FEATURE_H_
#define FALLOUT_GAME_MY_FEATURE_H_

namespace fallout {

// Public declarations here

} // namespace fallout

#endif // FALLOUT_GAME_MY_FEATURE_H_
```

```cpp
// Implementation file: src/game/my_feature.cc

#include "game/my_feature.h"

// Standard library includes
#include <stdio.h>

// Project includes
#include "game/other_file.h"
#include "plib/gnw/debug.h"

namespace fallout {

// Static (file-local) functions first
static void helperFunction()
{
    // Implementation
}

// Public functions
int publicFunction(int arg)
{
    return helperFunction() + arg;
}

} // namespace fallout
```

### Memory Management

- Use C-style allocation (`malloc`, `free`, `mem_malloc`, `mem_free`)
- The codebase uses extensive global state
- Avoid complex RAII patterns without thorough testing
- Always check allocation results

### Error Handling

Use the built-in debug functions:

```cpp
#include "plib/gnw/debug.h"

// Debug output (development only)
debug_printf("Value: %d\n", value);

// Non-fatal errors
dbg_error("subsystem", "Error message: %d", error_code);

// Fatal errors (terminates application)
GNWSystemError("Fatal error message");
```

---

## Before Submitting

### Required Checks

Run these before every submission:

```bash
# 1. Format code
./scripts/dev-format.sh

# 2. Pre-commit checks (formatting + static analysis)
./scripts/dev-check.sh

# 3. Build verification
./scripts/dev-verify.sh
```

All checks must pass before submitting a pull request.

### Testing Requirements

| Change Type | Required Testing |
|-------------|------------------|
| Build system | `./scripts/build-macos.sh` + `./scripts/build-ios.sh` |
| macOS-only code | `./scripts/test-macos.sh` |
| iOS-only code | `./scripts/test-ios-headless.sh --build` |
| Core engine | Both macOS and iOS tests |
| UI changes | Manual testing on both platforms |

### Adding New Source Files

If adding new `.cc` or `.h` files:

1. Add to `CMakeLists.txt` under `target_sources`:
   ```cmake
   target_sources(${EXECUTABLE_NAME} PUBLIC
       # ... existing files ...
       "src/game/my_new_file.cc"
       "src/game/my_new_file.h"
   )
   ```

2. Verify build:
   ```bash
   ./scripts/build-macos.sh
   ```

### Commit Messages

Use clear, descriptive commit messages:

```
Short summary (50 chars or less)

More detail if needed. Wrap at 72 characters.
Explain what and why, not how.

- Bullet points are OK
- Keep lines under 72 characters
```

Examples:
- `Fix Survivalist perk HP calculation`
- `Add iPad trackpad gesture support`
- `Update CMake minimum version to 3.13`

---

## Pull Request Process

### 1. Create Pull Request

- Push your branch to your fork
- Create a pull request against `main`
- Fill out the PR template (if provided)

### 2. PR Requirements

Your PR should include:

- **Clear title**: Summarize the change
- **Description**: What, why, and how
- **Testing done**: What you tested
- **Related issues**: Link any related issues

### 3. CI Checks

The following checks run automatically:

| Check | Requirement |
|-------|-------------|
| Static analysis (cppcheck) | No errors |
| Code formatting | No differences |
| iOS build | Compiles successfully |
| macOS build | Compiles successfully |

All checks must pass before merging.

### 4. Review Process

- Maintainers will review your code
- Address any feedback in new commits
- Once approved, a maintainer will merge

### 5. After Merging

- Delete your feature branch
- Sync your fork with upstream:
  ```bash
  git checkout main
  git pull upstream main
  git push origin main
  ```

---

## Issue Guidelines

### Bug Reports

Include:
1. **Platform**: macOS version or iOS version + device
2. **Steps to reproduce**: Exact steps to trigger the bug
3. **Expected behavior**: What should happen
4. **Actual behavior**: What actually happens
5. **Build info**: Release version or commit hash

### Feature Requests

Include:
1. **Use case**: Why is this feature needed?
2. **Proposed solution**: How should it work?
3. **Alternatives considered**: Other approaches you considered
4. **Platform scope**: macOS, iOS, or both?

### Questions

For general questions:
- Check existing documentation first
- Search closed issues for similar questions
- Use clear, specific titles

---

## Additional Resources

- [architecture.md](architecture.md) - Codebase structure
- [building.md](building.md) - Build instructions
- [testing.md](testing.md) - Testing procedures
- [scripts.md](scripts.md) - Script reference

## Code of Conduct

Be respectful and constructive in all interactions. We welcome contributors of all experience levels.
