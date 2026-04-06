#!/bin/bash
# aegis-sdd — Bootstrap: resolve AEGIS_HOME and optionally create dirs
# Usage: aegis-bootstrap.sh <project_root> [resolve|init]

set -euo pipefail

PROJECT_ROOT="${1:?Usage: aegis-bootstrap.sh <project_root> [resolve|init]}"
MODE="${2:-resolve}"

SPEC_REL=".claude/aegis/framework/SPEC.md"

# Check local install first, then global
if [ -f "$PROJECT_ROOT/$SPEC_REL" ]; then
  AEGIS_HOME="$PROJECT_ROOT/.claude/aegis"
  echo "AEGIS_HOME=$AEGIS_HOME"
  echo "SOURCE=local"
elif [ -f "$HOME/$SPEC_REL" ]; then
  AEGIS_HOME="$HOME/.claude/aegis"
  echo "AEGIS_HOME=$AEGIS_HOME"
  echo "SOURCE=global"
else
  echo "ERROR=not_found"
  exit 1
fi

# In init mode, also create output directories
if [ "$MODE" = "init" ]; then
  mkdir -p "$PROJECT_ROOT/.aegis" "$PROJECT_ROOT/.aegis/reports" "$PROJECT_ROOT/.aegis/tests"
  echo "DIRS_CREATED=true"
fi
