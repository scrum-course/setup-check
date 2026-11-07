# BUILD-SPEC: `setup-check` (public)

Course plan §6.1, §6.5, §11.1 (4 h); gate: exists 8 Nov, smoke-tested and **sent 9 Nov** (Batch 1), dry run on a clean Windows + Herd laptop and on macOS (§11 item 2). Day 1 L1.1.

## In this scaffold (✔ = done)
✔ `check.sh` (macOS/Linux, bash 3.2 compatible) · ✔ `check.ps1` (Windows PowerShell 5.1 and 7) · ✔ `scripts/check-php.php` (`composer check`) · ✔ `scripts/check-node.mjs` (`npm run check`) · ✔ `composer.json`/`package.json` fragments with the `check` scripts · ✔ `.devcontainer/devcontainer.json` · ✔ `.github/` (CI matrix on Windows, macOS, Ubuntu; issue forms incl. *Setup problem*) · ✔ `README.md`

## To build next round
1. `laravel new` (current Laravel 12, **no starter kit**, Pest) in this repo; merge the `check` script into the generated `composer.json` and `package.json` (keep `@playwright/test` and `vitest` dev dependencies; pin to the versions current at build).
2. One Pest test `tests/Feature/SetupTest.php`: `it('boots', fn () => $this->get('/up')->assertOk());` (Laravel's built-in health route) — SQLite in memory in `phpunit.xml`. `phpunit.xml` also sets a fixed **test-only** `APP_KEY` (`<env name="APP_KEY" value="base64:…"/>`, generated once at build, used for nothing else) so `php artisan test` runs straight after `composer install` without `.env` or `key:generate` (guide L1.1 step 5, participant guide §9).
   The current `composer.json` is a **fragment**: `laravel/framework`, `pestphp/pest`, `pestphp/pest-plugin-laravel` and the `artisan` file arrive with `laravel new` in this step; the 9 Nov send date depends on it.
3. One Vitest test `tests/js/setup.test.js`: `expect(1 + 1).toBe(2)` plus importing `@playwright/test` to prove the package resolves.
4. `.env.example`: `DB_CONNECTION=sqlite`, no secrets.
5. Run CI green on all three runners; then the human dry runs (clean Windows + Herd; macOS; a Codespace) — record timings in `labs/environment/readiness-gates.md`.

## Check list and thresholds (keep the four scripts consistent)

| Check | PASS | WARN | FAIL |
|---|---|---|---|
| Git | ≥ 2.30 | older | missing |
| PHP | 8.3.x | 8.4+/8.5 | other / missing |
| Extensions `pdo_sqlite pdo_pgsql intl mbstring zip curl openssl fileinfo` | loaded | — | missing |
| Composer | ≥ 2.7 | — | older / missing |
| Node | ≥ 24, or ≥ 22 (with note) | — | < 22 / missing |
| npm | present | — | missing |
| Playwright Chromium | browser folder present | — | missing |
| VS Code `code` CLI, Chrome/Edge | present | missing | — |
| github.com, api.github.com, packagist, npm registry | 2xx/3xx | — | other / no connection |
| `git ls-remote` of this repo | ok | — | failed |
| GitHub account name (optional flag) | 200 | API 403/429 | 404 |
| GitHub 2FA (only if `gh` is logged in) | `two_factor_authentication=true` | not checked | false |
| Lab app `192.168.8.10:8080/api/v1/health` | reachable | not reachable (expected off site) | — (never fails) |
| Free disk | ≥ 5 GB | less | — |

Exit code 1 if any FAIL.
