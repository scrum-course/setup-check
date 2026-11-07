<?php
// scripts/check-php.php — run by `composer check` (L1.1 step 3).
// Checks PHP 8.3, the extensions the course needs, and Composer >= 2.7.
// Exit 1 if any check fails. Output: one table row per check.
$rows = [];
$fail = 0;
$row = function (string $result, string $check, string $found, string $hint = '') use (&$rows, &$fail) {
    if ($result === 'FAIL') {
        $fail++;
    }
    $rows[] = sprintf("%-24s %-5s %-24s %s", $check, $result, substr($found, 0, 24), $hint);
};

$v = PHP_VERSION;
if (version_compare($v, '8.3.0', '>=') && version_compare($v, '8.4.0', '<')) {
    $row('PASS', 'PHP 8.3', $v);
} elseif (version_compare($v, '8.4.0', '>=')) {
    $row('WARN', 'PHP 8.3', $v, 'Course uses 8.3; switch version (guide 4)');
} else {
    $row('FAIL', 'PHP 8.3', $v, 'Install PHP 8.3 (guide 4)');
}

foreach (['pdo_sqlite', 'pdo_pgsql', 'intl', 'mbstring', 'zip', 'curl', 'openssl', 'fileinfo'] as $ext) {
    extension_loaded($ext)
        ? $row('PASS', "ext $ext", 'loaded')
        : $row('FAIL', "ext $ext", 'missing', "Enable $ext in php.ini: " . (php_ini_loaded_file() ?: 'no php.ini loaded'));
}

// Composer exposes its own path to scripts through COMPOSER_BINARY.
$composer = getenv('COMPOSER_BINARY');
$out = $composer ? shell_exec(escapeshellarg(PHP_BINARY) . ' ' . escapeshellarg($composer) . ' --version 2>&1') : null;
if ($out && preg_match('/(\d+\.\d+\.\d+)/', $out, $m)) {
    version_compare($m[1], '2.7.0', '>=')
        ? $row('PASS', 'Composer >= 2.7', $m[1])
        : $row('FAIL', 'Composer >= 2.7', $m[1], 'composer self-update');
} else {
    $row('WARN', 'Composer >= 2.7', 'not detected', 'Run via: composer check');
}

echo implode(PHP_EOL, $rows), PHP_EOL;
echo $fail === 0 ? "composer check: PASS\n" : "composer check: $fail FAIL(S)\n";
exit($fail === 0 ? 0 : 1);
