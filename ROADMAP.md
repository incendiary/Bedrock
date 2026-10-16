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
- [x] **H-2: Install local-ci hooks.** Done 2026-10-13 (pre-commit and pre-push installed in the owner's checkout; reinstalled after the skill rename). Effort XS.
  `bash local-ci.sh --sync`, review the toolchain-versus-CI table, then
  `bash local-ci.sh --install-hook pre-commit` and, once P-1 is decided, `--install-hook pre-push`. Run `pre-commit install` first
  so gitleaks stays live; local-ci chains existing hooks.

## Phase 1: defects (ship first)

- [x] **R-1: Fix Python build backend.** (merged, PR #29). Haiku. XS. Files: `python-template/pyproject.toml`.
  Change line 3 `build-backend = "setuptools.backends.legacy:build"` to `build-backend = "setuptools.build_meta"`.
  Verify: in a scratch dir `python -m venv .v && .v/bin/pip install -e ".[dev]"` from a copy of the template
  (replace `PROJECT_NAME` with `demo` first; the package dir is `src`, so add
  `[tool.setuptools] packages = ["src"]` only if the install errors on discovery) exits 0, then `.v/bin/pytest` passes.
- [x] **R-2: Make the secret-baseline gate fail on new secrets.** (merged, PR #26). Sonnet. S.
  Files: root `.github/workflows/ci.yml`; `python|csharp|cpp|iac-template/.github/workflows/ci.yml`;
  `python-template/tests/test_secrets.py`.
  Problem: `detect-secrets scan --baseline F` rewrites F and exits 0. Replace each CI step body with
  `pip install detect-secrets==1.5.0` then
  `git ls-files -z | xargs -0 detect-secrets-hook --baseline .secrets.baseline`
  (this exits non-zero on a new secret). node-spa has no such step: add the same step to its `lint` job.
  In `test_secrets.py`, call `detect_secrets` via `detect-secrets-hook` the same way, or delete the test and
  add `tests/test_main.py` asserting `main()` runs (pytest exits 5 with no tests, so one test must remain).
  Verify (negative test, in a scratch copy): add a file containing the AWS documentation example access key (look it up in the AWS docs; do not paste it into any tracked file), `git add` it,
  run the command; expect non-zero. Remove it; expect zero. Paste both exit codes.
- [x] **R-3: Commit a lockfile for node-spa.** (merged, PR #24). Sonnet. S. Files: `node-spa-template/package-lock.json` (new).
  In a scratch copy run `npm install --package-lock-only` at `node-spa-template/` (workspaces: one root lockfile).
  Copy the lockfile back. Verify: `npm ci && npm run lint && npm run build` succeeds in a clean copy;
  `npm audit --omit=dev` output pasted. Do not edit `package.json` versions here.
- [x] **R-4: Replace deprecated multer.** (merged, PR #30). Sonnet. XS. Needs: R-3. Files: `node-spa-template/server/package.json`, lockfile.
  Owner question first: if SQLite and uploads are not wanted by default, delete `multer` and `better-sqlite3`
  instead (ponytail finding 2). Default if no answer: bump to `multer` 2.x only; keep `better-sqlite3`.
  Verify: `npm ci && npm audit --omit=dev` shows no multer advisories; `node server/src/index.js` starts and
  `curl localhost:3000/api/health` returns `{"status":"ok",...}`.
- [x] **R-5: Harden `new-project.sh`.** (merged, PR #23). Sonnet. S. Files: `new-project.sh` only.
  (a) rename `LANG` to `TEMPLATE_LANG` everywhere; (b) fix the usage heredoc (lines 17-21: the `cpp` example
  swallows the next lines in one string; make each example its own `echo`); (c) `GITHUB_USER="${BEDROCK_GITHUB_USER:-incendiary}"`;
  (d) reject names not matching `^[A-Za-z0-9._-]+$` before any `gh` call; (e) set `-- ` and quote `$VISIBILITY` correctly.
  Verify: `bash -n new-project.sh && shellcheck new-project.sh`; `./new-project.sh python 'bad/name'` exits 1
  with a message and makes no network call (run with `PATH` stripped of `gh` to prove it); `./new-project.sh` prints clean usage.
- [x] **R-6: Remove the duplicate secret-scan workflow.** (merged, PR #28). Haiku. XS. Files: delete `.github/workflows/secret-scan.yml`.
  First confirm `ci.yml` `secret-scan` job exists (it does). Verify: `grep -c trufflehog .github/workflows/*.yml`;
  branch protection requires `Secret Scan`, which `ci.yml` provides. Note in PR that the check name is unchanged.
- [x] **R-7: Lint root workflows and pin lint tools.** (merged, PR #36). Haiku. XS. Files: root `.github/workflows/ci.yml`.
  Add `.github/workflows/ci.yml` to the yamllint file list; change `pip install --quiet yamllint` to
  `pip install --quiet yamllint==1.35.1` (check latest with `pip index versions yamllint`; use that exact version).
  Verify: `pip install yamllint==<v> && yamllint -d relaxed .github/workflows/ci.yml` exits 0.
- [x] **R-8: Fix the TruffleHog pre-commit hook args.** (merged, PR #27). Haiku. XS. Files: `.pre-commit-config.yaml` and the five
  `*-template/.pre-commit-config.yaml` (python, csharp, cpp, node-spa, iac). The upstream hook `entry` already is `trufflehog git file://. --since-commit HEAD ...`,
  so our `args: ["git", "file://.", ...]` duplicates the subcommand and the hook dies with "unexpected git" on every commit.
  Change `args` to `["--no-update"]` (the entry supplies `--results=verified` and `--fail`; repeating `--results` errors). Landed this way. Do not edit anything else.
  Verify: `pre-commit run trufflehog --all-files` exits 0 on a clean tree (needs `trufflehog` 3.x on PATH; if missing, say so).

## Phase 2: supply chain

- [x] **S-1: Pin all Actions to commit SHAs.** (merged, PR #37). Sonnet. M. Files: every `ci.yml` (root plus the five templates, including `iac-template`; `hashicorp/setup-terraform` too).
  For each `uses: owner/repo@tag`, resolve the SHA with
  `gh api repos/OWNER/REPO/commits/TAG --jq .sha` and write `uses: owner/repo@<sha> # TAG`.
  Replace `trufflehog@main` (removed by R-6 at root) with `@v3.95.2`'s SHA. Dependabot already updates Actions.
  Needs: R-6. Verify: `grep -rn "uses:" --include=*.yml . | grep -vE "@[0-9a-f]{40}"` returns nothing.
- [x] **S-2: Pin Black, Ruff, isort in Python CI.** (merged, PR #34). Haiku. XS. Files: `python-template/.github/workflows/ci.yml`.
  Change `pip install black ruff isort` to `pip install black==25.1.0 ruff==0.11.9 isort==6.0.1`
  (match `python-template/.pre-commit-config.yaml` revs; if those change, change both). Also pin in `pyproject.toml` `dev` extras
  with `==`. Verify: `grep -n "pip install" python-template/.github/workflows/ci.yml` shows only pinned lint tools.
- [x] **S-3: Least-privilege token.** (merged, PR #35). Haiku. XS. PR 20 added `permissions: contents: read` and `pull-requests: read` to the template
  workflows. Remaining: confirm all five template `ci.yml` and the root `ci.yml` carry the same block (root and any template
  missing it get it); do not add anything broader. Verify: `grep -L "permissions:" .github/workflows/*.yml */.github/workflows/ci.yml`
  prints nothing.

## Phase 3: consistency and tests

- [x] **C-1: Template conformance check.** (merged, PR #32). Sonnet. M. Files: `scripts/check-conformance.py` (new), root `ci.yml`, README Contributing.
  Python stdlib plus PyYAML only. Assert, for every `*-template/` (five, including `iac-template`): `.gitleaks.toml` byte-identical across templates;
  `.pre-commit-config.yaml` contains gitleaks, trufflehog, detect-secrets, no-commit-to-branch with identical `rev`s;
  `ci.yml` has a job named `Secret Scan` using the same gitleaks and trufflehog steps; `dependabot.yml` includes `github-actions` (and `terraform` for `iac-template`);
  every check name in `new-project.sh` `REQUIRED_CHECKS` for a language equals a job `name:` in that template's `ci.yml`.
  Exit non-zero listing every violation. Add a root CI step running it. Verify: passes on `main`; temporarily bump one
  `rev` in one template and confirm it fails with a clear message (revert it).
  Known existing violations to fix or allowlist with a comment: Python lacks `check-json`.
- [x] **T-1: Test `new-project.sh` with a stubbed `gh`.** (merged, PR #33). Sonnet. M. Needs: R-5. Files: `tests/new-project.bats`, `tests/stub/gh`, root `ci.yml`.
  The stub `gh` is a shell script first on `PATH` that logs its arguments to a file; for `repo clone` it runs
  `git init -b main` in the target directory and sets `origin` to a local bare repo created in the test.
  Cases: each of four languages produces expected files and no leftover `PROJECT_NAME`; `--public` passes `--public`;
  protection payload contains the right check names; bad name exits 1 before any `gh` call.
  Install bats via `brew`-free route: `git clone --depth 1 --branch v1.11.0 https://github.com/bats-core/bats-core` into `.git/` scratch;
  in CI use `npm i -g bats@1.11.0` or the pinned action SHA. Verify: `bats tests/` green locally.
- [ ] **T-2: Build every template in CI.** (PR open; done when merged and green). Sonnet. M. Needs: R-1, R-2, R-3, T-1. Files: root `ci.yml`.
  Matrix job: copy the template to a temp dir, `sed` `PROJECT_NAME`, `git init`, run that template's own lint, test, build
  (Python: pip install, black, ruff, pytest; C#: dotnet format, build, test; C++: cmake, ctest; node: npm ci, lint, build).
  Verify: job green for all four; deliberately break one template locally and confirm the matrix leg fails.

## Phase 4: new template

- [x] **N-1: Terraform template.** Landed as `iac-template/` (commit `caa7539`, PR 19) with `iac` in `new-project.sh`
  (required checks `Secret Scan`, `Validate`). Follow-ups are folded into R-2, R-8, S-1, S-2 and C-1 below. Known by design:
  Checkov runs advisory (`--soft-fail`) because these repos may host deliberately vulnerable infrastructure; do not "fix" that.

## Phase 4b: drift found after the review (new on `main`)

- [x] **P-1: Fix and keep `pre-push-validation.sh` (owner confirms).** (merged, PR #39). Sonnet. S. Files: `pre-push-validation.sh` (root) and the
  identical copy in each of the five templates; `new-project.sh` (the `read -p` block near the end). Recommendation: keep it, because
  generated repos do not have the owner's local-ci skill, so this is the only shippable pre-push gate. Confirmed defects:
  (1) `new-project.sh` runs `bash pre-push-validation.sh --install-hook`, but the script takes `--dry-run` from `$1` and `--install-hook` from `$2`,
  so the install branch never runs and the checks run instead: parse each flag from any position (`for a in "$@"`).
  (2) `install_hook` overwrites any existing `.git/hooks/pre-push` (`cat >`), destroying a pre-commit-framework or local-ci hook: if a non-ours
  hook exists, move it to `pre-push.prev` and have ours run it first, and refuse to run twice (marker line).
  (3) `detect_tech_stack` is dead except in `--dry-run`, and `[[ -f "$REPO_ROOT/*.csproj" ]]` never matches (quoted glob): delete the function
  and replace `--dry-run` with a one-line listing of the checks that apply.
  (4) `read -p` in `new-project.sh` hangs non-interactive runs: guard with `[ -t 0 ]`.
  Bash 3.2 compatible (no mapfile, readarray, associative arrays; the owner runs macOS /bin/bash 3.2). Keep it byte-identical across the six copies (C-1 asserts this).
  Verify: in a scratch repo `bash pre-push-validation.sh --install-hook` creates `.git/hooks/pre-push`; with a pre-existing hook the old hook still
  runs first; `bash pre-push-validation.sh --dry-run` prints without running checks; `bash -n` and `shellcheck` clean; run under `/bin/bash`.
- [x] **P-2: Default every template to PolyForm Noncommercial 1.0.0.** (merged, PR #31). Sonnet. S. Decision made by owner: use the
  text at https://github.com/incendiary/Chorus/blob/main/LICENSE (PolyForm Noncommercial 1.0.0, unmodified except the
  `Required Notice:` line). Replaces the Prosperity Public License from `0e3c8af`.
  Files: `LICENSE` in `python-template`, `csharp-template`, `cpp-template`, `node-spa-template`, `iac-template` (iac has none today);
  `python-template/pyproject.toml` (`license = { text = "MIT" }` contradicts the file: use `license = { file = "LICENSE" }`);
  `node-spa-template/package.json` and the two `client`/`server` package.json files (`"license": "SEE LICENSE IN LICENSE"`);
  `csharp-template/src/PROJECT_NAME.csproj` (`<PackageLicenseFile>` only if packable, otherwise skip); template READMEs (one line).
  Each `LICENSE` is this header, a blank line, then the Chorus licence body byte-for-byte (everything after its `Required Notice:` line):

      PolyForm Noncommercial License 1.0.0

      Required Notice: Copyright 2026 incendiary (https://github.com/incendiary/PROJECT_NAME)

      Commercial use needs a paid licence: open an issue titled "Commercial licence" at
      https://github.com/incendiary/PROJECT_NAME/issues. Maintainers of open-source projects can ask for a free licence the same way.

  Drop the email address (public file) and keep the literal `PROJECT_NAME` so `new-project.sh` substitutes it. The header is
  plain text outside the PolyForm terms; do not edit the licence body. No separate commercial file (owner decision) Do not edit any other licence wording.
  Bedrock's own root `LICENSE` was added after the owner confirmed (same PolyForm Noncommercial text) -- originally: do not add one.
  Verify: `diff <(sed 1,3d python-template/LICENSE) <(sed 1,3d csharp-template/LICENSE)` empty for all five; `grep -ril prosperity .`
  returns nothing; `grep -rn "MIT" python-template/pyproject.toml` returns nothing; C-1 asserts the five LICENSE files match.

- [x] **D-3: Fix the template CLAUDE.md audit prompts.** (PR open; iac CI still installs checkov unpinned, see note). Sonnet. S. Files: `CLAUDE.md` in each of the five templates. Group into one PR.
  Found in `python-template/CLAUDE.md`, check the other four for the same: Step 3 says `pip install black ruff isort pre-commit detect-secrets`
  (unpinned; use the versions in that template's `.pre-commit-config.yaml` and `pyproject.toml`); Step 5 shows a branch-protection call with
  `contexts: ["ci"]` and one required review, which disagrees with `new-project.sh` (language-specific contexts, no required reviews, strict true):
  replace it with a pointer to what `new-project.sh` already configures, or copy the exact contexts for that language. Keep each file under 150 lines.
  Verify: `grep -n "pip install" */CLAUDE.md` shows no unpinned tool; every `contexts` value equals `REQUIRED_CHECKS` for that language in `new-project.sh`.

## Phase 5: documentation and release

- [x] **D-1: Sync README.** (PR open). Haiku. XS. Do last in each batch. Files: `README.md`.
  Add v1.0.2 (and later versions) to Releases, add `terraform` to template table and examples once N-1 lands, point Contributing at
  `scripts/check-conformance.py`. Verify: every `git tag` appears in the Releases table.
- [ ] **D-2: Release v1.1.0.** Human, `github-release-workflow` skill. XS. Needs: Phases 1 to 4 merged.

## Out of scope for now

Reusable cross-repo workflows (would couple generated projects to this repo; C-1 achieves consistency instead).
Further languages beyond Terraform until C-1 and T-2 are green.

## Delivery map

One PR per item. Grouped only where files overlap or the change is one logical sweep (D-3 across five templates; S-2 and S-3 were
separate PRs). Merge `ci.yml` PRs one at a time and update each branch from `main` first (branch protection requires up to date); the
`ci.yml` PRs most likely to conflict are #32, #33, #34, #35, #36 and #37.

| Item | PR | State |
|---|---|---|
| R-1 to R-6, R-8 | #29, #26, #24, #30, #23, #28, #27 | Merged |
| P-2 licence, C-1, T-1, S-2, S-3, R-7, S-1, P-1 | #31, #32, #33, #34, #35, #36, #37, #39 | Merged |
| Node-spa required check names (found by C-1) | #40 | Merged |
| T-2 | #41 | Merged |
| D-3 | #42 | Merged |
| D-1 | open PR | Open |
| D-2 | none yet | Not started |

## Outside this repo (ci-local skill)

- The local-ci hooks print "0 steps executed" at commit time inside git worktrees, and the pre-push installer fails with
  `mkdir: .git: Not a directory` there (`.git` is a file in a worktree). Pushes still succeed. Fix in the skill, not here.
- The skill was renamed from `local-ci` to `ci-local`; hooks installed earlier pointed at the old path and blocked every push until reinstalled
  (`bash ~/.claude/skills/ci-local/local-ci.sh --install-hook pre-push`). The hook should resolve the script path at run time, not bake it in.

Note from D-3: `iac-template/.github/workflows/ci.yml` still runs `pip install checkov` unpinned (the docs now say `checkov==3.3.29`); pin it in the next CI sweep.

Gap found during D-1: `scripts/check-conformance.py` does not compare the five `LICENSE` files, although P-2 says it should. Add that assertion when next touching C-1.
