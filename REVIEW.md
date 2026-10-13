# Bedrock holistic review

Reviewed at `182ee06`; `main` then gained `iac-template`, a licence and `pre-push-validation.sh` (see ROADMAP Phase 4b). Findings below apply to all five templates unless noted.
Scope: 62 tracked files, four templates plus `new-project.sh`. Predictive: what breaks as
templates multiply (a Terraform template is planned) and as generated projects age.
Actions are in `ROADMAP.md` (IDs below match).

## Executive summary

The secret-scanning gate that is Bedrock's headline claim does not actually fail on a new
credential. `detect-secrets scan --baseline` rewrites the baseline and exits 0 (R-2). The Python
template cannot be installed because its build backend does not exist (R-1), and the node-spa
template fails `npm ci` in CI because it ships no lockfile (R-3). Consistency across templates
is enforced only by a sentence in the README, so drift is certain as templates grow (C-1).
The public repo's root `.gitleaks.toml` names employers, in history too (H-1; owner decision:
remove and wipe history).

## Architecture

| Path | Responsibility | Concerns |
|---|---|---|
| `new-project.sh` | Create repo, copy template, substitute names, push, set branch protection | Untested; hardcoded owner; `LANG` clobbers the locale variable; unvalidated repo name reaches `sed` |
| `<lang>-template/` | Files copied verbatim into new repos | Four near-identical copies of secret-scan job, pre-commit secret blocks, `.gitleaks.toml`, `.secrets.baseline` |
| `.github/workflows/ci.yml` | Validates templates (shell syntax, yamllint, baseline) | Does not lint root workflows; no template is ever built or tested |
| `.github/workflows/secret-scan.yml` | gitleaks + TruffleHog | Duplicates the `secret-scan` job in `ci.yml`; TruffleHog on `@main` |
| root `.pre-commit-config.yaml`, `.gitleaks.toml` | Bedrock's own gates | Root `.gitleaks.toml` differs from templates and carries employer rules |

Data flow: user args to `gh repo create`/`clone`, `cp -r` template, `sed` substitution over every
text file, `git push`, `gh api` branch protection with check names hard-coded per language.
Check names must equal CI job names; nothing verifies that.

## Risk inventory

| # | Category | Finding | Score | Location |
|---|---|---|---|---|
| 1 | Security | CI and `test_secrets.py` secret-baseline checks are no-ops (`scan --baseline` exits 0) | 5 | all 5 `ci.yml`, `python-template/tests/test_secrets.py` |
| 2 | Reliability | Python build backend `setuptools.backends.legacy:build` does not exist; `pip install -e ".[dev]"` fails | 5 | `python-template/pyproject.toml:3` |
| 3 | Reliability | node-spa has no `package-lock.json`; `npm ci` fails in generated CI | 5 | `node-spa-template/` |
| 4 | Security | Employer names in public repo and history | 4 | `.gitleaks.toml`, commit `6a99306` |
| 5 | Dependency | Black, Ruff, isort unpinned in Python CI but pinned in pre-commit; versions drift | 4 | `python-template/.github/workflows/ci.yml` |
| 6 | Dependency | `multer ^1.4.5-lts.1` is a deprecated 1.x line with known advisories; no code uses it | 4 | `node-spa-template/server/package.json` |
| 7 | Security | Actions pinned to tags (`@v4`, `@v2`), TruffleHog to `@main`; no `permissions:` block | 4 | all workflows |
| 8 | Maintainability | Universality rule is manual; templates already differ (`check-json` missing in Python) | 4 | README "Contributing" |
| 9 | Maintainability | `new-project.sh` has no tests; `LANG` shadows locale; usage heredoc malformed; owner hardcoded | 3 | `new-project.sh:5,17-21,32` |
| 10 | Reliability | Template CI is never exercised; a broken template ships until a user generates a project | 3 | `.github/workflows/ci.yml` |
| 12 | Reliability | TruffleHog pre-commit `args` repeat `git file://.` already in the hook entry; hook errors on every commit, in all 5 configs | 4 | every `.pre-commit-config.yaml` (R-8) |
| 11 | Maintainability | README Releases table lags the v1.0.2 tag | 2 | `README.md` |

## Predicted failure scenarios (score 3 and above)

- **PF-1 (risk 1):** a developer commits an API key in a generated project. Pre-commit may catch
  it; if hooks are skipped (`--no-verify`) or never installed, CI passes green and the key
  ships. Gitleaks and TruffleHog still run in CI, which limits impact, but the third layer is
  decorative. Fails today.
- **PF-2 (risks 2, 3):** the first Python or node-spa project generated after any Dependabot
  or toolchain bump fails its first CI run, and branch protection requires those checks, so
  the owner cannot merge until fixing the template by hand. Fails today.
- **PF-3 (risks 5, 7):** a new Black or Ruff release changes formatting; every generated
  Python repo goes red on its next unrelated PR. A compromised or force-moved Action tag runs
  with the default token. Timeline: next upstream release.
- **PF-4 (risks 8, 10):** the Terraform template is added by copy-paste, one security control is
  omitted, and nothing flags it. Timeline: the next template.
- **PF-5 (risk 9):** a repo name containing `/` or `&` corrupts `sed` substitution mid-run
  after the GitHub repo already exists, leaving a half-seeded remote. Fails on first odd input.

## Test coverage gaps

| Path | Why critical | Test type needed |
|---|---|---|
| `new-project.sh` | Creates remote repos and branch protection | bats with a stubbed `gh`: each language, bad name, `--public` |
| Each template, post-substitution | The product; never built | CI matrix: substitute, then lint, test, build per language |
| Secret-baseline gate | Headline security claim | Negative test: add a fake secret, expect non-zero exit |
| Check-name coupling | Wrong name blocks every merge | Script asserting `new-project.sh` contexts equal CI job names |

## Dependency audit

| Item | State | Action |
|---|---|---|
| `black`, `ruff`, `isort` (Python CI) | Unpinned in CI; pinned in pre-commit | S-2 |
| `yamllint`, `detect-secrets` (root CI) | Unpinned | R-7 |
| `multer`, `better-sqlite3` (node-spa) | Declared, unused; multer 1.x deprecated | R-4 |
| `express ^4`, `concurrently ^9` | Caret ranges; safe only with a lockfile | R-3 |
| Actions | Tags, one `@main` | S-1 |

Run `npm audit` and `pip-audit` inside R-3/R-4 once the lockfile exists; not run in this pass.

## CI/CD gaps

| Check | Root | Templates |
|---|---|---|
| Tests on PR | Shell syntax only | Yes, but never run in Bedrock itself |
| Lint and format | yamllint on templates only | Yes |
| Secret scan | Yes (twice) | Yes |
| Actions pinned | No | No |
| Least-privilege `permissions:` | No | No |
| Scheduled drift run | Dependabot only | Dependabot only |

## Ponytail audit (over-engineering only)

1. delete: `.github/workflows/secret-scan.yml`; `ci.yml` already has the same two scanners. About -25 lines.
2. yagni: `better-sqlite3` and `multer` in node-spa with no code using them. Delete until a route needs them (owner call: the README advertises SQLite).
3. reuse: five copies of `.gitleaks.toml` and four secret-scan blocks. Keep copies (templates must be self-contained) and enforce identity with C-1 rather than a reusable workflow.
4. delete: `# pylint: disable=subprocess-run-check` in `test_secrets.py`; pylint is not used.
5. shrink: `substitute_placeholders` `find | while grep | sed` becomes `grep -rlI PROJECT_NAME . | xargs sed ...`.
6. yagni: `clang` and `clang-tidy` apt installs in the C++ CI; no tidy step runs.
7. yagni: `test_secrets.py` triplicates the pre-commit and CI baseline checks. Replace with one trivial `main()` test after R-2.

net: about -60 lines, -2 deps possible.

## Local CI

`local-ci.sh --list` and `--dry-run` ran against a project-local `.venv` (PyYAML only): 2 runnable
steps (`bash -n`, yamllint), 1 skipped as CI-only (secret baseline). Not yet run for real, no
`--sync`, no hooks installed (H-2 gates those on owner confirmation). Local gitleaks over 17
commits found no leaks; employer terms are rule text, not secrets.

## Not verified

Template builds, `npm audit`, `pip-audit`, `dotnet`, `cmake`, Dependabot config correctness for
C++ and C#, and live branch protection other than the two required checks on `main`.
