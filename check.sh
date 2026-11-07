#!/usr/bin/env bash
# setup-check/check.sh — pre-course toolchain check for macOS and Linux (and Git Bash/WSL).
# Prints a PASS / WARN / FAIL table and exits 1 if anything FAILS.
#
#   ./check.sh                         # all checks
#   ./check.sh --github-user <name>    # also confirms your GitHub account name exists
#   ./check.sh --offsite               # LAN check reported as SKIP (use at home, before Day 1)
#
# Works with the bash 3.2 that ships with macOS (no associative arrays).
# Nothing is installed or changed; the script only reads versions and makes HTTPS requests.

set -u
GITHUB_USER=""
OFFSITE=0
LAB_HOST="${LAB_HOST:-192.168.8.10}"
while [ $# -gt 0 ]; do
  case "$1" in
    --github-user) GITHUB_USER="${2:-}"; shift 2 ;;
    --offsite) OFFSITE=1; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 2 ;;
  esac
done

FAILS=0; WARNS=0
if [ -t 1 ]; then G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; B=$'\033[1m'; N=$'\033[0m'; else G=""; Y=""; R=""; B=""; N=""; fi

row() { # result check found hint
  local colour="$G"
  case "$1" in WARN) colour="$Y"; WARNS=$((WARNS+1));; FAIL) colour="$R"; FAILS=$((FAILS+1));; SKIP) colour="";; esac
  printf '%-26s %s%-5s%s %-28s %s\n' "$2" "$colour" "$1" "$N" "$(printf '%.28s' "$3")" "$4"
}
have() { command -v "$1" >/dev/null 2>&1; }
# ver_ge A B : true if version A >= B (numeric dotted compare)
ver_ge() {
  local IFS=.
  # shellcheck disable=SC2206
  local a=($1) b=($2) i
  for i in 0 1 2; do
    local x="${a[$i]:-0}" y="${b[$i]:-0}"
    x="${x//[^0-9]/}"; y="${y//[^0-9]/}"; x="${x:-0}"; y="${y:-0}"
    [ "$x" -gt "$y" ] && return 0
    [ "$x" -lt "$y" ] && return 1
  done
  return 0
}
first_version() { grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1; }
# http_code URL : prints the HTTP status (000 = no connection); http_ok URL : 2xx/3xx
http_code() { have curl || { echo 000; return; }; curl -s -o /dev/null -m 8 -w '%{http_code}' "$1" 2>/dev/null || true; }
http_ok() { case "$(http_code "$1")" in 2*|3*) return 0;; *) return 1;; esac; }

echo "${B}Airport Ops Hub course — setup check${N}  ($(uname -s) $(uname -m), $(date '+%Y-%m-%d %H:%M'))"
printf '%-26s %-5s %-28s %s\n' "CHECK" "RESULT" "FOUND" "WHAT TO DO IF NOT PASS"
printf '%s\n' "------------------------------------------------------------------------------------------"

# --- Git ---
if have git; then v=$(git --version | first_version)
  if ver_ge "$v" 2.30; then row PASS "Git" "$v" ""; else row WARN "Git" "$v" "Update Git (guide §2)"; fi
else row FAIL "Git" "not found" "Install Git (guide §2)"; fi

# --- PHP 8.3 ---
if have php; then v=$(php -r 'echo PHP_VERSION;' 2>/dev/null)
  case "$v" in
    8.3.*) row PASS "PHP 8.3" "$v" "" ;;
    8.4.*|8.5.*) row WARN "PHP 8.3" "$v" "Course uses 8.3; switch in Herd or install 8.3 (guide §4)" ;;
    *) row FAIL "PHP 8.3" "${v:-unknown}" "Install PHP 8.3 (guide §4)" ;;
  esac
  for ext in pdo_sqlite pdo_pgsql intl mbstring zip curl openssl fileinfo; do
    if php -m 2>/dev/null | grep -qix "$ext"; then row PASS "  ext $ext" "loaded" ""
    else row FAIL "  ext $ext" "missing" "Enable $ext in php.ini (guide §4.4)"; fi
  done
else row FAIL "PHP 8.3" "not found" "Install PHP 8.3 + Composer (guide §4)"; fi

# --- Composer >= 2.7 ---
if have composer; then v=$(composer --version 2>/dev/null | first_version)
  if ver_ge "$v" 2.7; then row PASS "Composer >= 2.7" "$v" ""; else row FAIL "Composer >= 2.7" "$v" "composer self-update (guide §4)"; fi
else row FAIL "Composer >= 2.7" "not found" "Install Composer (guide §4)"; fi

# --- Node >= 22 (24 LTS recommended), npm ---
if have node; then v=$(node --version | first_version)
  if ver_ge "$v" 24; then row PASS "Node.js LTS" "$v" ""
  elif ver_ge "$v" 22; then row PASS "Node.js LTS" "$v" "(24 LTS recommended; 22 is fine)"
  else row FAIL "Node.js LTS" "$v" "Install Node 24 LTS (guide §3)"; fi
else row FAIL "Node.js LTS" "not found" "Install Node 24 LTS (guide §3)"; fi
if have npm; then row PASS "npm" "$(npm --version 2>/dev/null)" ""; else row FAIL "npm" "not found" "Comes with Node (guide §3)"; fi

# --- Playwright Chromium ---
pw_dirs="${PLAYWRIGHT_BROWSERS_PATH:-} $HOME/.cache/ms-playwright $HOME/Library/Caches/ms-playwright"
found_pw=""
for d in $pw_dirs; do
  [ -n "$d" ] && [ -d "$d" ] && ls -d "$d"/chromium-* >/dev/null 2>&1 && found_pw="$(ls -d "$d"/chromium-* | tail -n1)"
done
if [ -n "$found_pw" ]; then row PASS "Playwright Chromium" "$(basename "$found_pw")" ""
else row FAIL "Playwright Chromium" "not found" "In this folder: npx playwright install chromium"; fi

# --- Editor and browser (warnings only) ---
if have code; then row PASS "VS Code (code CLI)" "$(code --version 2>/dev/null | head -n1)" ""
else row WARN "VS Code (code CLI)" "not on PATH" "Install VS Code; mac: Cmd+Shift+P 'Shell Command: Install code'"; fi
browser=""
for b in google-chrome google-chrome-stable chromium microsoft-edge microsoft-edge-stable; do have "$b" && browser="$b"; done
[ -d "/Applications/Google Chrome.app" ] && browser="Google Chrome"
[ -d "/Applications/Microsoft Edge.app" ] && browser="${browser:-Microsoft Edge}"
if [ -n "$browser" ]; then row PASS "Chrome or Edge" "$browser" ""; else row WARN "Chrome or Edge" "not detected" "Install Chrome or Edge (guide §6)"; fi

# --- Network: internet services the labs need ---
for u in https://github.com https://api.github.com https://repo.packagist.org/packages.json https://registry.npmjs.org/; do
  name="Reach ${u#https://}"; name="${name%%/*}"
  code="$(http_code "$u")"
  case "$code" in
    2*|3*) row PASS "$name" "HTTPS ok" "" ;;
    000)   row FAIL "$name" "no connection" "Network/proxy blocks it — tell the trainer" ;;
    *)     row FAIL "$name" "HTTP $code" "Proxy or filter answers instead — tell the trainer" ;;
  esac
done

# --- GitHub: clone access and (optionally) account ---
if have git && git ls-remote https://github.com/scrum-course/setup-check HEAD >/dev/null 2>&1; then
  row PASS "git clone from GitHub" "ok" ""
else row FAIL "git clone from GitHub" "failed" "Check proxy/firewall for git over HTTPS"; fi
if [ -n "$GITHUB_USER" ]; then
  code="$(http_code "https://api.github.com/users/$GITHUB_USER")"
  case "$code" in
    200) row PASS "GitHub account" "$GITHUB_USER" "Send this name to the trainer" ;;
    404) row FAIL "GitHub account" "$GITHUB_USER ?" "Name not found — check spelling (guide §7)" ;;
    *)   row WARN "GitHub account" "not checked (HTTP $code)" "GitHub API busy or blocked; check the name by hand" ;;
  esac
else row WARN "GitHub account" "not given" "Rerun: ./check.sh --github-user <your-name>"; fi
if have gh && gh auth status >/dev/null 2>&1; then
  tfa=$(gh api user --jq '.two_factor_authentication' 2>/dev/null)
  if [ "$tfa" = "true" ]; then row PASS "GitHub 2FA" "enabled" ""; else row FAIL "GitHub 2FA" "${tfa:-unknown}" "Turn on 2FA (guide §7.2)"; fi
else row WARN "GitHub 2FA" "not checked" "Confirm 2FA is on: github.com/settings/security"; fi

# --- Lab LAN (only on site, on Wi-Fi opshub-lab) ---
if [ "$OFFSITE" -eq 1 ]; then row SKIP "Lab app $LAB_HOST:8080" "offsite" "Checked on Day 1"
elif http_ok "http://$LAB_HOST:8080/api/v1/health"; then row PASS "Lab app $LAB_HOST:8080" "reachable" ""
else row WARN "Lab app $LAB_HOST:8080" "not reachable" "Only works on Wi-Fi opshub-lab (Day 1)"; fi

# --- Disk space ---
free_gb=$(df -Pk . 2>/dev/null | awk 'NR==2 {printf "%d", $4/1048576}')
if [ "${free_gb:-0}" -ge 5 ]; then row PASS "Free disk >= 5 GB" "${free_gb} GB" ""; else row WARN "Free disk >= 5 GB" "${free_gb:-?} GB" "Free some space"; fi

printf '%s\n' "------------------------------------------------------------------------------------------"
if [ "$FAILS" -eq 0 ]; then
  echo "${G}${B}ALL REQUIRED CHECKS PASSED${N} ($WARNS warning(s)). Next: composer install && php artisan test && npm ci && npm test"
  exit 0
else
  echo "${R}${B}$FAILS CHECK(S) FAILED${N}, $WARNS warning(s). Fix what you can with the guide; send this table to the trainer, or use the Codespaces fallback (guide §8)."
  exit 1
fi
