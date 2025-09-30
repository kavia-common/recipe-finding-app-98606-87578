#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-87578/BackendAPIService"
cd "$WORKSPACE"
VENV_PY="$WORKSPACE/.venv/bin/python"
LOG="$WORKSPACE/validation_server.log"
# Determine target port from env or .env
PORT_ENV=${PORT:-}
if [ -z "$PORT_ENV" ]; then
  PORT_ENV=$(grep -E '^PORT=' .env 2>/dev/null | cut -d= -f2 || echo 5000)
fi
TARGET_PORT=${PORT_ENV:-5000}
# Python-based port check
is_port_free() {
  python3 - <<PY
import socket,sys
s=socket.socket()
try:
 s.bind(('127.0.0.1', int(sys.argv[1])))
 s.close(); print('yes')
except Exception:
 print('no')
PY
}
if [ "$(is_port_free "$TARGET_PORT")" != "yes" ]; then
  TARGET_PORT=$(python3 - <<PY
import socket
s=socket.socket(); s.bind(('127.0.0.1',0)); p=s.getsockname()[1]; s.close(); print(p)
PY
)
  [ -n "$TARGET_PORT" ] || (echo 'no free port' >&2 && exit 4)
fi
export PORT="$TARGET_PORT"
# ensure venv python exists
if [ ! -x "$VENV_PY" ]; then
  echo "Virtualenv python not found at $VENV_PY" >&2
  exit 5
fi
# Start server
nohup setsid "$VENV_PY" -u app.py >"$LOG" 2>&1 &
PID=$!
sleep 0.2
if ps -p "$PID" -o comm= | grep -q 'sh\|bash\|nohup'; then
  PGID=$(ps -o pgid= -p "$PID" | tr -d ' ')
  CHILD=$(pgrep -n -g "$PGID" -f "python.*app.py" || true)
  [ -n "$CHILD" ] && PID="$CHILD"
fi
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ')
echo "$PID" > "$WORKSPACE/server.pid"
echo "$PGID" > "$WORKSPACE/server.pgid"
# Probe loop: increase retries (max ~40 * 0.5s = 20s)
TRIES=0
MAX_TRIES=40
until curl -sS --max-time 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 || [ $TRIES -ge $MAX_TRIES ]; do
  TRIES=$((TRIES+1))
  sleep 0.5
done
# Strict JSON check
if curl -sS --max-time 2 "http://127.0.0.1:$PORT/health" | python3 -c "import sys,json
try:
 data=json.load(sys.stdin)
 if data.get('status')=='ok':
  sys.exit(0)
 sys.exit(2)
except Exception:
 sys.exit(3)"; then
  echo '{"validation":"success","endpoint":"/health","port':$PORT',"pid":'
