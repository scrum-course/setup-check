<?php

// The one Pest test of setup-check (BUILD-SPEC step 2): Laravel boots and answers its
// built-in health route. No .env needed: phpunit.xml carries a test-only APP_KEY and
// SQLite :memory:.

it('boots', fn () => $this->get('/up')->assertOk());
