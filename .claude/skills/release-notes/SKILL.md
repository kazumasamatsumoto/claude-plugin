---
name: release-notes
description: 前回のタグから現在までのコミット履歴をもとにリリースノートを作成する。
disable-model-invocation: true
argument-hint: "[バージョン番号 例: v0.2.0]"
---

# リリースノート作成

対象バージョン: $ARGUMENTS

1. 次のスクリプトでコミット一覧を取得する:
   `bash ${CLAUDE_SKILL_DIR}/scripts/collect-commits.sh`
2. コミットを type ごとに分類する（feat → 新機能、fix → バグ修正、その他 → 改善）
3. 以下のテンプレートで Markdown を出力する

```markdown
## <バージョン> (<今日の日付>)

### 新機能
- ...

### バグ修正
- ...

### その他の改善
- ...
```

利用者に関係ない内部的な変更（chore、test のみ等）は省略してよい。
