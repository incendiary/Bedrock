# PROJECT_NAME

> **TODO:** Replace this line with a one-paragraph description of what this project does and why.

---

## Setup

```bash
# Clone and enter
git clone git@github.com:incendiary/PROJECT_NAME.git
cd PROJECT_NAME

# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

### Requirements
- CMake 3.20+
- C++17-capable compiler (GCC 9+, Clang 10+, MSVC 2019+)
- [pre-commit](https://pre-commit.com/)
- clang-format (for pre-commit hook)
- [gitleaks](https://github.com/gitleaks/gitleaks) (installed via pre-commit)

---

## Usage

```bash
# TODO: add usage examples
./build/PROJECT_NAME --help
```

---

## Development

```bash
# Format code
clang-format -i src/**/*.cpp src/**/*.h

# Check formatting without modifying
clang-format --dry-run --Werror src/**/*.cpp src/**/*.h

# Build with tests
cmake -B build -DBUILD_TESTS=ON
cmake --build build
ctest --test-dir build --output-on-failure

# Run all pre-commit hooks manually
pre-commit run --all-files
```

---

## Roadmap

| # | Status | Description |
|---|--------|-------------|
| [#1](../../issues/1) | ✅ Done | Secret scan — gitleaks + TruffleHog + detect-secrets (pre-commit + CI) |
| [#2](../../issues/2) | ✅ Done | Dependency audit — Dependabot (Actions, weekly) |
| [#3](../../issues/3) | ⬜ Todo | Code quality pass — dead code, duplication, memory safety |
| [#4](../../issues/4) | ✅ Done | Tooling — clang-format, clang-tidy, pre-commit, CI pipeline |
| [#5](../../issues/5) | ⬜ Todo | Tests — add unit/integration test coverage (Google Test / Catch2) |
| [#6](../../issues/6) | ⬜ Todo | Documentation — fill in description + usage above |
| [#7](../../issues/7) | ✅ Done | Branch protection — force-push blocked, required CI checks on main |

Status key: ⬜ Todo · 🔄 In Progress · ✅ Done

---

## Releases

| Version | Description |
|---------|-------------|
| v1.0.0  | Public release — all roadmap items complete |

---

## License

This project is licensed under the [Prosperity Public License 4.0.0](LICENSE). See the LICENSE file for details.

---

> This project was uplifted for public release with the assistance of Claude (Anthropic).
> Things should work, but some paths may not have been fully re-tested. PRs and fixes welcome.
