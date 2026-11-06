#!/usr/bin/env bash
# SessionStart フック: 標準出力の内容がセッションのコンテキストとして Claude に渡される
set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}"

echo "## リポジトリの現在の状態"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "- ブランチ: $(git branch --show-current 2>/dev/null || echo '(detached)')"
  echo "- 未コミットの変更: $(git status --porcelain | wc -l | tr -d ' ') 件"
else
  echo "- git リポジトリではありません"
fi
echo "- Node.js: $(node --version 2>/dev/null || echo '未インストール')"
