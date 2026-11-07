// The one Vitest test of setup-check (BUILD-SPEC step 3): Vitest runs, and the
// @playwright/test package resolves (the browser itself is checked by `npm run check`).
import { expect, test } from 'vitest';
import * as playwright from '@playwright/test';

test('toolchain works', () => {
  expect(1 + 1).toBe(2);
  expect(typeof playwright.chromium.launch).toBe('function');
});
