# Bedrock

Project templates plus `new-project.sh`, which creates a GitHub repo and seeds it from one of
four templates (`python-template`, `csharp-template`, `cpp-template`, `node-spa-template`).
Every template ships the same security baseline: gitleaks, TruffleHog and detect-secrets,
language formatters, CI, Dependabot and branch protection.

## Layout

- `new-project.sh`: generator. Needs `gh` authenticated; substitutes `PROJECT_NAME` / `REPO_NAME`.
- `<lang>-template/`: files copied verbatim into a new repo. Treat them as product, not scaffolding.
- `.github/workflows/`, `.pre-commit-config.yaml`, `.gitleaks.toml`: Bedrock's own gates.
- `ROADMAP.md`: ordered work items for agents. `REVIEW.md`: the findings behind them.

## Rules

- **Universality rule:** any security or tooling change lands in all templates and in the root
  config in the same PR (see README "Contributing"). Do not change one template alone.
- Template files are copied into other repos: no personal, employer, or client names, no
  absolute paths, no real secrets. Treat everything here as public.
- Do not hand-edit `.secrets.baseline`; regenerate with `detect-secrets scan`.
- Pin tool versions explicitly (`pip install black==X.Y.Z`, Action SHAs), never floating.
- One PR per roadmap item. Conventional commit titles (`fix(python): ...`).
- Never rewrite git history or force-push without the owner's explicit instruction.
- Do not run `new-project.sh` for real: it creates GitHub repos. Test with a stubbed `gh`.

## Verify before pushing

Use a project-local venv (`.venv/`, git-excluded). Do not install anything system-wide.

```bash
bash local-ci.sh --list       # which workflow steps are runnable locally (skill: local-ci)
bash -n new-project.sh && shellcheck new-project.sh
pre-commit run --all-files
```

Steps marked CI-only (secrets, GitHub context) are unverified until CI runs. Say so in the PR.

## Adding or changing a template

1. Edit the template and mirror the change across the others (or record why not).
2. Update the README template table and Releases table.
3. Add the template's required check names to the branch-protection `case` in `new-project.sh`.
