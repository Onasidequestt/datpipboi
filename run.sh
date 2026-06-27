#!/bin/bash
# run.sh — start DATBOI: the discovery sidecar + the dashboard + the bot.
# Source lives in src/; everything runs with src/ as the working directory so the
# bot, sidecar, dashboard, and tools all agree on where state lives (src/bots,
# src/shared_memory, src/logs). Your .env stays at the repo root.
cd "$(dirname "$0")" || exit 1     # repo root

# First run? Create a minimal .env (at the repo root) so the dashboard can boot,
# then finish setup in the browser at http://localhost:8080 (enter your API keys
# there). Prefer the terminal? Run `python3 src/setup.py` for an interactive wizard.
if [ ! -f .env ]; then
    python3 src/setup.py --bootstrap || exit 1
fi

# DATBOI — boot banner (green phosphor)
G=$'\033[1;32m'; D=$'\033[2;32m'; R=$'\033[0m'
printf '\n'
printf '%s   🐸  DATBOI%s\n' "$G" "$R"
printf '%s      ═══════>   ═══════>   ═══════>%s\n' "$D" "$R"
printf '%s      autonomous solana trading bot%s\n' "$D" "$R"
_PORT=$(grep -E '^DASHBOARD_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d ' ')
_PORT=${_PORT:-8080}
printf '%s  Dashboard %s→%s http://localhost:%s%s\n\n' "$D" "$G" "$D" "$_PORT" "$R"

cd src || exit 1     # run everything from src/ so all paths resolve consistently

# Kill the entire process group on any exit — Ctrl+C, terminal close, or kill —
# so the bot never runs orphaned when you leave the terminal. SIGHUP is the
# config-reload signal here, so it is forwarded to the bot (not treated as exit).
mkdir -p logs
_DEATHLOG="$PWD/logs/fleet_death.log"
_log_sig() {  # $1 = signal name
    {
        echo "[shutdown] $(date '+%Y-%m-%dT%H:%M:%S%z') caught SIG$1  (run.sh pid=$$ ppid=$PPID)"
        ps -o pid,ppid,stat,etime,command -p "$$" "$PPID" 2>/dev/null | sed 's/^/    /'
    } >> "$_DEATHLOG" 2>&1
}
_shutdown() {
    trap - EXIT INT TERM
    _log_sig "${1:-EXIT}"
    echo ""
    echo "[DATBOI] shutting everything down (sig ${1:-EXIT})..."
    kill 0
}
trap '_shutdown EXIT' EXIT
trap '_shutdown INT'  INT
trap '_shutdown TERM' TERM
trap '_log_sig HUP-IGNORED; pkill -HUP -f "main.py" 2>/dev/null || true' HUP

# Start the discovery sidecar first — one shared polling process feeds the bot.
python3 discovery_service.py &
_SIDECAR_PID=$!
echo "[DATBOI] Discovery sidecar started (pid $_SIDECAR_PID) — waiting for first snapshot..."
sleep 3

# macOS: caffeinate keeps the machine awake while trading. On Linux it does not
# exist, so fall back to running the dashboard directly.
if command -v caffeinate >/dev/null 2>&1; then
    caffeinate -dims python3 dashboard.py
else
    python3 dashboard.py
fi
