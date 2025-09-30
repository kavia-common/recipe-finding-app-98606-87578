#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-87578/BackendAPIService"
cd "$WORKSPACE"
VENV_PY="$WORKSPACE/.venv/bin/python"
LOG="$WORKSPACE/validation_server.log"
: ${PORT:=""}
# Determine port from env or .env default
if [ -z "${PORT:-}" ]; then
  PORT=$(grep -E '^PORT=' .env 2>/dev/null | cut -d= -f2 || echo 5000)
fi
# python port free check function
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
# choose target port
if [ "$(is_port_free "$PORT")" != "yes" ]; then
  PORT=$(python3 - <<PY
import socket
s=socket.socket(); s.bind(('127.0.0.1',0)); p=s.getsockname()[1]; s.close(); print(p)
PY
)
  [ -n "$PORT" ] || (echo 'no free port' >&2 && exit 4)
fi
export PORT
# Make sure venv python exists
if [ ! -x "$VENV_PY" ]; then
  echo "Virtualenv python not found at $VENV_PY" >&2
  exit 5
fi
# Start in new session, capture pid
nohup setsid "$VENV_PY" -u app.py >"$LOG" 2>&1 &
PID=$!
sleep 0.2
# If the recorded pid is wrapper, find the actual python child in the pgid
if ps -p "$PID" -o comm= | grep -q 'sh\|bash\|nohup'; then
  PGID=$(ps -o pgid= -p "$PID" | tr -d ' ')
  CHILD=$(pgrep -n -g "$PGID" -f "python.*app.py" || true)
  [ -n "$CHILD" ] && PID="$CHILD"
fi
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ')
echo "$PID" > "$WORKSPACE/server.pid"
echo "$PGID" > "$WORKSPACE/server.pgid"
# print pid/port for caller
echo "STARTED port=$PORT pid=$PID pgid=$PGID"
