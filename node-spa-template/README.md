# REPO_NAME

TODO: Add a one-line description of this project.

---

## Prerequisites

- Node.js ≥ 20
- npm ≥ 10
- [pre-commit](https://pre-commit.com/) (`pip install pre-commit`)
- [gitleaks](https://github.com/gitleaks/gitleaks)

---

## Setup

```bash
git clone git@github.com:incendiary/REPO_NAME.git
cd REPO_NAME
npm install
pre-commit install
npm run dev
```

The Express server runs on `http://localhost:3000`.
The Vite dev server runs on `http://localhost:5173` and proxies `/api` to the Express server.

---

## Project Structure

```
REPO_NAME/
├── server/
│   ├── src/
│   │   └── index.js     # Express entry point
│   └── package.json
├── client/
│   ├── src/
│   │   ├── main.js      # Vue 3 entry point
│   │   └── App.vue      # Root component
│   ├── index.html
│   ├── vite.config.js
│   └── package.json
├── uploads/             # Uploaded files (gitignored)
└── package.json         # Root workspace manifest
```

---

## Development

| Command | Description |
|---------|-------------|
| `npm run dev` | Start server + client in watch mode |
| `npm run build` | Build Vue SPA to `server/public/` |
| `npm run lint` | Run ESLint across `client/src/` |
| `npm run start` | Start production server (requires `npm run build` first) |

---

## Roadmap

| # | Status | Description |
|---|--------|-------------|
| 1 | ✅ Done | Secret scan (gitleaks + TruffleHog + detect-secrets, pre-commit + CI) |
| 2 | ✅ Done | Dependency audit (npm audit, Dependabot) |
| 3 | ⬜ Todo | Code quality pass (ESLint clean, no dead code) |
| 4 | ✅ Done | Tooling (pre-commit hooks, CI pipeline) |
| 5 | ⬜ Todo | Tests (add unit + integration tests) |
| 6 | ⬜ Todo | Documentation (fill in description + usage above) |
| 7 | ✅ Done | Branch protection (force-push blocked, required CI checks on main) |

Status key: ⬜ Todo · 🔄 In Progress · ✅ Done

---

## Releases

| Version | Description |
|---------|-------------|
| v1.0.0  | Public release — all roadmap items complete |

---

## Licence

For personal / authorized use only. No warranty. User assumes all responsibility.
