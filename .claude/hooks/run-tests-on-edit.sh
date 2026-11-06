#!/usr/bin/env bash
# PostToolUse フック (matcher: Edit|Write|MultiEdit)
# src/ または test/ の .js が編集されたらテストを実行し、失敗したら exit 2 で Claude に知らせる。
set -uo pipefail

file=$(jq -r '.tool_input.file_path // ""')
case "$file" in
  "$CLAUDE_PROJECT_DIR"/src/*.js|"$CLAUDE_PROJECT_DIR"/test/*.js) ;;
  *) exit 0 ;;
esac

cd "$CLAUDE_PROJECT_DIR"
if ! out=$(npm test --silent 2>&1); then
  echo "テストが失敗しました（$file の編集後）:" >&2
  echo "$out" | tail -n 30 >&2
  exit 2
fi
exit 0
