#!/usr/bin/env bats
# new-project.sh against a stubbed gh. Never touches real GitHub.

setup() {
    # git hooks export GIT_DIR etc.; they would redirect the stub's git calls at the real repo
    unset $(compgen -e | grep '^GIT_')
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export GH_STUB_LOG="$BATS_TEST_TMPDIR/gh.log"
    export GH_STUB_ORIGIN="$BATS_TEST_TMPDIR/origin.git"
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
    : > "$GH_STUB_LOG"
    git init -q --bare -b main "$GH_STUB_ORIGIN"
    export PATH="$REPO_ROOT/tests/stub:$PATH"
    WORK="$BATS_TEST_TMPDIR/work"
    mkdir "$WORK"
    cd "$WORK"
}

# required checks for a language, read from the script itself
required_checks() {
    sed -n "s/^ *$1) *REQUIRED_CHECKS='\(.*\)' *;;.*/\1/p" "$REPO_ROOT/new-project.sh"
}

run_np() {
    run bash "$REPO_ROOT/new-project.sh" "$@" <<< "n"
}

check_lang() {
    local lang="$1" marker="$2"
    run_np "$lang" demo-proj
    [ "$status" -eq 0 ]
    [ -e "demo-proj/$marker" ]
    [ -e demo-proj/README.md ]
    [ -e demo-proj/.pre-commit-config.yaml ]
    run grep -rIl --exclude-dir=.git -e PROJECT_NAME -e REPO_NAME demo-proj
    [ -z "$output" ]
    [ -z "$(find demo-proj -name '*PROJECT_NAME*' -not -path '*/.git/*')" ]
    grep -q "^api repos/.*/demo-proj/branches/main/protection" "$GH_STUB_LOG"
    local checks
    checks="$(required_checks "$lang")"
    [ -n "$checks" ]
    grep -qF "\"contexts\": $checks" "$GH_STUB_LOG"
}

@test "python" { check_lang python pyproject.toml; }
@test "csharp" { check_lang csharp demo-proj.sln; }
@test "cpp" { check_lang cpp CMakeLists.txt; }
@test "node-spa" { check_lang node-spa package.json; }
@test "iac" { check_lang iac main.tf; }

@test "--public is passed to gh repo create" {
    run_np python demo-proj --public
    [ "$status" -eq 0 ]
    grep -q "^repo create .* --public" "$GH_STUB_LOG"
}

@test "default visibility is private" {
    run_np python demo-proj
    grep -q "^repo create .* --private" "$GH_STUB_LOG"
}

@test "bad repo name exits 1 before any gh call" {
    run_np python bad/name
    [ "$status" -eq 1 ]
    [ ! -s "$GH_STUB_LOG" ]
}

@test "unknown language exits 1" {
    run_np cobol demo-proj
    [ "$status" -eq 1 ]
    [ ! -s "$GH_STUB_LOG" ]
}
