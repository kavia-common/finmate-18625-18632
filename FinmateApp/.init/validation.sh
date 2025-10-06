#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/finmate-18625-18632/FinmateApp"
cd "$WORKSPACE"
VENV="$WORKSPACE/.venv"
PY="$VENV/bin/python"
STREAMLIT="$VENV/bin/streamlit"
if [ ! -x "$STREAMLIT" ]; then echo "streamlit not found in venv" >&2; exit 2; fi
if [ -f /etc/profile.d/streamlit_env.sh ]; then source /etc/profile.d/streamlit_env.sh || true; fi
PORT=${PORT:-${STREAMLIT_SERVER_PORT:-8501}}
LOG="$WORKSPACE/streamlit.log"
PIDFILE="$WORKSPACE/.streamlit.pid"
rm -f "$LOG" "$PIDFILE"
# start streamlit in its own process group so we can kill the group later
setsid "$STREAMLIT" run app.py --server.port "$PORT" --server.headless true --server.address 0.0.0.0 >"$LOG" 2>&1 &
ST_PID=$!
# write pidfile
printf '%s\n' "$ST_PID" > "$PIDFILE"
# save PGID
PGID=$(ps -o pgid= -p "$ST_PID" | tr -d ' ')
# ensure cleanup on exit: terminate process group
cleanup(){
  if [ -n "$PGID" ] && kill -0 -"$PGID" >/dev/null 2>&1; then
    kill -TERM -"$PGID" >/dev/null 2>&1 || true
    sleep 1
    kill -KILL -"$PGID" >/dev/null 2>&1 || true
  elif ps -p "$ST_PID" >/dev/null 2>&1; then
    kill "$ST_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
# health-check against multiple addresses (127.0.0.1 and container IP)
RETRIES=30; SLEEPT=1
SUCCESS=0
for host in 127.0.0.1 $(hostname -I | awk '{print $1}'); do
  for i in $(seq 1 $RETRIES); do
    CODE=$(curl -sS --max-time 2 -o /dev/null -w "%{http_code}" "http://$host:$PORT/" 2>/dev/null || echo "")
    if [ "$CODE" = "200" ] || [ "$CODE" = "302" ]; then
      SUCCESS=1; echo "streamlit-up at $host:$PORT"; break 2
    fi
    sleep $SLEEPT
    if [ $i -eq $RETRIES ]; then break; fi
  done
done
if [ $SUCCESS -ne 1 ]; then
  echo "streamlit failed to return successful HTTP code; see $LOG" >&2
  tail -n 200 "$LOG" >&2 || true
  exit 3
fi
# check logs for startup indicators
if ! grep -Ei "(Running on|Application started|Started|Server is running|HTTP server listening)" "$LOG" >/dev/null 2>&1; then
  echo "Warning: startup indicators not found in log; dumping tail" >&2
  tail -n 200 "$LOG" >&2 || true
else
  echo "startup-log-evidence" >&2
fi
# normal exit triggers trap cleanup; wait briefly then exit successfully
sleep 1
