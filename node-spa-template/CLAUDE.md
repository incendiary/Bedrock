# CLAUDE.md — Publication Readiness Audit (Node / SPA)

Fill in the four fields below, then tell Claude: **"Start the audit."**

```
Type:            [e.g. REST API + Vue SPA, CLI tool, internal dashboard]
Authorization:   [e.g. personal project, authorized engagement, open-source]
Release intent:  [e.g. public GitHub, internal only, portfolio]
Audience:        [e.g. developers, homebrewers, red teamers]
```

---

## Audit Steps

### Priority Zero — Secret Scan
```bash
npm audit
npx gitleaks detect --source . --verbose
# TruffleHog and detect-secrets run via pre-commit
pre-commit run --all-files
```
- No credentials, API keys, tokens, or internal IPs in source
- No absolute local filesystem paths (home directory references) committed
- `.env` is in `.gitignore` and never committed
- `.secrets.baseline` is up to date (`detect-secrets scan > .secrets.baseline`)

### Step 1 — Dependency Audit
```bash
npm audit --audit-level=moderate
```
- All moderate/high/critical vulnerabilities resolved or documented
- `package-lock.json` committed so CI uses pinned versions
- Dependabot or `npm outdated` checked for stale dependencies

### Step 2 — Code Quality
```bash
npm run lint
```
- ESLint passes with zero errors
- No `console.log` left in production paths (use a logger or remove)
- No hardcoded hostnames, ports, or absolute local paths
- No dead routes or commented-out code blocks in committed files

### Step 3 — Tooling
```bash
pre-commit install
pre-commit run --all-files
```
- Pre-commit hooks installed and all checks pass
- CI pipeline (`.github/workflows/ci.yml`) green on a clean push
- `npm run dev` starts both server and client without errors
- `npm run build` produces a clean build in `server/public/`

### Step 4 — Documentation & Branch Protection
- `README.md` has: description, prerequisites, setup steps, usage, roadmap
- Sensitive engagement context removed from all docs and comments
- Branch protection enabled on `main`:
```bash
gh api repos/OWNER/REPO/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["lint","secret-scan"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":0}' \
  --field restrictions=null
```

### Step 5 — Versioning
Tag releases using semver. Suggested milestones:

| Tag | Milestone |
|-----|-----------|
| v0.1.0 | Secret + dependency scan clean |
| v0.2.0 | Code quality pass, ESLint green |
| v0.3.0 | Tooling complete, CI green |
| v1.0.0 | Public release ready |
