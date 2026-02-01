# .github/

GitHub repository configuration and automation.

## Contents

| Path | Description |
|------|-------------|
| [workflows/](workflows/) | GitHub Actions CI/CD workflows |
| [skills/](skills/) | Copilot skill definitions |
| `copilot-instructions.md` | AI coding assistant guide |

## workflows/

GitHub Actions workflow files for continuous integration and release automation:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci-build.yml` | Push/PR to main | Build validation, static analysis, format check |
| `release.yml` | Tag push, release | Build and upload signed artifacts |

## skills/

Copilot skill definitions providing domain-specific knowledge for AI assistants working on this project.

## copilot-instructions.md

Comprehensive guide for AI coding assistants containing:
- Project architecture overview
- Build commands for macOS and iOS
- Code conventions and patterns
- CI/CD configuration details
- Asset licensing rules

## Usage

### Workflows

Workflows run automatically on:
- Push to `main` branch
- Pull request creation or update
- Tag push matching `v*`
- Release publication

### Local Development

Run the same checks locally before pushing:

```bash
./scripts/check.sh    # Format and lint checks
./scripts/test.sh     # Build verification
```

## See Also

- [workflows/README.md](workflows/README.md) - Detailed workflow documentation
- [FCE/](../FCE/) - Project documentation and phase guides
