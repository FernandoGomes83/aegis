#!/bin/bash
# aegis-sdd — Git worktree management for parallel task execution
# Usage: aegis-build-worktree.sh <action> [args]

set -euo pipefail

ACTION="${1:?Usage: aegis-build-worktree.sh <action> [args]}"
shift

WORKTREE_DIR=".worktrees"

case "$ACTION" in
  create)
    BRANCH_PREFIX="${1:?Missing branch prefix}"
    shift

    if [ $# -eq 0 ]; then
      echo "ERROR=no_task_ids"
      echo "No task IDs provided"
      exit 1
    fi

    # Ensure we are in a git repo
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "ERROR=not_git_repo"
      echo "Not inside a git repository"
      exit 1
    fi

    mkdir -p "$WORKTREE_DIR"
    CREATED=0

    for task_id in "$@"; do
      # Normalize task ID for branch name (lowercase, no special chars)
      branch_name="${BRANCH_PREFIX}-$(echo "$task_id" | tr '[:upper:]' '[:lower:]')"
      worktree_path="$WORKTREE_DIR/$task_id"

      if [ -d "$worktree_path" ]; then
        echo "SKIP=$task_id (worktree already exists)"
        continue
      fi

      git worktree add "$worktree_path" -b "$branch_name" 2>/dev/null
      if [ $? -eq 0 ]; then
        CREATED=$((CREATED + 1))
        echo "CREATED=$task_id branch=$branch_name path=$worktree_path"
      else
        echo "FAILED=$task_id"
      fi
    done

    echo "TOTAL_CREATED=$CREATED"
    ;;

  merge)
    BRANCH_PREFIX="${1:?Missing branch prefix}"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "ERROR=not_git_repo"
      exit 1
    fi

    CURRENT_BRANCH=$(git branch --show-current)
    MERGED=0
    CONFLICTS=0

    # Find all branches matching the prefix
    for branch in $(git branch --list "${BRANCH_PREFIX}-*" | sed 's/^[* ]*//' | tr -d ' '); do
      echo "MERGING=$branch"
      if git merge --no-edit "$branch" 2>/dev/null; then
        MERGED=$((MERGED + 1))
        echo "MERGED=$branch"
      else
        CONFLICTS=$((CONFLICTS + 1))
        echo "CONFLICT=$branch"
        # Abort the failed merge to keep working tree clean
        git merge --abort 2>/dev/null || true
      fi
    done

    echo "TOTAL_MERGED=$MERGED"
    echo "TOTAL_CONFLICTS=$CONFLICTS"
    ;;

  cleanup)
    BRANCH_PREFIX="${1:?Missing branch prefix}"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "ERROR=not_git_repo"
      exit 1
    fi

    REMOVED=0

    # Remove worktrees created by aegis (legacy worktree mode)
    if [ -d "$WORKTREE_DIR" ]; then
      for wt_dir in "$WORKTREE_DIR"/TASK-*; do
        [ -d "$wt_dir" ] || continue
        git worktree remove "$wt_dir" --force 2>/dev/null && REMOVED=$((REMOVED + 1)) || true
      done
    fi

    # Remove worktrees created by Agent tool (isolation: "worktree")
    # Agent tool creates worktrees under .worktrees/ with generated names
    if [ -d "$WORKTREE_DIR" ]; then
      for wt_dir in "$WORKTREE_DIR"/*/; do
        [ -d "$wt_dir" ] || continue
        git worktree remove "$wt_dir" --force 2>/dev/null && REMOVED=$((REMOVED + 1)) || true
      done
    fi

    # Prune stale worktree references
    git worktree prune 2>/dev/null || true

    # Delete branches matching the build prefix
    BRANCHES_DELETED=0
    for branch in $(git branch --list "${BRANCH_PREFIX}-*" | sed 's/^[* ]*//' | tr -d ' '); do
      if git branch -d "$branch" 2>/dev/null; then
        BRANCHES_DELETED=$((BRANCHES_DELETED + 1))
        echo "DELETED_BRANCH=$branch"
      else
        # Force delete if not fully merged (user chose to cleanup)
        git branch -D "$branch" 2>/dev/null && BRANCHES_DELETED=$((BRANCHES_DELETED + 1)) || true
      fi
    done

    # Delete branches created by Agent tool worktrees (claude-worktree-* pattern)
    for branch in $(git branch --list "claude-worktree-*" | sed 's/^[* ]*//' | tr -d ' '); do
      if git branch -d "$branch" 2>/dev/null; then
        BRANCHES_DELETED=$((BRANCHES_DELETED + 1))
        echo "DELETED_BRANCH=$branch"
      else
        git branch -D "$branch" 2>/dev/null && BRANCHES_DELETED=$((BRANCHES_DELETED + 1)) || true
      fi
    done

    # Remove worktree directory if empty
    if [ -d "$WORKTREE_DIR" ]; then
      rmdir "$WORKTREE_DIR" 2>/dev/null || true
    fi

    echo "WORKTREES_REMOVED=$REMOVED"
    echo "BRANCHES_DELETED=$BRANCHES_DELETED"
    ;;

  *)
    echo "ERROR=unknown_action"
    echo "Unknown action: $ACTION"
    echo "Valid actions: create, merge, cleanup"
    exit 1
    ;;
esac
