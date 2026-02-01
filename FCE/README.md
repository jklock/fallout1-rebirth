# Fallout 1 Community Edition - Apple Revival

A project to revive Fallout 1 Community Edition specifically for macOS and iPadOS, consolidating community work from 180+ forks.

## Project Goals

1. **Fork Archaeology** - Analyze all GitHub forks to find valuable community contributions
2. **Platform Stripping** - Remove all non-Apple platform code (Windows, Linux, Android)
3. **2026 Modernization** - Widescreen support, mod system, knowledge database
4. **AI Optimization** - Structure codebase for ongoing AI-assisted maintenance

## Quick Start

### Prerequisites

```bash
# Install GitHub CLI
brew install gh

# Authenticate with GitHub
gh auth login

# Install Python dependencies (optional, for detailed analysis)
pip install -r tools/requirements.txt
```

### Run Fork Analysis

Quick analysis (shell script, requires only gh + jq):
```bash
./tools/quick_fork_analysis.sh https://github.com/alexbatalov/fallout1-ce
```

Detailed analysis (Python, richer output):
```bash
python tools/fork_archaeology.py https://github.com/alexbatalov/fallout1-ce
```

## Project Structure

```
FCE/
├── README.md                 # This file
├── PROJECT_PLAN.md           # Comprehensive project plan
├── tools/
│   ├── fork_archaeology.py   # Detailed fork analysis tool
│   ├── quick_fork_analysis.sh # Quick shell-based analysis
│   └── requirements.txt      # Python dependencies
└── analysis/                 # Generated analysis output (after running tools)
    ├── forks.json
    ├── pulls.json
    ├── issues.json
    ├── SUMMARY.md
    └── recommendations.md
```

## Documentation

- [PROJECT_PLAN.md](PROJECT_PLAN.md) - Full project plan with phases, sprints, and technical decisions

## Upstream Repository

- **Fallout 1 CE**: https://github.com/alexbatalov/fallout1-ce
- **Fallout 2 CE**: https://github.com/alexbatalov/fallout2-ce (related project)

## License

This project respects the [Sustainable Use License](https://github.com/alexbatalov/fallout1-ce/blob/main/LICENSE.md) of the upstream Fallout 1 CE project.
