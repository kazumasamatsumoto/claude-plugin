---
name: commit-message
description: ステージ済みの変更から Conventional Commits 形式のコミットメッセージを作成する。コミットメッセージの作成やコミットを頼まれたときに使う。
allowed-tools: Bash(git diff:*), Bash(git status), Bash(git log:*)
---

# コミットメッセージ作成

1. `git diff --cached` でステージ済みの変更を確認する（空なら `git status` を見てユーザーに伝える）
2. `git log --oneline -10` で既存のスタイルを確認する
3. 次の形式でメッセージを作る

```
<type>(<scope>): <要約（50文字以内、命令形）>

<なぜこの変更が必要か。何をしたかは diff を見ればわかるので「なぜ」を書く>
```

type は次から選ぶ: `feat` / `fix` / `docs` / `refactor` / `test` / `chore`

scope はディレクトリ名や機能名（例: `calc`）。不明なら省略してよい。
