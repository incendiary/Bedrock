#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_USER="incendiary"

usage() {
    echo "Usage: $0 <language> <repo-name> [--public]"
    echo ""
    echo "  language   python | csharp | cpp"
    echo "  repo-name  name for the new GitHub repository"
    echo "  --public   create as public repo (default: private)"
    echo ""
    echo "Examples:"
    echo "  $0 python my-new-tool"
    echo "  $0 csharp SharpLoader"
    echo "  $0 cpp exploit-helper --public"
    exit 1
}

[[ $# -lt 2 ]] && usage

LANG="$1"
REPO_NAME="$2"
VISIBILITY="--private"

[[ "${3:-}" == "--public" ]] && VISIBILITY="--public"

case "$LANG" in
    python)   TEMPLATE_DIR="$SCRIPT_DIR/python-template" ;;
    csharp)   TEMPLATE_DIR="$SCRIPT_DIR/csharp-template" ;;
    cpp)      TEMPLATE_DIR="$SCRIPT_DIR/cpp-template" ;;
    *)        echo "Unknown language: $LANG"; usage ;;
esac

# Cross-platform in-place sed (BSD on macOS, GNU on Linux)
sed_i() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Replace PROJECT_NAME and REPO_NAME tokens in all text files under cwd
substitute_placeholders() {
    local name="$1"
    # grep -I skips binary files
    find . -type f ! -path './.git/*' \
        | while read -r file; do
            if grep -qI "PROJECT_NAME\|REPO_NAME" "$file" 2>/dev/null; then
                sed_i "s/PROJECT_NAME/$name/g; s/REPO_NAME/$name/g" "$file"
            fi
        done

    # Rename any files whose name contains PROJECT_NAME (e.g. .csproj, .sln)
    find . -name "*PROJECT_NAME*" ! -path './.git/*' \
        | while read -r file; do
            mv "$file" "${file//PROJECT_NAME/$name}"
        done
}

echo "==> Creating GitHub repo: $GITHUB_USER/$REPO_NAME ($VISIBILITY)"
gh repo create "$GITHUB_USER/$REPO_NAME" $VISIBILITY

echo "==> Cloning into $(pwd)/$REPO_NAME"
gh repo clone "$GITHUB_USER/$REPO_NAME" "$REPO_NAME"

cd "$REPO_NAME"

echo "==> Seeding from $LANG template"
cp -r "$TEMPLATE_DIR/." .

echo "==> Substituting PROJECT_NAME → $REPO_NAME"
substitute_placeholders "$REPO_NAME"

echo "==> Setting up git"
git add -A
git commit -m "chore: initialise from $LANG template"
git push origin main

echo "==> Setting default branch to main"
gh repo edit "$GITHUB_USER/$REPO_NAME" --default-branch main

echo "==> Enabling branch protection on main"
case "$LANG" in
    python)  REQUIRED_CHECKS='["Secret Scan","Lint","Test"]' ;;
    csharp)  REQUIRED_CHECKS='["Secret Scan","Build & Test"]' ;;
    cpp)     REQUIRED_CHECKS='["Secret Scan","Build & Test"]' ;;
esac

gh api "repos/$GITHUB_USER/$REPO_NAME/branches/main/protection" \
  --method PUT \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": $REQUIRED_CHECKS
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo ""
echo "Done. Next steps:"
echo "  cd $REPO_NAME"
case "$LANG" in
    python)
        echo "  python -m venv .venv && source .venv/bin/activate"
        echo "  pip install -e '.[dev]'"
        echo "  pre-commit install"
        echo "  # Regenerate secrets baseline after adding project code:"
        echo "  # detect-secrets scan > .secrets.baseline && git add .secrets.baseline"
        ;;
    csharp)
        echo "  dotnet restore"
        echo "  pip install pre-commit detect-secrets && pre-commit install"
        ;;
    cpp)
        echo "  cmake -B build -DCMAKE_BUILD_TYPE=Release"
        echo "  pip install pre-commit detect-secrets && pre-commit install"
        ;;
esac
echo ""
echo "  Then drop your code into src/ and update README.md + CLAUDE.md context fields."
echo "  Open in Claude Code — CLAUDE.md loads automatically to start the audit."
