# Project Publication Readiness — C++

## Context
- **Type:** <!-- e.g. Red team tool / utility / library -->
- **Authorization:** <!-- e.g. All development under signed scope of work -->
- **Public release intent:** <!-- e.g. Educational reference / portfolio -->
- **Audience:** <!-- e.g. Security professionals / developers -->

Fill in the four fields above before starting the audit.

---

## Ordered Steps — Work top to bottom. One PR per logical unit. Stop before any destructive action.

### Priority Zero — Secret Scanning
Audit every file and the full git history for hardcoded credentials, API keys,
tokens, internal IPs, hostnames, email addresses, and proprietary config.

```bash
# Working tree
grep -rniE "(key|secret|token|password|auth|bearer|api_key)" . \
  --include="*.cpp" --include="*.cc" --include="*.cxx" \
  --include="*.h" --include="*.hpp" --include="*.hxx" \
  --include="*.cmake" --include="*.txt" --include="*.json" \
  --include="*.yaml" --include="*.yml"

# Git history
git log -p | grep -iE "(key|secret|token|password|bearer)" | head -100
```

If secrets found in history: recommend destroying `.git` and reinitialising.
**Do not proceed until working tree and history are confirmed clean.**

---

### Step 1 — Dependency Audit
- Review `CMakeLists.txt`, `vcpkg.json`, `conanfile.txt/py` for severely outdated packages.
- Check for known CVEs in vendored or pinned third-party libraries.
- Flag anything high-severity.

---

### Step 2 — Code Quality Review (Karpathy pass)
Review every `.cpp` / `.h` file:
- **Dead code** — unreachable branches, unused includes, unused functions/variables
- **Duplication** — repeated logic that should be extracted
- **Confusing control flow** — catch-and-re-throw without context, empty catch blocks, dead branches
- **Comment noise** — comments that describe *what* not *why*
- **Memory safety** — raw owning pointers, missing RAII, manual delete

Present findings grouped as (A) dead code, (B) duplication, (C) control flow, (D) comment noise, (E) memory safety.
**Ask for confirmation before implementing each group. Make distinct commits per group.**

Principles:
- Surgical changes only — every changed line traces to a finding
- Prefer modern C++ (C++17/20) idioms: `std::unique_ptr`, range-for, structured bindings
- Match existing style unless step 3 tooling enforces otherwise

---

### Step 3 — Tooling
Set up if not already present:

```bash
# clang-format (format enforcement)
# clang-tidy (static analysis)
# Install via package manager, e.g.:
brew install llvm          # macOS
apt install clang-format clang-tidy  # Debian/Ubuntu

# Format check
clang-format --dry-run --Werror src/**/*.cpp src/**/*.h

# Static analysis
clang-tidy src/**/*.cpp -- -std=c++17

# Install pre-commit and detect-secrets
pip install pre-commit detect-secrets
pre-commit install
pre-commit run --all-files

# Generate secrets baseline (commit this file — it tracks known findings)
detect-secrets scan > .secrets.baseline
```

Required config files (templates already in this repo):
- `.clang-format` — style rules (LLVM base, Google, or Mozilla)
- `.clang-tidy` — enabled checks
- `.pre-commit-config.yaml` — gitleaks, trufflehog, clang-format, detect-secrets hooks
- `CMakeLists.txt` — build system
- `.github/workflows/ci.yml` — build + test + format check + secret baseline on push/PR
- `.gitleaks.toml` — gitleaks config with `.secrets.baseline` allowlist
- `.secrets.baseline` — detect-secrets known-findings baseline (committed, not ignored)

Add a GitHub issue and roadmap entry for any missing tests (Google Test / Catch2 recommended).

---

### Step 4 — Documentation
- Update `README.md`: project description, build instructions, usage, roadmap table
- Add `## Roadmap` section with columns: Issue #, Status, Description
- Create a GitHub issue for each step above that required work
- Add this footer to README:

```markdown
> This project was uplifted for public release with the assistance of Claude (Anthropic).
> Things should work, but some paths may not have been fully re-tested. PRs and fixes welcome.
```

---

### Step 5 — Branch Protection
```bash
# Make repo public
gh repo edit --visibility public

# Enable branch protection on main
gh api repos/incendiary/REPO_NAME/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["ci"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null
```

---

### Versioning
Tag a release at each milestone:
```bash
gh release create v0.1.0 --title "Secret scan + dependency audit clean" --notes "Priority Zero and Step 1 complete"
gh release create v0.2.0 --title "Code quality pass" --notes "Step 2 complete"
gh release create v0.3.0 --title "Tooling configured" --notes "Step 3 complete"
gh release create v1.0.0 --title "Public release" --notes "All steps complete, branch protection enabled"
```

---

## Engineering Philosophy
- Think before coding — state assumptions, ask before implementing
- Simplicity first — minimum code that solves the problem
- Surgical changes — touch only what you must
- Prefer RAII and smart pointers over raw memory management
- Never install global tools without confirming with user
