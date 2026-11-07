<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{{ config('app.name', 'setup-check') }}</title>
        <style>
            body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 3rem auto; padding: 0 1rem; line-height: 1.5; }
            code { background: #f2f2f2; padding: 0 .25rem; }
        </style>
    </head>
    <body>
        <h1>setup-check</h1>
        <p>If you can read this, PHP {{ PHP_VERSION }} and Laravel {{ app()->version() }} run on your laptop.</p>
        <p>Next: <code>php artisan test</code> and <code>npm test</code> (guide L1.1 step 5).</p>
        <p><small>Training data — fictional.</small></p>
    </body>
</html>
