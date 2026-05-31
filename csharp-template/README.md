# PROJECT_NAME

> **TODO:** Replace this line with a one-paragraph description of what this project does and why.

---

## Setup

```bash
# Clone and enter
git clone git@github.com:incendiary/PROJECT_NAME.git
cd PROJECT_NAME

# Restore NuGet packages
dotnet restore

# Build
dotnet build

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

### Requirements
- [.NET 8 SDK](https://dotnet.microsoft.com/download)
- [pre-commit](https://pre-commit.com/)
- [gitleaks](https://github.com/gitleaks/gitleaks) (installed via pre-commit)

---

## Usage

```bash
# TODO: add usage examples
dotnet run --project src/PROJECT_NAME
```

---

## Development

```bash
# Format code
dotnet format

# Check formatting without modifying
dotnet format --verify-no-changes

# Run tests
dotnet test

# Run all pre-commit hooks manually
pre-commit run --all-files
```

---

## Roadmap

| # | Status | Description |
|---|--------|-------------|
| [#1](../../issues/1) | ✅ Done | Secret scan — gitleaks + TruffleHog + detect-secrets (pre-commit + CI) |
| [#2](../../issues/2) | ✅ Done | Dependency audit — Dependabot (NuGet + Actions, weekly) |
| [#3](../../issues/3) | ⬜ Todo | Code quality pass — dead code, duplication, control flow |
| [#4](../../issues/4) | ✅ Done | Tooling — dotnet format, editorconfig, pre-commit, CI pipeline |
| [#5](../../issues/5) | ⬜ Todo | Tests — add unit/integration test coverage |
| [#6](../../issues/6) | ⬜ Todo | Documentation — fill in description + usage above |
| [#7](../../issues/7) | ✅ Done | Branch protection — force-push blocked, required CI checks on main |

Status key: ⬜ Todo · 🔄 In Progress · ✅ Done

---

## Releases

| Version | Description |
|---------|-------------|
| v1.0.0  | Public release — all roadmap items complete |

---

> This project was uplifted for public release with the assistance of Claude (Anthropic).
> Things should work, but some paths may not have been fully re-tested. PRs and fixes welcome.
