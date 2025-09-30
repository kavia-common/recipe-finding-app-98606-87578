#!/usr/bin/env bash
set -euo pipefail
# build is a no-op for this simple Python Flask project
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-87578/BackendAPIService"
cd "$WORKSPACE"
# ensure workspace exists
[ -d "$WORKSPACE" ] || (echo "Workspace missing" >&2 && exit 2)
# no build steps required
exit 0
