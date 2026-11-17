<#
  setup-check/check.ps1 — pre-course toolchain check for Windows (PowerShell 5.1 or 7).
  Prints a PASS / WARN / FAIL table and exits 1 if anything FAILS.

    .\check.ps1
    .\check.ps1 -GitHubUser <name>     # also confirms your GitHub account name exists
    .\check.ps1 -Offsite               # LAN check reported as SKIP (use at home, before Day 1)

  If scripts are blocked:  powershell -ExecutionPolicy Bypass -File .\check.ps1
  Nothing is installed or changed; the script only reads versions and makes HTTPS requests.
#>
[CmdletBinding()]
param(
  [string]$GitHubUser = "",
  [switch]$Offsite,
  [string]$LabHost = "192.168.8.10"
)

$ErrorActionPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:Fails = 0
$script:Warns = 0

function Row([string]$Result, [string]$Check, [string]$Found, [string]$Hint) {
  $colour = "Green"
  if ($Result -eq "WARN") { $colour = "Yellow"; $script:Warns++ }
  if ($Result -eq "FAIL") { $colour = "Red"; $script:Fails++ }
  if ($Result -eq "SKIP") { $colour = "Gray" }
  if ($Found.Length -gt 28) { $Found = $Found.Substring(0, 28) }
  Write-Host ("{0,-26} " -f $Check) -NoNewline
  Write-Host ("{0,-5} " -f $Result) -ForegroundColor $colour -NoNewline
  Write-Host ("{0,-28} {1}" -f $Found, $Hint)
}
function Have([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function FirstVersion([string]$Text) {
  $m = [regex]::Match($Text, '\d+\.\d+(\.\d+)?')
  if ($m.Success) { return $m.Value } else { return "0.0.0" }
}
function VerGe([string]$A, [string]$B) {
  try { return ([version](FirstVersion $A)) -ge ([version](FirstVersion $B)) } catch { return $false }
}
function HttpStatus([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8 -Method Get
    return [int]$r.StatusCode
  } catch {
    if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
    return 0
  }
}
function HttpOk([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8 -Method Get
    return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400)
  } catch { return $false }
}

Write-Host "Airport Ops Hub course - setup check  ($([Environment]::OSVersion.VersionString), $(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
Write-Host ("{0,-26} {1,-5} {2,-28} {3}" -f "CHECK", "RESULT", "FOUND", "WHAT TO DO IF NOT PASS")
Write-Host ("-" * 90)

# --- Git ---
if (Have git) {
  $v = FirstVersion (git --version)
  if (VerGe $v "2.30") { Row PASS "Git" $v "" } else { Row WARN "Git" $v "Update Git (guide 2)" }
} else { Row FAIL "Git" "not found" "Install Git (guide 2)" }

# --- PHP 8.3 + extensions ---
if (Have php) {
  $v = (php -r "echo PHP_VERSION;")
  if ($v -like "8.3.*") { Row PASS "PHP 8.3" $v "" }
  elseif ($v -like "8.4.*" -or $v -like "8.5.*") { Row WARN "PHP 8.3" $v "Course uses 8.3; switch PHP version in Herd (guide 4)" }
  else { Row FAIL "PHP 8.3" "$v" "Install PHP 8.3 via Laravel Herd (guide 4)" }
  $mods = (php -m) | ForEach-Object { $_.Trim().ToLower() }
  foreach ($ext in @("pdo_sqlite", "pdo_pgsql", "intl", "mbstring", "zip", "curl", "openssl", "fileinfo")) {
    if ($mods -contains $ext) { Row PASS "  ext $ext" "loaded" "" } else { Row FAIL "  ext $ext" "missing" "Enable $ext in php.ini (guide 4.4)" }
  }
} else { Row FAIL "PHP 8.3" "not found" "Install Laravel Herd (guide 4)" }

# --- Composer >= 2.7 ---
if (Have composer) {
  $v = FirstVersion (composer --version 2>$null | Out-String)
  if (VerGe $v "2.7") { Row PASS "Composer >= 2.7" $v "" } else { Row FAIL "Composer >= 2.7" $v "composer self-update (guide 4)" }
} else { Row FAIL "Composer >= 2.7" "not found" "Herd includes Composer (guide 4)" }

# --- Node >= 22 (24 recommended), npm ---
if (Have node) {
  $v = FirstVersion (node --version)
  if (VerGe $v "24.0") { Row PASS "Node.js LTS" $v "" }
  elseif (VerGe $v "22.0") { Row PASS "Node.js LTS" $v "(24 LTS recommended; 22 is fine)" }
  else { Row FAIL "Node.js LTS" $v "Install Node 24 LTS (guide 3)" }
} else { Row FAIL "Node.js LTS" "not found" "Install Node 24 LTS (guide 3)" }
if (Have npm) { Row PASS "npm" (npm --version) "" } else { Row FAIL "npm" "not found" "Comes with Node (guide 3)" }

# --- Playwright Chromium ---
$pwRoots = @()
if ($env:PLAYWRIGHT_BROWSERS_PATH) { $pwRoots += $env:PLAYWRIGHT_BROWSERS_PATH }
$pwRoots += (Join-Path $env:LOCALAPPDATA "ms-playwright")
$pw = $null
foreach ($root in $pwRoots) {
  $hit = Get-ChildItem -Path $root -Directory -Filter "chromium-*" -ErrorAction SilentlyContinue | Select-Object -Last 1
  if ($hit) { $pw = $hit.Name }
}
if ($pw) { Row PASS "Playwright Chromium" $pw "" } else { Row FAIL "Playwright Chromium" "not found" "In this folder: npx playwright install chromium" }

# --- Editor and browser (warnings only) ---
if (Have code) { Row PASS "VS Code (code CLI)" ((code --version | Select-Object -First 1)) "" }
else { Row WARN "VS Code (code CLI)" "not on PATH" "Install VS Code (guide 2); reopen PowerShell" }
$browsers = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
)
$found = $browsers | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($found) { Row PASS "Chrome or Edge" (Split-Path $found -Leaf) "" } else { Row WARN "Chrome or Edge" "not detected" "Install Chrome or Edge (guide 6)" }

# --- Network ---
foreach ($u in @("https://github.com", "https://api.github.com", "https://repo.packagist.org/packages.json", "https://registry.npmjs.org/")) {
  $name = "Reach " + ($u -replace '^https://', '' -replace '/.*$', '')
  $code = HttpStatus $u
  if ($code -ge 200 -and $code -lt 400) { Row PASS $name "HTTPS ok" "" }
  elseif ($code -eq 0) { Row FAIL $name "no connection" "Network/proxy blocks it - tell the trainer" }
  else { Row FAIL $name "HTTP $code" "Proxy or filter answers instead - tell the trainer" }
}

# --- GitHub ---
if ((Have git) -and ((git ls-remote https://github.com/scrum-course/setup-check HEAD 2>$null) -ne $null)) {
  Row PASS "git clone from GitHub" "ok" ""
} else { Row FAIL "git clone from GitHub" "failed" "Check proxy/firewall for git over HTTPS" }
if ($GitHubUser) {
  $code = HttpStatus "https://api.github.com/users/$GitHubUser"
  if ($code -eq 200) { Row PASS "GitHub account" $GitHubUser "Send this name to the trainer" }
  elseif ($code -eq 404) { Row FAIL "GitHub account" "$GitHubUser ?" "Name not found - check spelling (guide 7)" }
  else { Row WARN "GitHub account" "not checked (HTTP $code)" "GitHub API busy or blocked; check the name by hand" }
} else { Row WARN "GitHub account" "not given" "Rerun: .\check.ps1 -GitHubUser <your-name>" }
if ((Have gh) -and ((gh auth status 2>&1 | Out-String) -match "Logged in")) {
  $tfa = (gh api user --jq ".two_factor_authentication" 2>$null)
  if ($tfa -eq "true") { Row PASS "GitHub 2FA" "enabled" "" }
  elseif ($tfa -eq "false") { Row FAIL "GitHub 2FA" "off" "Turn on 2FA (guide 7.2)" }
  else { Row WARN "GitHub 2FA" "not checked" "Confirm 2FA is on: github.com/settings/security" }
} else { Row WARN "GitHub 2FA" "not checked" "Confirm 2FA is on: github.com/settings/security" }

# --- Lab LAN ---
if ($Offsite) { Row SKIP "Lab app ${LabHost}:8080" "offsite" "Checked on Day 1" }
elseif (HttpOk "http://${LabHost}:8080/api/v1/health") { Row PASS "Lab app ${LabHost}:8080" "reachable" "" }
else { Row WARN "Lab app ${LabHost}:8080" "not reachable" "Only works on Wi-Fi opshub-lab (Day 1)" }

# --- Disk ---
$drive = (Get-Location).Drive
$freeGb = [math]::Floor((Get-PSDrive $drive.Name).Free / 1GB)
if ($freeGb -ge 5) { Row PASS "Free disk >= 5 GB" "$freeGb GB" "" } else { Row WARN "Free disk >= 5 GB" "$freeGb GB" "Free some space" }

Write-Host ("-" * 90)
if ($script:Fails -eq 0) {
  Write-Host "ALL REQUIRED CHECKS PASSED ($($script:Warns) warning(s)). Next: composer install; php artisan test; npm ci; npm test" -ForegroundColor Green
  exit 0
} else {
  Write-Host "$($script:Fails) CHECK(S) FAILED, $($script:Warns) warning(s). Fix what you can with the guide; send this table to the trainer, or use the Codespaces fallback (guide 8)." -ForegroundColor Red
  exit 1
}
