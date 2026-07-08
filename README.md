# Bedrock

One command from an empty GitHub repo to a hardened, production-ready project — secret scanning wired in, branch protection configured, CI running, before you write a single line of application code.

Most project templates give you a file layout. Bedrock gives you a security posture. Three-layer secret scanning (pattern matching + verified credential detection + entropy baseline), formatting enforcement, CI pipelines, Dependabot, and branch protection are all configured out of the box by `new-project.sh` — consistently, across Python, C#, C++, Node/SPA, and IaC. The same security standard applies regardless of which language you reach for.

---

## Quickstart

```bash
# Clone this repo once
git clone git@github.com:incendiary/Bedrock.git
cd Bedrock

# Spin up a new project
./new-project.sh <language> <repo-name>
```

### Examples

```bash
./new-project.sh python    my-python-tool
./new-project.sh csharp    SharpLoader
./new-project.sh cpp       exploit-helper
./new-project.sh node-spa  HopStock --public
./new-project.sh iac       my-terraform-range
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
| `package.json` (workspaces) | Node/SPA: root workspace manifest for server + client |
| `vite.config.js` | Node/SPA: Vite config proxying `/api` to Express, builds to `server/public/` |
| `versions.tf` / `main.tf` / `variables.tf` | IaC: Terraform skeleton with version pins and common tags |
| `terraform.tfvars.example` | IaC: sample variables; real `terraform.tfvars` is gitignored |

---

## What each generated project gets

Each generated README contains a seven-item roadmap. Bedrock wires up four of those items automatically — the remaining three are handed to you to complete for your specific project.

**Configured automatically by `new-project.sh`:**

| # | Item |
|---|------|
| 1 | Secret scan — gitleaks + TruffleHog + detect-secrets (pre-commit + CI) |
| 2 | Dependency audit — Dependabot (packages + Actions, weekly) |
| 4 | Tooling — language formatter, pre-commit hooks, CI pipeline |
| 7 | Branch protection — force-push blocked, required CI checks on main |

**Completed by you after generating:**

| # | Item |
|---|------|
| 3 | Code quality pass — run the CLAUDE.md audit on your code |
| 5 | Tests — scaffold provided; write tests for your implementation |
| 6 | Documentation — README scaffold provided; fill in description + usage |

---

## Using CLAUDE.md

After running `new-project.sh`, open the project in Claude Code. The `CLAUDE.md` in the project root will be loaded automatically. Fill in the four context fields at the top (Type, Authorization, Release intent, Audience), then tell Claude to start the audit.

---

## Releases

| Version | Description |
|---------|-------------|
| v0.1.0  | Initial public release — python and C# templates |
| v0.2.0  | detect-secrets + gitleaks configs across all templates; C++ template |
| v0.3.0  | node-spa template (Express + Vue 3 + Vite + SQLite) |
| v1.0.0  | All templates at full parity — tooling, secrets, branch protection |
| v1.0.1  | Renamed to Bedrock |

---

## Contributing to Bedrock

```bash
git clone git@github.com:incendiary/Bedrock.git
cd Bedrock
pip install pre-commit
pre-commit install
```

**Universality rule:** any security or tooling addition must be applied consistently across:
- All five template `.pre-commit-config.yaml` files
- All five template `.github/workflows/ci.yml` files
- The Bedrock root `.pre-commit-config.yaml`
- The Bedrock root `.github/workflows/ci.yml`

If you add a tool in one place, add it everywhere before committing.
