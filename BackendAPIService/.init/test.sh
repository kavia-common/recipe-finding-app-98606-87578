#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-87578/BackendAPIService"
cd "$WORKSPACE"
VENV_PY="$WORKSPACE/.venv/bin/python"
# run pytest using venv python if available
if [ -x "$VENV_PY" ]; then
  "$VENV_PY" -m pytest -q || exit 2
else
  python3 -m pytest -q || exit 2
fi
exit 0
