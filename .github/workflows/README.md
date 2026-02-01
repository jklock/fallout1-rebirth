# .github/workflows/

GitHub Actions workflow definitions for CI/CD automation.

## Contents

| Workflow | Description |
|----------|-------------|
| `ci-build.yml` | Continuous integration for every push and PR |
| `release.yml` | Automated release builds with signing and upload |

## ci-build.yml

Runs on every push to `main` and on pull requests.

### Jobs

| Job | Runner | Purpose |
|-----|--------|---------|
| `static-analysis` | ubuntu-latest | Run cppcheck for C++ static analysis |
| `code-format` | ubuntu-latest | Verify clang-format compliance |
| `ios` | macos-14 | Build iOS application |
| `macos` | macos-14 | Build macOS application |

### Checks Performed

- **cppcheck**: Static analysis with C++17 standard
- **clang-format**: Code style verification against `.clang-format`
- **Build**: Full CMake build for both platforms

## release.yml

Runs on tag push (`v*`) or release publication.

### Jobs

| Job | Runner | Purpose |
|-----|--------|---------|
| `ios` | macos-14 | Build and upload IPA |
| `macos` | macos-14 | Build, sign, notarize, and upload DMG |

### Artifacts

- `fallout1-rebirth-ios.ipa` - iOS application package
- `fallout1-rebirth-macos.dmg` - macOS disk image (signed and notarized)

### Required Secrets

| Secret | Purpose |
|--------|---------|
| `APPLE_DEVELOPER_CERTIFICATE_P12_FILE_BASE64` | Code signing certificate |
| `APPLE_DEVELOPER_CERTIFICATE_P12_PASSWORD` | Certificate password |
| `APPLE_NOTARIZATION_TEAM_ID` | Apple Developer Team ID |
| `APPLE_NOTARIZATION_APPLE_ID` | Apple ID for notarization |
| `APPLE_NOTARIZATION_PASSWORD` | App-specific password |

## Usage

### Triggering CI

Push to `main` or open a pull request:

```bash
git push origin main
git push origin feature-branch
```

### Creating a Release

Tag and push to trigger release builds:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or create a release through the GitHub web interface.

## See Also

- [../.github/README.md](../README.md) - GitHub configuration overview
- [scripts/](../../scripts/) - Local build and check scripts
