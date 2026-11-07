// Separate from vite.config.js so the Laravel Vite plugin is not loaded for tests.
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        include: ['tests/js/**/*.test.js'],
        environment: 'node',
    },
});
