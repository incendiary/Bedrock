#!/bin/bash
# Pre-push gate: runs the commands CI runs (read from .github/workflows/ci.yml) before you push.
# Read-only: skips installs, sudo, secrets and GitHub-only steps; a missing local tool is a warning, a failing step blocks.
# Full-featured version (version parity, auto-fix, --sync): the ci-local skill, https://github.com/incendiary/grimoire
# Usage: bash pre-push-validation.sh [--install-hook]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ "${1:-}" = "--install-hook" ]; then
  hook="$(git rev-parse --git-path hooks/pre-push)"
  mkdir -p "$(dirname "$hook")"
  if [ -f "$hook" ] && ! grep -q "pre-push-validation" "$hook"; then mv "$hook" "$hook.prev"; fi
  cat > "$hook" <<'HOOK'
#!/bin/bash
# pre-push-validation: runs any previous hook first, then the CI-derived checks
prev="$(dirname "$0")/pre-push.prev"
if [ -x "$prev" ]; then "$prev" "$@" || exit $?; fi
exec bash "$(git rev-parse --show-toplevel)/pre-push-validation.sh"
HOOK
  chmod +x "$hook"
  echo "pre-push hook installed: $hook (bypass once with git push --no-verify)"
  exit 0
fi

python3 - <<'PY'
import re, subprocess, sys
try:
    import yaml
except ImportError:
    sys.exit("PyYAML missing: pip install pyyaml (inside your venv). Push not gated.")
skip_step = re.compile(r"\$\{\{|gh |sudo |apt-get")
skip_line = re.compile(r"^\s*((python3? -m )?pip install\b|npm (ci|install)\b|dotnet restore\b|sudo\b|apt-get\b)")
ran = 0
for job in yaml.safe_load(open(".github/workflows/ci.yml"))["jobs"].values():
    for step in job.get("steps", []):
        run = step.get("run")
        if not run or skip_step.search(run):
            continue
        script = "\n".join(l for l in run.splitlines() if not skip_line.match(l))
        if not script.strip():
            continue
        print("==> %s / %s" % (job.get("name", "job"), step.get("name", script.splitlines()[0][:60])))
        rc = subprocess.run(["bash", "-e", "-c", script]).returncode
        if rc == 127:
            print("    skipped: tool not installed locally")
        elif rc:
            sys.exit("FAILED (exit %d): fix before pushing, or git push --no-verify" % rc)
        ran += 1
print("%d CI step(s) passed locally. CI-only steps (secret scanners, installs) are not covered." % ran)
PY
