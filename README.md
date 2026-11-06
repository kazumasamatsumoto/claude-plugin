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

## 配布形態の整理 — ファイル直置き・プラグイン・MCP

外部から提供されるツールを組み込むときに迷わないよう、**「中身（部品）」と「配り方」を分けて** 整理します。

> **要点**
>
> - 配布元が「Claude Code のプラグインとして配布する」と明言していない場合、**ファイルとしてローカルに配られるのか、マーケットプレイスのプラグインとして配られるのかは、まだ決まっていません。** 配布元への確認が必要です（[配布元に確認するとよいこと](#配布元に確認するとよいこと)）。
> - **どちらの形で配られても、中身は最終的に各メンバーの PC に保存されてから実行されます。** 違うのは、置き場所と、誰が管理するかです。
>
> | | ファイルで配られる場合（A） | プラグインとして配られる場合（B） |
> |---|---|---|
> | PC 上の保存場所 | リポジトリ内の `.claude/`（git で共有される） | `~/.claude/plugins/cache/…`（インストール時に自動でダウンロードされる。リポジトリには入らない） |
> | リポジトリに書くもの | 部品のファイルそのもの | `settings.json` に、どこから・どれを使うかだけ |
> | 管理するのは | 自分たち（自由に改造できる） | 配布元（改造できない。更新は配布元から届く） |

### 中身は4種類（どの配り方でも同じ）

| 部品 | 役割 |
|---|---|
| スキル | 手順書。`/名前` で呼ぶか、Claude が必要に応じて使う |
| エージェント | 専門の担当者（サブエージェント） |
| フック | 決まったタイミングで自動実行されるスクリプト |
| MCP サーバー | 外部システムに接続するためのツール（API など） |

**プラグインは、これらをひとまとめにした「箱」** です。プラグインだけの特別な機能があるわけではありません。

### 配り方は3通り

```
A. ファイルを直接置く
   リポジトリ/.claude/skills/…, .claude/agents/…, settings.json の hooks, .mcp.json
   → コピーしたものがそのまま使われる。自由に改造できる

B. プラグインとして、マーケットプレイス経由で配る
   配布元の Git リポジトリ（marketplace.json + プラグインの箱）
        ↓ 参照
   リポジトリ/.claude/settings.json に「どこから・どれを」書くだけ
   → .claude/ に部品をコピーする必要はない

C. MCP サーバーだけを配る（外部システムとの接続が目的の場合によくある形）
   リポジトリ/.mcp.json に接続先を書く
```

- 「マーケットプレイス」は claude.com の公開ストアだけを指すわけではありません。**`marketplace.json` を置いた Git リポジトリならどれでもマーケットプレイスになります**（public でも、社内の private でも構いません）。
- `settings.json` は、プラグインを「呼び出す」のではなく「登録して有効にする」ためのものです。実際に使われるのは、`/` で呼んだときか、Claude が必要と判断したときです。プラグインのものは `プラグイン名:名前` で表示されます（例: `frontend-design:frontend-design`）。
- A と B は共存できます。配布元のツールは B で受け取り、プロジェクト固有のルールは A で `.claude/` に置く、という使い方が普通です（このリポジトリもその構成です）。

### プラグインの中身はどこにあり、改造できるか

**リポジトリには入りませんが、各メンバーの PC には入ります。** インストールすると、Claude Code が中身をキャッシュにダウンロードします。

```
~/.claude/plugins/cache/<マーケットプレイス名>/<プラグイン名>/<バージョン>/
```

- **改造はできません。** プラグインのエージェントやスキルは、配布元が定義した内容のまま動きます。キャッシュのファイルを書き換えてもその PC だけの変更で、更新時に上書きされます。有効・無効の切り替えも、基本的にプラグイン単位です。
- `.claude/agents/` に同じ名前のエージェントを置いても上書きにはなりません。プラグインのものには `プラグイン名:` が付くので、別のものとして並んで存在します。
- **中身は配布元の都合で変わります。** 配布元が更新すると、次回の更新時にその内容がそのまま入ってきます。勝手に挙動が変わると困る場合は、チーム用のマーケットプレイスを作り、commit SHA を指定してバージョンを固定します。

### 使う側が外側から制御できること

| 方法 | プラグインへの効き方 |
|---|---|
| `settings.json` の `permissions`（deny など） | 効く。プラグインのエージェントも、プロジェクトの権限設定の範囲内でしか動けない |
| `settings.json` の `hooks`（`PreToolUse` など） | 効く。プラグインのエージェントのツール呼び出しにも発火する |
| `CLAUDE.md` | メインの会話に指示として渡るので、いつ・どう使うかには影響する。エージェント定義そのものは変わらない |
| プラグインを無効にして、中身をコピーして A の形にする | 自由に改造できる。ただしライセンスの確認が必要で、上流の更新は自分で取り込むことになる |

プラグインのエージェントは frontmatter に書いた `hooks`・`mcpServers`・`permissionMode` が無視されます（セキュリティ上の理由）。そのため、**プラグインが勝手に権限を広げることはできず、主導権は使う側の設定にあります。**

### 提供されたものから組み込み方を判断する

| 渡されるもの | 形 | このリポジトリでやること |
|---|---|---|
| GitHub などの URL で、`.claude-plugin/marketplace.json` がある | B | `settings.json` の `extraKnownMarketplaces` と `enabledPlugins` に書く |
| `.claude-plugin/plugin.json` だけがある（箱はあるが一覧がない） | B の一歩手前 | 自分たちで marketplace.json を作って包むか、配布元に一覧の追加を依頼する |
| `SKILL.md` やエージェントの `.md`、スクリプトなどのファイル | A | `.claude/skills/`、`.claude/agents/` などにコピーする |
| MCP サーバーの URL や起動コマンド | C | `.mcp.json` に書く |

### 配布元に確認するとよいこと

1. **形式:** Claude Code のプラグイン（マーケットプレイス）として提供されるのか、ファイルや MCP サーバーとして提供されるのか
2. **場所:** マーケットプレイスなら、リポジトリの URL とマーケットプレイス名（`marketplace.json` の `name`）、プラグイン名
3. **公開範囲:** public か private か（private なら、メンバー全員にアクセス権と git の認証が必要）
4. **バージョン:** 更新の頻度と、バージョンを固定できるか（タグや commit SHA）
5. **中身:** スキル・エージェント・フック・MCP のどれが入っているか（フックや MCP は社内のセキュリティ確認の対象になりやすい）

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
