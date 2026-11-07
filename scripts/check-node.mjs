// scripts/check-node.mjs — run by `npm run check` (L1.1 step 4).
// Checks Node >= 22 (24 LTS recommended), npm, Playwright Chromium, and reachability of
// github.com, packagist.org, registry.npmjs.org and the lab app (LAB_HOST, default 192.168.8.10:8080).
import { existsSync } from 'node:fs';

const rows = [];
let fail = 0;
const row = (result, check, found, hint = '') => {
  if (result === 'FAIL') fail++;
  rows.push(`${check.padEnd(26)} ${result.padEnd(5)} ${String(found).slice(0, 24).padEnd(24)} ${hint}`);
};

const major = Number(process.versions.node.split('.')[0]);
if (major >= 24) row('PASS', 'Node.js LTS', process.versions.node);
else if (major >= 22) row('PASS', 'Node.js LTS', process.versions.node, '(24 LTS recommended)');
else row('FAIL', 'Node.js LTS', process.versions.node, 'Install Node 24 LTS (guide 3)');

const ua = process.env.npm_config_user_agent ?? '';
const npmVersion = (ua.match(/npm\/([\d.]+)/) ?? [])[1];
npmVersion ? row('PASS', 'npm', npmVersion) : row('WARN', 'npm', 'not detected', 'Run via: npm run check');

try {
  const { chromium } = await import('@playwright/test');
  const exe = chromium.executablePath();
  existsSync(exe) ? row('PASS', 'Playwright Chromium', 'installed') : row('FAIL', 'Playwright Chromium', 'missing', 'npx playwright install chromium');
} catch {
  row('FAIL', 'Playwright Chromium', 'package missing', 'npm ci first');
}

const reach = async (name, url, required) => {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(8000), redirect: 'manual' });
    res.status < 400 ? row('PASS', name, `HTTP ${res.status}`) : row(required ? 'FAIL' : 'WARN', name, `HTTP ${res.status}`, 'Proxy/filter? tell the trainer');
  } catch {
    row(required ? 'FAIL' : 'WARN', name, 'no connection', required ? 'Network blocks it - tell the trainer' : 'Only on Wi-Fi opshub-lab (Day 1)');
  }
};
await reach('Reach github.com', 'https://github.com', true);
await reach('Reach packagist.org', 'https://repo.packagist.org/packages.json', true);
await reach('Reach registry.npmjs.org', 'https://registry.npmjs.org/', true);
const lab = process.env.LAB_HOST ?? '192.168.8.10:8080';
await reach(`Lab app ${lab}`, `http://${lab}/api/v1/health`, false);

console.log(rows.join('\n'));
console.log(fail === 0 ? 'npm run check: PASS' : `npm run check: ${fail} FAIL(S)`);
process.exit(fail === 0 ? 0 : 1);
