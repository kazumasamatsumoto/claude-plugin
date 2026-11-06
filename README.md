# Claude Code リポジトリ単位設定サンプル

このリポジトリを clone して `claude` を起動するだけで、チーム全員が同じ **エージェント・スキル・フック・プラグイン** を使えるようにするサンプルです。

## 構成

```
.
├── CLAUDE.md                         # プロジェクトの前提知識（毎セッション読み込まれる）
├── .claude/
│   ├── settings.json                 # 権限・フック・使うプラグインの指定（コミットする）
│   ├── agents/                       # サブエージェント
│   │   ├── code-reviewer.md
│   │   └── test-runner.md
│   ├── skills/                       # スキル（/名前 で呼び出し可能）
│   │   ├── commit-message/SKILL.md
│   │   └── release-notes/
│   │       ├── SKILL.md
│   │       └── scripts/collect-commits.sh
│   └── hooks/                        # settings.json から呼ばれるフックスクリプト
│       ├── session-start.sh
│       ├── block-dangerous-commands.sh
│       └── run-tests-on-edit.sh
├── src/calc.js                       # 動作確認用のサンプルコード
└── test/calc.test.js
```

## 各要素の説明

### サブエージェント（`.claude/agents/`）

| 名前 | 役割 | 使えるツール |
|---|---|---|
| `code-reviewer` | 差分をレビューし、重大/推奨/任意に分けて指摘 | Read, Grep, Glob, Bash |
| `test-runner` | テストを実行し、失敗原因を調べる（編集はしない） | Bash, Read, Grep, Glob |

`description` に合う場面では Claude が自動で呼び出します。明示的に使うなら「code-reviewer エージェントでレビューして」のように頼みます。`/agents` で一覧を確認できます。

### スキル（`.claude/skills/`）

| 名前 | 呼び出し方 | 内容 |
|---|---|---|
| `commit-message` | `/commit-message`、または「コミットメッセージを作って」 | Conventional Commits 形式でメッセージを作る |
| `release-notes` | `/release-notes v0.2.0`（手動のみ） | タグ以降のコミットからリリースノートを作る |

- `disable-model-invocation: true` を付けたスキルは Claude が自動では使わず、ユーザーが `/名前` で呼んだときだけ動きます。
- `allowed-tools` を付けると、スキル実行中はそのツールを確認なしで使えます。
- `${CLAUDE_SKILL_DIR}` でスキルのディレクトリ内のスクリプトを参照できます。

### フック（`.claude/settings.json` の `hooks`）

| イベント | スクリプト | 動作 |
|---|---|---|
| `SessionStart` | `session-start.sh` | ブランチ名や未コミット件数を Claude のコンテキストに渡す |
| `PreToolUse` (Bash) | `block-dangerous-commands.sh` | ルート/ホームの再帰削除、強制 push、`git reset --hard`、`curl \| sh` をブロック |
| `PostToolUse` (Edit/Write) | `run-tests-on-edit.sh` | `src/`・`test/` の編集後にテストを実行し、失敗を Claude に返す |

フックは stdin で JSON（`tool_input` など）を受け取ります。**exit 2** で終了すると処理をブロックし、stderr の内容が Claude に伝わります。

> 注意: `PreToolUse` フックはコマンド文字列全体を見るため、危険なコマンドを「文字列として含むだけ」のコマンド（例: その文字列を書き込む heredoc）にも反応します。パターンは誤検知が少なくなるよう絞ってありますが、必要に応じて調整してください。

### プラグイン — 公開されているプラグインをチーム全員で使う

`.claude/settings.json` に **マーケットプレイス（取得元）** と **有効にするプラグイン** を書いてコミットします。それだけで、リポジトリを clone したメンバー全員に同じプラグインが入ります。

```json
"extraKnownMarketplaces": {
  "claude-plugins-official": {
    "source": { "source": "github", "repo": "anthropics/claude-plugins-official" }
  }
},
"enabledPlugins": {
  "frontend-design@claude-plugins-official": true,
  "commit-commands@claude-plugins-official": true,
  "pr-review-toolkit@claude-plugins-official": true
}
```

| プラグイン | 取得元 | 内容 |
|---|---|---|
| `frontend-design` | 公式（[claude.com/marketplace](https://claude.com/ja/marketplace/plugins/frontend-design)） | 見た目の質が高いフロントエンドを作るスキル |
| `commit-commands` | 公式 | コミット・push・PR 作成のコマンド |
| `pr-review-toolkit` | 公式 | PR レビュー用のエージェント群 |

#### プラグインを追加する方法

1. [claude.com/marketplace](https://claude.com/ja/marketplace) などで使いたいプラグインを探す
2. `enabledPlugins` に `"<プラグイン名>@<マーケットプレイス名>": true` を追加する
   - 公式のプラグインなら `@claude-plugins-official`
   - 公式以外（他社や個人が GitHub で公開しているもの）は、そのリポジトリを `extraKnownMarketplaces` に追加する。マーケットプレイス名は、そのリポジトリの `.claude-plugin/marketplace.json` の `name` に書かれている
3. コミットして PR を出す

手で JSON を書く代わりに、`claude plugin install <名前>@<マーケットプレイス> --scope project` を実行しても `.claude/settings.json` に追記されます。

#### メンバー側で起こること

- リポジトリで `claude` を起動すると、フォルダを信頼するか聞かれ、続いてマーケットプレイスの追加とプラグインのインストールを確認される。承認すれば入る
- 入ったプラグインは `/plugin` で確認できる。個人的に止めたい場合は `.claude/settings.local.json` に `"enabledPlugins": { "xxx@yyy": false }` と書く
- 公開プラグインは上流の最新版が使われる（バージョンを固定したい場合は、チーム用のマーケットプレイスを作って commit SHA を指定する方法がある）

## 使い方

```bash
git init && git add . && git commit -m "chore: initial commit"   # git が前提のフックやスキルがあります
claude
```

1. 初回起動時にフォルダを信頼するか聞かれ、続いてマーケットプレイスとプラグインのインストールを確認されるので承認します。
   - 表示されない場合は手動で: `/plugin marketplace add anthropics/claude-plugins-official` → `/plugin install frontend-design@claude-plugins-official`
2. 確認:
   - `/agents` … `code-reviewer`、`test-runner` と、プラグインのエージェント（`pr-review-toolkit` など）が並ぶ
   - `/` を入力 … `commit-message`、`release-notes` と、プラグインのスキル・コマンドが出る
   - `/plugin` … 有効化した 3 つのプラグインが見える
   - `/hooks` … 登録済みのフックが見える
3. 試してみる:
   - 「`src/calc.js` に multiply を追加して」→ 編集後にテストが自動で走る
   - 「強制 push して」→ フックでブロックされる
   - 「ランディングページを作って」→ `frontend-design` スキルが自動で使われる

## 個人用の設定

自分だけの設定は `.claude/settings.local.json` と `CLAUDE.local.md` に書きます（どちらも `.gitignore` 済み）。
