#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-87578/BackendAPIService"
cd "$WORKSPACE"
VENV_PY="$WORKSPACE/.venv/bin/python"
VENV_PIP="$WORKSPACE/.venv/bin/pip"
if [ ! -d "$WORKSPACE/.venv" ]; then
  python3 -m venv "$WORKSPACE/.venv"
fi
$VENV_PIP install -q --upgrade pip
$VENV_PIP install -q -r "$WORKSPACE/requirements.txt"
$VENV_PY - <<'PY'
import sys
try:
    import flask, dotenv, PIL, requests, sqlite3
    conn = sqlite3.connect(':memory:')
    cur = conn.cursor(); cur.execute('select 1'); cur.close(); conn.close()
except Exception as e:
    sys.stderr.write('Dependency or sqlite validation failed: %s\n' % e)
    sys.exit(2)
print('deps-ok')
PY
