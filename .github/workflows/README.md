# .github/workflows/

This directory previously contained GitHub Actions CI/CD workflows.

## Current Status

**CI/CD workflows have been removed.** This project is now built locally only.

## Local Development

Use these scripts instead of CI:

| Task | Command |
|------|---------|
| Pre-commit checks | `./scripts/dev/dev-check.sh` |
| Full verification | `./scripts/dev/dev-verify.sh` |
| macOS DMG | `./scripts/build/build-macos-dmg.sh` |
| iOS IPA | `./scripts/build/build-ios.sh && cd build-ios && cpack -C RelWithDebInfo` |

## Releasing

1. Build artifacts locally using the scripts above
2. Create a release on GitHub
3. Upload the DMG/IPA artifacts manually

## See Also

- [scripts/README.md](../../scripts/README.md) - Build and test scripts
- [copilot-instructions.md](../copilot-instructions.md) - Development guide
