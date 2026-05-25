# txtconcat

A small macOS-friendly shell script that concatenates text files in selected
directories into a single text file.

## Requirements

- macOS `/bin/sh`
- Standard macOS command-line tools (`find`, `sort`, `grep`, `cat`, `awk`)

## Usage

Concatenate matching files in the current directory.

```sh
./txtconcat.sh
```

Include subdirectories.

```sh
./txtconcat.sh --recurse
```

Specify one source directory.

```sh
./txtconcat.sh --source-dir ./src
```

Specify multiple source directories.

```sh
./txtconcat.sh --source-dirs ./src,./docs
```

Specify an output directory.

```sh
./txtconcat.sh --output-dir ./out
```

Specify target extensions.

```sh
./txtconcat.sh --extensions .txt,.md,.py
```

Detect text files by file content instead of extension.

```sh
./txtconcat.sh --auto-text
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `--source-dir` | current directory | Specifies one input directory. |
| `--source-dirs` | current directory | Specifies multiple input directories. Cannot be used with `--source-dir`. |
| `--output-dir` | current directory | Specifies the output directory. |
| `--recurse` | off | Includes subdirectories. |
| `--auto-text` | off | Detects text files by content instead of extension. |
| `--extensions` | see File Selection | Target extensions or exact file names when `--auto-text` is not used. |
| `--exclude-dirs` | see File Selection | Directory names to exclude, especially when using `--recurse`. |
| `--delimiter` | `==========` | Separator text between files. |
| `--prefix` | `txtconcat` | Prefix for generated output file names. |
| `--include-generated-files` | off | Includes generated output files that would otherwise be skipped. |
| `--no-home-placeholder` | off | Keeps absolute home paths instead of replacing them with `~`. |

## File Selection

By default, files are selected by extension.
The default target extensions are:

```text
.txt
.md
.markdown
.json
.jsonl
.yaml
.yml
.toml
.xml
.html
.htm
.css
.scss
.js
.jsx
.ts
.tsx
.py
.ps1
.sh
.bash
.zsh
.sql
.csv
.tsv
.log
.env
.ini
.cfg
.conf
.gitignore
.dockerignore
```

The default extension list is intentionally broad for source code, configuration, documents, and logs.
Use `--auto-text` when you want to include any file that looks like text regardless of extension.

When `--auto-text` is specified, files are checked by content instead of extension.
The script reads up to the first 8192 bytes and uses these rules:

- Empty files are treated as text.
- Files containing NUL bytes are treated as binary.
- Files with UTF-8 / UTF-16 / UTF-32 BOMs are treated as text.
- Files with less than 30% control characters are treated as text.

By default, generated `txtconcat_*.txt` and `txtconcat_*_list.txt` files are excluded from input.
These directories are also excluded by default, especially when using `--recurse`:

```text
.git
out
temp
node_modules
dist
build
target
.venv
venv
__pycache__
.cache
.next
.nuxt
coverage
```

## Output

The script creates two files in the output directory:

- `txtconcat_yyyyMMdd-HHmmssfff.txt`
- `txtconcat_yyyyMMdd-HHmmssfff_list.txt`

The concatenated output writes each file as path, delimiter, content, delimiter.

```text
~/Documents/GitHub/txtconcat/example.md
==========
# Example
...
==========
```

## Legacy Scripts

The previous PowerShell 7 implementation remains available as `txtconcat.ps1`.
Older purpose-specific PowerShell scripts are kept in `legacy/`.

## Maintainer Setup

Maintainers can enable the repository git hook checks with:

```sh
python3 scripts/install_git_hooks.py
```

The pre-commit hook checks staged text files for the local `USER_NAME` value and
blocks accidental local path or username leaks before they are committed.

---

# txtconcat 日本語版

指定したフォルダ内のテキストファイルを1つのテキストファイルに結合する、
macOS向けの小さなshell scriptです。

## 要件

- macOS `/bin/sh`
- macOS標準のコマンドラインツール (`find`, `sort`, `grep`, `cat`, `awk`)

## 使い方

カレントフォルダの対象ファイルを結合します。

```sh
./txtconcat.sh
```

サブフォルダも含めます。

```sh
./txtconcat.sh --recurse
```

入力フォルダを指定します。

```sh
./txtconcat.sh --source-dir ./src
```

複数フォルダを指定します。

```sh
./txtconcat.sh --source-dirs ./src,./docs
```

出力先を指定します。

```sh
./txtconcat.sh --output-dir ./out
```

拡張子を指定します。

```sh
./txtconcat.sh --extensions .txt,.md,.py
```

拡張子ではなく、ファイル内容からテキストファイルを自動判定します。

```sh
./txtconcat.sh --auto-text
```

## オプション

| Option | Default | Description |
| --- | --- | --- |
| `--source-dir` | current directory | 入力フォルダを1つ指定します。 |
| `--source-dirs` | current directory | 入力フォルダを複数指定します。`--source-dir` とは同時指定できません。 |
| `--output-dir` | current directory | 出力先フォルダを指定します。 |
| `--recurse` | off | サブフォルダを含めます。 |
| `--auto-text` | off | 拡張子ではなく内容からテキストファイルを判定します。 |
| `--extensions` | 対象ファイルの選び方を参照 | `--auto-text` 未指定時の対象拡張子または完全一致ファイル名です。 |
| `--exclude-dirs` | 対象ファイルの選び方を参照 | `--recurse` 時などに除外するディレクトリ名です。 |
| `--delimiter` | `==========` | ファイル境界の区切り文字です。 |
| `--prefix` | `txtconcat` | 出力ファイル名の接頭辞です。 |
| `--include-generated-files` | off | 通常は除外される生成済み出力ファイルを入力対象に含めます。 |
| `--no-home-placeholder` | off | ホーム配下のパスを `~` に置換せず、絶対パスのまま出力します。 |

## 対象ファイルの選び方

通常は拡張子で対象ファイルを選びます。
既定では次の拡張子が対象です。

```text
.txt
.md
.markdown
.json
.jsonl
.yaml
.yml
.toml
.xml
.html
.htm
.css
.scss
.js
.jsx
.ts
.tsx
.py
.ps1
.sh
.bash
.zsh
.sql
.csv
.tsv
.log
.env
.ini
.cfg
.conf
.gitignore
.dockerignore
```

既定の対象は、ソースコード、設定、ドキュメント、ログを広めに拾う方針です。
拡張子に関係なくテキストらしいファイルを拾いたい場合は `--auto-text` を使います。

`--auto-text` を指定した場合は、拡張子ではなくファイル内容からテキストファイルかどうかを判定します。
先頭最大8192バイトを読み、次の条件で判定します。

- 空ファイルはテキスト扱い
- NULバイトを含むファイルはバイナリ扱い
- UTF-8 / UTF-16 / UTF-32 のBOMを持つファイルはテキスト扱い
- 制御文字の割合が30%未満ならテキスト扱い

既定では、生成済みの `txtconcat_*.txt` と `txtconcat_*_list.txt` は入力対象から除外します。
また、`--recurse` 時などは次のディレクトリを既定で除外します。

```text
.git
out
temp
node_modules
dist
build
target
.venv
venv
__pycache__
.cache
.next
.nuxt
coverage
```

## 出力

実行すると、出力先フォルダに2ファイル作成します。

- `txtconcat_yyyyMMdd-HHmmssfff.txt`
- `txtconcat_yyyyMMdd-HHmmssfff_list.txt`

結合結果は各ファイルごとに、パス、区切り、本文、区切りの順で出力します。

```text
~/Documents/GitHub/txtconcat/example.md
==========
# Example
...
==========
```

## 旧スクリプト

PowerShell 7版は `txtconcat.ps1` として残しています。
移行前の用途別PowerShellスクリプトは `legacy/` に残しています。

## メンテナ向けセットアップ

メンテナは次のコマンドでリポジトリの git hook チェックを有効化できます。

```sh
python3 scripts/install_git_hooks.py
```

pre-commit hook は staged text files にローカルの `USER_NAME` 値が含まれていないかを確認し、
ローカルパスやユーザー名の混入を commit 前に止めます。
