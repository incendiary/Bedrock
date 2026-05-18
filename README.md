# StartingPoint

Project templates for Python, C#, and C++ repositories. Each template ships with secret scanning (gitleaks + TruffleHog + detect-secrets), formatting enforcement, CI pipelines, Dependabot, and branch protection — configured out of the box by `new-project.sh`.

---

## Quickstart

```bash
# Clone this repo once
git clone git@github.com:incendiary/StartingPoint.git
cd StartingPoint

# Spin up a new project
./new-project.sh <language> <repo-name>
```

### Examples

```bash
./new-project.sh python  my-python-tool
./new-project.sh csharp  SharpLoader
./new-project.sh cpp     exploit-helper
```

The script creates a private GitHub repo under your account, seeds it from the right template, and pushes the initial commit. It then prints the exact next steps for that language.

---

## What's in each template

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Publication-readiness audit prompt — loads automatically in Claude Code |
| `.pre-commit-config.yaml` | gitleaks · TruffleHog · detect-secrets · language formatter |
| `.github/workflows/ci.yml` | Build, test, lint, secret scan on push/PR |
| `.github/dependabot.yml` | Weekly Dependabot updates for packages + Actions |
| `.gitleaks.toml` | Gitleaks config with `.secrets.baseline` allowlist |
| `.secrets.baseline` | detect-secrets baseline (committed; regenerate after adding code) |
| `.gitignore` | Comprehensive ignores for the language |
| `README.md` | Project README with roadmap table |
| `pyproject.toml` | Python: Black, Ruff, isort, detect-secrets config |
| `.editorconfig` | C#: Microsoft conventions + naming/compiler warnings |
| `.clang-format` | C++: Google-based style, 100-char columns |
| `.clang-tidy` | C++: Core Guidelines + modernize checks |
| `CMakeLists.txt` | C++: CMake scaffold with optional test build |

---

## Roadmap table (per project)

Each generated README contains a roadmap. Items marked ✅ below are **done by default** when `new-project.sh` runs — no manual setup needed.

| # | Default | Description |
|---|---------|-------------|
| #1 | ✅ Done | Secret scan (gitleaks + TruffleHog + detect-secrets, pre-commit + CI) |
| #2 | ✅ Done | Dependency audit (Dependabot weekly, packages + Actions) |
| #3 | ⬜ Todo | Code quality pass (manual review — run CLAUDE.md audit) |
| #4 | ✅ Done | Tooling (pre-commit hooks, CI pipeline, formatters) |
| #5 | ⬜ Todo | Tests (scaffold present for Python; add tests for your code) |
| #6 | ⬜ Todo | Documentation (README scaffold present; fill in description + usage) |
| #7 | ✅ Done | Branch protection (force-push blocked, required CI checks on main) |

Status key: ⬜ Todo · 🔄 In Progress · ✅ Done

---

## Using CLAUDE.md

After running `new-project.sh`, open the project in Claude Code. The `CLAUDE.md` in the project root will be loaded automatically. Fill in the four context fields at the top (Type, Authorization, Release intent, Audience), then tell Claude to start the audit.

---

## Contributing to StartingPoint

```bash
git clone git@github.com:incendiary/StartingPoint.git
cd StartingPoint
pip install pre-commit
pre-commit install
```

**Universality rule:** any security or tooling addition must be applied consistently across:
- All three template `.pre-commit-config.yaml` files
- All three template `.github/workflows/ci.yml` files
- The StartingPoint root `.pre-commit-config.yaml`
- The StartingPoint root `.github/workflows/ci.yml`

If you add a tool in one place, add it everywhere before committing.
