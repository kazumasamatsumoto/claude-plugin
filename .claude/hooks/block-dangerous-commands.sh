#!/usr/bin/env bash
# PreToolUse フック (matcher: Bash)
# stdin で受け取ったツール入力 JSON を検査し、危険なコマンドなら exit 2 でブロックする。
# exit 2 のとき stderr の内容が Claude にフィードバックされる。
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

# 拡張正規表現。誤検知を減らすため「コマンドとして実行される形」だけに絞っている。
patterns=(
  'rm +-[a-zA-Z]*[rR][a-zA-Z]* +(/|~|\$HOME)/?( |;|&|$)'  # ルート/ホームの再帰削除
  'git push( .*)? (--force|-f)( |$)'                       # 強制 push（--force-with-lease は許可）
  'git reset +--hard'
  'curl [^|]*\| *(ba|z)?sh( |$)'                           # curl | sh
)

for p in "${patterns[@]}"; do
  if echo "$cmd" | grep -Eq -- "$p"; then
    echo "ブロック: このリポジトリでは '$p' に該当するコマンドは禁止されています。別の方法を検討してください。" >&2
    exit 2
  fi
done

exit 0
