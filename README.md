# setup-check (public)

Run this **one week before the course**. It checks that your laptop has everything the labs need and prints a PASS / WARN / FAIL table. It installs nothing and changes nothing.

Full step-by-step guide for Windows, macOS and Linux: **`labs/participant-setup/README.md`** (sent with the invitation e-mail as a PDF/web page).

## 1. Get it
```bash
git clone https://github.com/scrum-course/setup-check
cd setup-check
```

## 2. Run the check
| Your laptop | Command |
|---|---|
| Windows | `powershell -ExecutionPolicy Bypass -File .\check.ps1 -GitHubUser <your-github-name> -Offsite` |
| macOS / Linux | `./check.sh --github-user <your-github-name> --offsite` |

(`-Offsite` / `--offsite` is for checking at home. On Day 1, run it again without it, on Wi-Fi `opshub-lab`.)

## 3. Run the two tiny tests
```bash
composer install
composer check          # PHP 8.3, extensions, Composer
npm ci
npx playwright install chromium     # once; it downloads a browser (~150 MB)
npm run check           # Node, Playwright, network
php artisan test        # 1 Pest test (no .env needed; phpunit.xml carries a test-only key)
npm test                # 1 Vitest test
```

## 4. Send the result
Reply to the invitation e-mail with a screenshot of the table (or open an issue with the *Setup problem* form). Anything red that the guide does not fix: we fix it in the first 30 minutes of Day 1, or you use the **Codespaces fallback** (guide §8) — **stop your codespace when you finish**.

Used in: pre-course (sent 9 Nov for Batch 1, 23 Nov for Batch 2) and Day 1 lab L1.1.
