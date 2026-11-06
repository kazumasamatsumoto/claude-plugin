#!/usr/bin/env bash
# 直近のタグ以降のコミットを一覧表示する（タグがなければ全履歴）
set -euo pipefail
if last_tag=$(git describe --tags --abbrev=0 2>/dev/null); then
  git log "${last_tag}..HEAD" --pretty=format:'%h %s'
else
  git log --pretty=format:'%h %s'
fi
