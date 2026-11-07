# BUILD-NOTES — setup-check (build round 2)

## What was built
The "next round" of `BUILD-SPEC.md`: a Laravel 12 app with no starter kit, one Pest test and one Vitest test, merged into the existing scaffold. The scaffold's working `check.sh`, `check.ps1`, `scripts/check-php.php` and `scripts/check-node.mjs` are unchanged (byte for byte, same line endings).

| BUILD-SPEC item | Files |
|---|---|
| 1. `laravel new` (Laravel 12, no starter kit, Pest), `check` scripts merged | `artisan`, `bootstrap/app.php` (health route `/up`), `bootstrap/providers.php`, `bootstrap/cache/`, `config/app.php`, `config/database.php` (other config = framework defaults, Laravel 11+ merge), `app/Http/Controllers/Controller.php`, `app/Models/User.php`, `app/Providers/AppServiceProvider.php`, `database/{migrations,factories,seeders}/`, `public/{index.php,.htaccess,robots.txt}`, `resources/{views/welcome.blade.php,css/app.css,js/app.js}`, `routes/{web,console}.php`, `storage/**/.gitignore`, `vite.config.js`; `composer.json` (`laravel/framework ^12.0`, `pestphp/pest ^3.7`, `pestphp/pest-plugin-laravel ^3.1`, `check` + `test` scripts), `package.json` (`check`, `test` = `vitest --run`; `@playwright/test 1.54.2`, `vitest 3.2.4`, `vite ^6.2.4`, `laravel-vite-plugin ^1.2.0`) |
| 2. One Pest test, SQLite `:memory:`, test-only `APP_KEY` | `tests/Feature/SetupTest.php` (`it('boots', fn () => $this->get('/up')->assertOk());`), `tests/Pest.php`, `tests/TestCase.php`, `phpunit.xml` (only the `Feature` suite, so the count is exactly 1; fixed `APP_KEY` generated once for this repo, marked test-only) |
| 3. One Vitest test importing `@playwright/test` | `tests/js/setup.test.js`, `vitest.config.js` (separate from `vite.config.js` so the Laravel plugin is not loaded in tests) |
| 4. `.env.example`: `DB_CONNECTION=sqlite`, no secrets | `.env.example` (also `SESSION_DRIVER=file`, `CACHE_STORE=file`, `QUEUE_CONNECTION=sync`, so `php artisan serve` works without running migrations) |
| 5. CI green on three runners, human dry runs | **not done here** (see below) |

Other changes:
- `.github/workflows/ci.yml`: `npm install` instead of `npm ci` and no `cache: npm` (both need a lock file that could not be generated here); the last step now runs `php artisan test` **without** `.env` or `key:generate` (`test ! -f .env` first), which is exactly what guide L1.1 step 5 and participant guide §9 promise.
- `.devcontainer/devcontainer.json`: `npm install` instead of `npm ci` (same reason).
- `README.md`: a "For the trainer" section with the first-push steps. `BUILD-SPEC.md`: a "Built" block above the original list.
- Version bump: the scaffold pinned `vitest 2.1.8` / `@playwright/test 1.49.1`; the spec says "pin to the versions current at build", and Vitest 3.2 supports Vite 6 directly (2.1 would nest its own Vite 5). Re-pin both to the newest releases on the first push if you like; nothing else depends on the exact numbers (`check.sh`/`check.ps1` look for any `chromium-*` browser folder).

Guide cross-check (L1.1, participant guide §9): `composer install` → `composer check` → `npm ci` → `npm run check` → `php artisan test` (`Tests: 1 passed`) → `npm test` (`1 passed`) all exist. `npm ci` works once `package-lock.json` is committed (first push). Branches/tags: none required by the spec or `labs/NAMES.md`; only `main`.

## Verified here
- `php -l` on all 18 PHP files: clean (PHP 8.3.6). `node --check` on `vite.config.js`, `vitest.config.js`, `tests/js/setup.test.js`, `scripts/check-node.mjs`: clean. `composer.json`, `package.json`, `devcontainer.json` parse; `ci.yml` and issue forms parse as YAML; `phpunit.xml` is well-formed XML; `bash -n check.sh` clean.

## NOT verified here (no Packagist / npm access)
- `composer install`, `php artisan test`, `npm install`, `npm test`, `npm run build` were never run. The skeleton follows the Laravel 12 `laravel/laravel` layout, but the first real run is the first push's CI.
- Exact package versions resolve as written (`@playwright/test 1.54.2`, `vitest 3.2.4`).
- `check.ps1` on PowerShell 5.1/7 and the Windows/macOS runners.

## First push (trainer, on a machine with internet)
```bash
cd setup-check
composer update --no-interaction --prefer-dist     # writes composer.lock
npm install                                        # writes package-lock.json
php artisan test                                   # expect: Tests: 1 passed  (no .env present)
npm test                                           # expect: 1 passed
git add composer.lock package-lock.json && git commit -m "Add lock files"
git remote add origin git@github.com:scrum-course/setup-check.git
git push -u origin main
```
Then wait for CI green on ubuntu/windows/macos, optionally switch CI back to `npm ci` + `cache: npm`, and do the human dry runs (clean Windows + Herd, macOS, a Codespace) and record the timings in `labs/environment/readiness-gates.md` (gate: sent 9 Nov).
