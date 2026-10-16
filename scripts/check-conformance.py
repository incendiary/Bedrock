#!/usr/bin/env python3
"""Assert the security baseline is identical across all templates.

Stdlib plus PyYAML. Prints every violation and exits 1 if any.
Run from anywhere: paths resolve relative to the repo root (or argv[1]).
"""

import re
import sys
from pathlib import Path

import yaml

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
TEMPLATES = {
    "python": "python-template",
    "csharp": "csharp-template",
    "cpp": "cpp-template",
    "node-spa": "node-spa-template",
    "iac": "iac-template",
}
PRE_COMMIT_REPOS = {
    "gitleaks": "gitleaks/gitleaks",
    "trufflehog": "trufflesecurity/trufflehog",
    "detect-secrets": "Yelp/detect-secrets",  # pragma: allowlist secret
    "no-commit-to-branch": "pre-commit/pre-commit-hooks",
}
# Hook ids every template must run, except where allowlisted below.
REQUIRED_HOOK_IDS = ["gitleaks", "trufflehog", "detect-secrets", "no-commit-to-branch", "check-json"]
HOOK_ALLOWLIST = {
    # python-template has no JSON files by default, so it omits check-json.
    ("python", "check-json"),
    # Real gap, tracked here so the gate lands; remove when iac-template gains check-json.
    ("iac", "check-json"),
}
PRE_PUSH = [ROOT / "pre-push-validation.sh"] + [
    ROOT / d / "pre-push-validation.sh" for d in TEMPLATES.values()
]

violations = []


def fail(msg):
    violations.append(msg)


def load_yaml(path):
    try:
        return yaml.safe_load(path.read_text())
    except (OSError, yaml.YAMLError) as e:
        fail(f"{path.relative_to(ROOT)}: cannot parse ({e})")
        return None


def all_equal(label, values):
    """values: {template: value}. Report once if they differ."""
    if len({repr(v) for v in values.values()}) > 1:
        fail(f"{label} differs: " + "; ".join(f"{k}={v!r}" for k, v in values.items()))


def check_identical_files(label, paths):
    contents = {str(p.relative_to(ROOT)): p.read_bytes() if p.exists() else None for p in paths}
    for name, data in contents.items():
        if data is None:
            fail(f"{label}: {name} missing")
    present = {n: d for n, d in contents.items() if d is not None}
    if len(set(present.values())) > 1:
        ref_name, ref = next(iter(present.items()))
        for n, d in present.items():
            if d != ref:
                fail(f"{label}: {n} differs from {ref_name}")


# .gitleaks.toml and pre-push-validation.sh: byte-identical
check_identical_files(".gitleaks.toml", [ROOT / d / ".gitleaks.toml" for d in TEMPLATES.values()])
# iac-template ships no pre-push-validation.sh: five copies are root plus four templates.
check_identical_files("pre-push-validation.sh", PRE_PUSH)

# LICENSE: the five templates are byte-identical, and the root is the same text with the project name filled in
check_identical_files("LICENSE", [ROOT / d / "LICENSE" for d in TEMPLATES.values()])
root_licence, template_licence = ROOT / "LICENSE", ROOT / "python-template" / "LICENSE"
if not root_licence.exists():
    fail("LICENSE: root LICENSE missing")
elif template_licence.exists() and root_licence.read_text() != template_licence.read_text().replace("PROJECT_NAME", "Bedrock"):
    fail("LICENSE: root LICENSE differs from the template text with PROJECT_NAME replaced by Bedrock")

# pre-commit
revs = {k: {} for k in PRE_COMMIT_REPOS}
th_args = {}
for lang, d in TEMPLATES.items():
    cfg = load_yaml(ROOT / d / ".pre-commit-config.yaml")
    if not cfg:
        continue
    ids_seen = set()
    for repo in cfg.get("repos", []):
        url = repo.get("repo", "")
        for hook in repo.get("hooks", []):
            ids_seen.add(hook["id"])
            if hook["id"] in PRE_COMMIT_REPOS and PRE_COMMIT_REPOS[hook["id"]] in url:
                revs[hook["id"]][lang] = repo.get("rev")
            if hook["id"] == "trufflehog":
                th_args[lang] = hook.get("args")
    for hid in REQUIRED_HOOK_IDS:
        if hid not in ids_seen and (lang, hid) not in HOOK_ALLOWLIST:
            fail(f"{d}/.pre-commit-config.yaml: hook '{hid}' missing")
for hid, by_lang in revs.items():
    all_equal(f"pre-commit rev for {hid}", by_lang)
all_equal("pre-commit trufflehog args", th_args)

# ci.yml
jobs_by_lang = {}
secret_steps = {}
for lang, d in TEMPLATES.items():
    wf = load_yaml(ROOT / d / ".github/workflows/ci.yml")
    jobs = (wf or {}).get("jobs", {})
    jobs_by_lang[lang] = {j.get("name") for j in jobs.values()}
    scan = [j for j in jobs.values() if j.get("name") == "Secret Scan"]
    if not scan:
        fail(f"{d}/.github/workflows/ci.yml: no job named 'Secret Scan'")
    else:
        secret_steps[lang] = scan[0].get("steps")
all_equal("Secret Scan job steps", secret_steps)

# dependabot
for lang, d in TEMPLATES.items():
    cfg = load_yaml(ROOT / d / ".github/dependabot.yml")
    ecos = {u.get("package-ecosystem") for u in (cfg or {}).get("updates", [])}
    for eco in ["github-actions"] + (["terraform"] if lang == "iac" else []):
        if eco not in ecos:
            fail(f"{d}/.github/dependabot.yml: ecosystem '{eco}' missing")

# new-project.sh REQUIRED_CHECKS vs job names
script = (ROOT / "new-project.sh").read_text()
for m in re.finditer(r"^\s*([\w-]+)\)\s+REQUIRED_CHECKS='(\[.*?\])'", script, re.M):
    lang, checks = m.group(1), yaml.safe_load(m.group(2))
    if lang not in TEMPLATES:
        fail(f"new-project.sh: REQUIRED_CHECKS for unknown language '{lang}'")
        continue
    for c in checks:
        if c not in jobs_by_lang[lang]:
            fail(f"new-project.sh: {lang} required check '{c}' is not a job name in "
                 f"{TEMPLATES[lang]}/ci.yml (jobs: {sorted(n for n in jobs_by_lang[lang] if n)})")

if violations:
    print(f"{len(violations)} conformance violation(s):")
    for v in violations:
        print(f"  - {v}")
    sys.exit(1)
print("Template conformance: OK")
