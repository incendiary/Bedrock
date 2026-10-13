# Bedrock roadmap

Findings are in `REVIEW.md`. Each item is written so an agent with no other context can do it.

## How to run an item (every agent)

1. Read `CLAUDE.md`, then only your item. Do not read other items.
2. `git switch -c <branch>` from fresh `main`. One item, one branch, one PR.
3. Change only the files listed. If you need another file, stop and report why.
4. Run the **Verify** commands. Paste their output in the PR. If a command cannot run
   (missing tool, CI-only), say so; never write "passes" for something you did not run.
5. Use a project-local `.venv`. Never install anything system-wide. Never run `new-project.sh` for real.
6. Commit as `type(scope): summary`. Open the PR. Do not merge. Do not force-push.
7. If a Verify step fails twice, stop and report the output. Do not widen scope to make it pass.

**Agent tiers.** Haiku: mechanical edits with exact before/after. Sonnet: standard changes, needs
judgement within the listed files. Opus: security design or anything touching history. Human:
needs the owner (irreversible or outward-facing).

**Order.** Phase 0, then Phase 1 (items are independent unless `Needs:` says otherwise), then 2 to 5.
Items in the same phase touch disjoint files except where noted; do not run two agents on one file.

Effort: XS under 15 min, S under 1 h, M half a day, L a day.

---

## Phase 0: human-gated (owner decisions made; agents prepare, owner executes)

- [x] **H-1: Remove employer rules and wipe history.** Done 2026-10-13 by targeted `git filter-repo` rewrite (not a full wipe).
  The four employer rules and the file title were stripped from `.gitleaks.toml` in every commit; all other content is unchanged.
  `main`, `docs/review-roadmap` and all six tags were force-pushed; branch protection was restored; releases and PR 21 survived.
  Residual: hidden `refs/pull/19/head` and `refs/pull/20/head` still reach the old commits. Open a GitHub Support request to purge
  cached views and run garbage collection (owner action), or record as accepted risk. Other clones and forks keep the old history.
  Owner keeps employer-term rules in a private global gitleaks config, not in any repo.
- [ ] **H-2: Install local-ci hooks.** Human confirms. Effort XS.
  `bash local-ci.sh --sync`, review the toolchain-versus-CI table, then
  `bash local-ci.sh --install-hook pre-commit` and `--install-hook pre-push`. Run `pre-commit install` first
  so gitleaks stays live; local-ci chains existing hooks.

## Phase 1: defects (ship first)

- [ ] **R-1: Fix Python build backend.** Haiku. XS. Files: `python-template/pyproject.toml`.
  Change line 3 `build-backend = "setuptools.backends.legacy:build"` to `build-backend = "setuptools.build_meta"`.
  Verify: in a scratch dir `python -m venv .v && .v/bin/pip install -e ".[dev]"` from a copy of the template
  (replace `PROJECT_NAME` with `demo` first; the package dir is `src`, so add
  `[tool.setuptools] packages = ["src"]` only if the install errors on discovery) exits 0, then `.v/bin/pytest` passes.
- [ ] **R-2: Make the secret-baseline gate fail on new secrets.** Sonnet. S.
  Files: root `.github/workflows/ci.yml`; `python|csharp|cpp-template/.github/workflows/ci.yml`;
  `python-template/tests/test_secrets.py`.
  Problem: `detect-secrets scan --baseline F` rewrites F and exits 0. Replace each CI step body with
  `pip install detect-secrets==1.5.0` then
  `git ls-files -z | xargs -0 detect-secrets-hook --baseline .secrets.baseline`
  (this exits non-zero on a new secret). node-spa has no such step: add the same step to its `lint` job.
  In `test_secrets.py`, call `detect_secrets` via `detect-secrets-hook` the same way, or delete the test and
  add `tests/test_main.py` asserting `main()` runs (pytest exits 5 with no tests, so one test must remain).
  Verify (negative test, in a scratch copy): add a file containing the AWS documentation example access key (look it up in the AWS docs; do not paste it into any tracked file), `git add` it,
  run the command; expect non-zero. Remove it; expect zero. Paste both exit codes.
- [ ] **R-3: Commit a lockfile for node-spa.** Sonnet. S. Files: `node-spa-template/package-lock.json` (new).
  In a scratch copy run `npm install --package-lock-only` at `node-spa-template/` (workspaces: one root lockfile).
  Copy the lockfile back. Verify: `npm ci && npm run lint && npm run build` succeeds in a clean copy;
  `npm audit --omit=dev` output pasted. Do not edit `package.json` versions here.
- [ ] **R-4: Replace deprecated multer.** Sonnet. XS. Needs: R-3. Files: `node-spa-template/server/package.json`, lockfile.
  Owner question first: if SQLite and uploads are not wanted by default, delete `multer` and `better-sqlite3`
  instead (ponytail finding 2). Default if no answer: bump to `multer` 2.x only; keep `better-sqlite3`.
  Verify: `npm ci && npm audit --omit=dev` shows no multer advisories; `node server/src/index.js` starts and
  `curl localhost:3000/api/health` returns `{"status":"ok",...}`.
- [ ] **R-5: Harden `new-project.sh`.** Sonnet. S. Files: `new-project.sh` only.
  (a) rename `LANG` to `TEMPLATE_LANG` everywhere; (b) fix the usage heredoc (lines 17-21: the `cpp` example
  swallows the next lines in one string; make each example its own `echo`); (c) `GITHUB_USER="${BEDROCK_GITHUB_USER:-incendiary}"`;
  (d) reject names not matching `^[A-Za-z0-9._-]+$` before any `gh` call; (e) set `-- ` and quote `$VISIBILITY` correctly.
  Verify: `bash -n new-project.sh && shellcheck new-project.sh`; `./new-project.sh python 'bad/name'` exits 1
  with a message and makes no network call (run with `PATH` stripped of `gh` to prove it); `./new-project.sh` prints clean usage.
- [ ] **R-6: Remove the duplicate secret-scan workflow.** Haiku. XS. Files: delete `.github/workflows/secret-scan.yml`.
  First confirm `ci.yml` `secret-scan` job exists (it does). Verify: `grep -c trufflehog .github/workflows/*.yml`;
  branch protection requires `Secret Scan`, which `ci.yml` provides. Note in PR that the check name is unchanged.
- [ ] **R-7: Lint root workflows and pin lint tools.** Haiku. XS. Files: root `.github/workflows/ci.yml`.
  Add `.github/workflows/ci.yml` to the yamllint file list; change `pip install --quiet yamllint` to
  `pip install --quiet yamllint==1.35.1` (check latest with `pip index versions yamllint`; use that exact version).
  Verify: `pip install yamllint==<v> && yamllint -d relaxed .github/workflows/ci.yml` exits 0.
- [ ] **R-8: Fix the TruffleHog pre-commit hook args.** Haiku. XS. Files: `.pre-commit-config.yaml` and the four
  `*-template/.pre-commit-config.yaml`. The upstream hook `entry` already is `trufflehog git file://. --since-commit HEAD ...`,
  so our `args: ["git", "file://.", ...]` duplicates the subcommand and the hook dies with "unexpected git" on every commit.
  Change `args` to `["--results=verified,unknown", "--no-update"]` (the entry supplies `--fail`). Do not edit anything else.
  Verify: `pre-commit run trufflehog --all-files` exits 0 on a clean tree (needs `trufflehog` 3.x on PATH; if missing, say so).

## Phase 2: supply chain

- [ ] **S-1: Pin all Actions to commit SHAs.** Sonnet. M. Files: all 6 workflow files (root 1, templates 4, plus none else).
  For each `uses: owner/repo@tag`, resolve the SHA with
  `gh api repos/OWNER/REPO/commits/TAG --jq .sha` and write `uses: owner/repo@<sha> # TAG`.
  Replace `trufflehog@main` (removed by R-6 at root) with `@v3.95.2`'s SHA. Dependabot already updates Actions.
  Needs: R-6. Verify: `grep -rn "uses:" --include=*.yml . | grep -vE "@[0-9a-f]{40}"` returns nothing.
- [ ] **S-2: Pin Black, Ruff, isort in Python CI.** Haiku. XS. Files: `python-template/.github/workflows/ci.yml`.
  Change `pip install black ruff isort` to `pip install black==25.1.0 ruff==0.11.9 isort==6.0.1`
  (match `python-template/.pre-commit-config.yaml` revs; if those change, change both). Also pin in `pyproject.toml` `dev` extras
  with `==`. Verify: `grep -n "pip install" python-template/.github/workflows/ci.yml` shows only pinned lint tools.
- [ ] **S-3: Least-privilege token.** Haiku. XS. Files: all 5 `ci.yml`. Add under `on:`:
  `permissions:\n  contents: read`. Exception: the gitleaks-action step may need `pull-requests: read`; add that at
  job level on `secret-scan` only. Verify: `yamllint` on each file; first CI run green.

## Phase 3: consistency and tests

- [ ] **C-1: Template conformance check.** Sonnet. M. Files: `scripts/check-conformance.py` (new), root `ci.yml`, README Contributing.
  Python stdlib plus PyYAML only. Assert, for every `*-template/`: `.gitleaks.toml` byte-identical across templates;
  `.pre-commit-config.yaml` contains gitleaks, trufflehog, detect-secrets, no-commit-to-branch with identical `rev`s;
  `ci.yml` has a job named `Secret Scan` using the same gitleaks and trufflehog steps; `dependabot.yml` includes `github-actions`;
  every check name in `new-project.sh` `REQUIRED_CHECKS` for a language equals a job `name:` in that template's `ci.yml`.
  Exit non-zero listing every violation. Add a root CI step running it. Verify: passes on `main`; temporarily bump one
  `rev` in one template and confirm it fails with a clear message (revert it).
  Known existing violations to fix or allowlist with a comment: Python lacks `check-json`.
- [ ] **T-1: Test `new-project.sh` with a stubbed `gh`.** Sonnet. M. Needs: R-5. Files: `tests/new-project.bats`, `tests/stub/gh`, root `ci.yml`.
  The stub `gh` is a shell script first on `PATH` that logs its arguments to a file; for `repo clone` it runs
  `git init -b main` in the target directory and sets `origin` to a local bare repo created in the test.
  Cases: each of four languages produces expected files and no leftover `PROJECT_NAME`; `--public` passes `--public`;
  protection payload contains the right check names; bad name exits 1 before any `gh` call.
  Install bats via `brew`-free route: `git clone --depth 1 --branch v1.11.0 https://github.com/bats-core/bats-core` into `.git/` scratch;
  in CI use `npm i -g bats@1.11.0` or the pinned action SHA. Verify: `bats tests/` green locally.
- [ ] **T-2: Build every template in CI.** Sonnet. M. Needs: R-1, R-2, R-3, T-1. Files: root `ci.yml`.
  Matrix job: copy the template to a temp dir, `sed` `PROJECT_NAME`, `git init`, run that template's own lint, test, build
  (Python: pip install, black, ruff, pytest; C#: dotnet format, build, test; C++: cmake, ctest; node: npm ci, lint, build).
  Verify: job green for all four; deliberately break one template locally and confirm the matrix leg fails.

## Phase 4: new template

- [ ] **N-1: Terraform template.** Sonnet implements; Opus reviews the security controls. L. Needs: C-1, T-2.
  Files: `terraform-template/` (new: `.gitignore`, `.gitleaks.toml` (copy), `.secrets.baseline`, `.pre-commit-config.yaml`,
  `.github/workflows/ci.yml`, `.github/dependabot.yml` with `terraform` and `github-actions`, `CLAUDE.md`, `README.md`,
  `.tflint.hcl`, `versions.tf`, `main.tf`, `variables.tf`, `outputs.tf`), `new-project.sh`, root `README.md`, C-1 and T-1 tests.
  Rules: copy the secret-scan job and the three secret layers exactly from the Python template. Add `terraform fmt -check`,
  `terraform validate` (with `init -backend=false`), `tflint`, and `checkov` (or `trivy config`), all pinned to explicit versions.
  `.gitignore` must exclude `*.tfstate*`, `.terraform/`, `*.tfvars` (keep `*.tfvars.example`). No provider credentials anywhere;
  `main.tf` is a harmless no-op (a `terraform_data` resource or `null` output). Job names: `Secret Scan`, `Terraform`.
  Add `terraform)` branches to every `case` in `new-project.sh`. Use the `terraform-checkov-skips` and `terraform-version-compat`
  skills; any checkov skip needs a one-line justification comment. Verify: C-1 and T-2 pass including the new template.

## Phase 5: documentation and release

- [ ] **D-1: Sync README.** Haiku. XS. Do last in each batch. Files: `README.md`.
  Add v1.0.2 (and later versions) to Releases, add `terraform` to template table and examples once N-1 lands, point Contributing at
  `scripts/check-conformance.py`. Verify: every `git tag` appears in the Releases table.
- [ ] **D-2: Release v1.1.0.** Human, `github-release-workflow` skill. XS. Needs: Phases 1 to 4 merged.

## Out of scope for now

Reusable cross-repo workflows (would couple generated projects to this repo; C-1 achieves consistency instead).
Further languages beyond Terraform until C-1 and T-2 are green.
