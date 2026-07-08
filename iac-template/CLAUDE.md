# Project Publication Readiness — IaC

## Context
- **Type:** <!-- e.g. Terraform range / Packer + Ansible images -->
- **Authorization:** <!-- e.g. All development under signed scope of work -->
- **Public release intent:** <!-- e.g. Internal-only, never publish -->
- **Audience:** <!-- e.g. Maintainers only -->

Fill in the four fields above before starting the audit. Infrastructure that
provisions deliberately vulnerable services is internal-only by default.

---

## Ordered Steps — Work top to bottom. One PR per logical unit. Stop before any destructive action.

### Priority Zero — Secret Scanning
Audit every file and the full git history for hardcoded credentials, access
keys, tokens, internal IPs, hostnames, account ids, and AMI identifiers.

```bash
grep -rniE "(aws_access_key|aws_secret|akia|asia|private_key|password|token)" . \
  --include="*.tf" --include="*.tfvars" --include="*.hcl" \
  --include="*.yml" --include="*.yaml" --include="*.json"
```

Confirm `terraform.tfvars`, `*.tfstate`, `.terraform/`, and any AMI id files are
gitignored and were never committed. If secrets exist in history, recommend
destroying `.git` and reinitialising. **Do not proceed until history is clean.**

---

### Step 1 — Provider and Module Audit
- Pin `required_version` and every provider version in `versions.tf`.
- Prefer registry modules with pinned versions over copied HCL.
- Let Dependabot track the `terraform` and `github-actions` ecosystems.

---

### Step 2 — Configuration Review
- **Network posture:** private subnets, SSM Session Manager access only,
  default-deny security groups, least-privilege egress, no public ingress.
- **Tagging:** every resource carries project, owner, ttl, and range-version.
- **Teardown:** a single teardown target and a TTL auto-expiry path exist.
- **Cost:** a cost alarm and a documented hourly estimate are present.
- Note that host hardening is deliberately out of scope. Hosts may be
  unhardened by design; network isolation is what keeps a range safe.

---

### Step 3 — Tooling

```bash
pip install pre-commit detect-secrets checkov
pre-commit install
pre-commit run --all-files
detect-secrets scan > .secrets.baseline
```

Config files (templates already in this repo):
- `.pre-commit-config.yaml` — gitleaks, trufflehog, terraform_fmt, terraform_validate, checkov, detect-secrets
- `.github/workflows/ci.yml` — fmt, validate, advisory checkov, secret scan
- `.github/dependabot.yml` — terraform + github-actions, weekly
- `.gitignore` — state, tfvars, .terraform, AMI ids, credential material

Checkov runs in advisory mode. Seeded vulnerabilities are expected findings and
must not fail the build.

---

### Step 4 — Documentation
- `README.md`: what the range provisions, how to plan and apply, teardown, and
  the documented hourly cost estimate.
- Record the machine-readable inventory the configuration emits.

---

### Step 5 — Branch Protection
`new-project.sh` enables branch protection with the required checks on `main`.
Keep repositories private. Never pass `--public`.

---

## Engineering Philosophy
- Think before coding — state assumptions, ask before implementing.
- Simplicity first — minimum configuration that provisions the range.
- Surgical changes — touch only what you must.
- Never apply against an account without explicit, separate approval.
