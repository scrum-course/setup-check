<?php

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
| Feature tests run on Laravel's TestCase, so `$this->get('/up')` works.
*/

pest()->extend(Tests\TestCase::class)->in('Feature');
