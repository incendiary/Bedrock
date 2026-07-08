#!/bin/bash
# Pre-push validation: runs checks before allowing push to remote
# Exit code: 0 = all checks pass, 1 = first failure stops execution

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
DRY_RUN=${1:-}
INSTALL_HOOK=${2:-}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_pass() { echo -e "${GREEN}✓${NC} $1"; }
log_fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
log_info() { echo -e "${YELLOW}→${NC} $1"; }

# Detect project type
detect_tech_stack() {
  local has_node=0 has_python=0 has_go=0 has_rust=0 has_csharp=0 has_bash=0
  
  [[ -f "$REPO_ROOT/package.json" ]] && has_node=1
  [[ -f "$REPO_ROOT/pyproject.toml" || -f "$REPO_ROOT/requirements.txt" ]] && has_python=1
  [[ -f "$REPO_ROOT/go.mod" ]] && has_go=1
  [[ -f "$REPO_ROOT/Cargo.toml" ]] && has_rust=1
  [[ -f "$REPO_ROOT/*.csproj" ]] && has_csharp=1
  [[ -f "$REPO_ROOT/new-project.sh" ]] && has_bash=1
  
  echo "$has_node $has_python $has_go $has_rust $has_csharp $has_bash"
}

# Run checks
run_checks() {
  local failed=0
  
  # Shell: shellcheck
  if command -v shellcheck &>/dev/null && [[ -f "$REPO_ROOT/new-project.sh" ]]; then
    log_info "Running shellcheck on shell scripts..."
    if shellcheck "$REPO_ROOT/new-project.sh" 2>&1; then
      log_pass "shellcheck"
    else
      log_fail "shellcheck failed"
    fi
  fi
  
  # Python: black, ruff
  if [[ -f "$REPO_ROOT/pyproject.toml" ]]; then
    log_info "Running Python checks..."
    if command -v black &>/dev/null; then
      if black --check . 2>&1 | tail -1; then
        log_pass "black"
      else
        log_fail "black formatting issues found"
      fi
    fi
    if command -v ruff &>/dev/null; then
      if ruff check . 2>&1 | tail -1; then
        log_pass "ruff"
      else
        log_fail "ruff linting issues found"
      fi
    fi
  fi
  
  # Node: eslint, prettier
  if [[ -f "$REPO_ROOT/package.json" ]]; then
    log_info "Running Node checks..."
    if command -v npm &>/dev/null; then
      if npm run lint 2>&1 | tail -3; then
        log_pass "npm lint"
      else
        log_fail "npm lint failed"
      fi
    fi
  fi
  
  log_pass "All checks passed"
}

# Install git hook
install_hook() {
  local hook_path="$REPO_ROOT/.git/hooks/pre-push"
  mkdir -p "$REPO_ROOT/.git/hooks"
  cat > "$hook_path" << 'HOOK'
#!/bin/bash
# Auto-generated pre-push hook
REPO_ROOT="$(git rev-parse --show-toplevel)"
bash "$REPO_ROOT/pre-push-validation.sh"
HOOK
  chmod +x "$hook_path"
  log_pass "Pre-push hook installed"
}

# Main
if [[ "$DRY_RUN" == "--dry-run" ]]; then
  log_info "Dry run mode - showing what would be checked..."
  log_info "Tech stack detection..."
  detect_tech_stack
elif [[ "$INSTALL_HOOK" == "--install-hook" ]]; then
  install_hook
else
  run_checks
fi
