# txtconcat

A PowerShell script that concatenates text files in selected directories into a single text file.
It targets PowerShell 7 (`pwsh`) so it can run on both Windows and macOS.

## Requirements

- PowerShell 7+

On macOS, you can install it with Homebrew.

```sh
brew install powershell
```

## Usage

Concatenate matching files in the current directory.

```sh
pwsh ./txtconcat.ps1
```

Include subdirectories.

```sh
pwsh ./txtconcat.ps1 -Recurse
```

Specify one source directory.

```sh
pwsh ./txtconcat.ps1 -SourceDir ./src
```

Specify multiple source directories.

```sh
pwsh ./txtconcat.ps1 -SourceDirs ./src,./docs
```

Specify an output directory.

```sh
pwsh ./txtconcat.ps1 -OutputDir ./out
```

Specify target extensions.

```sh
pwsh ./txtconcat.ps1 -Extensions .txt,.md,.py
```

Detect text files by file content instead of extension.

```sh
pwsh ./txtconcat.ps1 -AutoText
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `-SourceDir` | current directory | Specifies one input directory. |
| `-SourceDirs` | current directory | Specifies multiple input directories. Cannot be used with `-SourceDir`. |
| `-OutputDir` | current directory | Specifies the output directory. |
| `-Recurse` | off | Includes subdirectories. |
| `-AutoText` | off | Detects text files by content instead of extension. |
| `-Extensions` | see File Selection | Target extensions or exact file names when `-AutoText` is not used. |
| `-ExcludeDirs` | see File Selection | Directory names to exclude, especially when using `-Recurse`. |
| `-Delimiter` | `==========` | Separator text between files. |
| `-Prefix` | `txtconcat` | Prefix for generated output file names. |
| `-ExcludeGeneratedFiles` | `$true` | Excludes `txtconcat_*.txt` and `txtconcat_*_list.txt` from input. |
| `-UseHomePlaceholder` | `$true` | Replaces paths under the home directory with `~`. |

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
Use `-AutoText` when you want to include any file that looks like text regardless of extension.

When `-AutoText` is specified, files are checked by content instead of extension.
The script reads up to the first 8192 bytes and uses these rules:

- Empty files are treated as text.
- Files containing NUL bytes are treated as binary.
- Files with UTF-8 / UTF-16 / UTF-32 BOMs are treated as text.
- Files with less than 30% control characters are treated as text.

By default, generated `txtconcat_*.txt` and `txtconcat_*_list.txt` files are excluded from input.
These directories are also excluded by default, especially when using `-Recurse`:

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

The old purpose-specific PowerShell scripts are kept in `legacy/`.
Use `txtconcat.ps1` for normal use going forward.

---

# txtconcat 日本語版

指定したフォルダ内のテキストファイルを1つのテキストファイルに結合するPowerShellスクリプトです。
WindowsとmacOSの両方で使えるよう、PowerShell 7 (`pwsh`) 前提にしています。

## 要件

- PowerShell 7+

macOSではHomebrewでインストールできます。

```sh
brew install powershell
```

## 使い方

カレントフォルダの対象ファイルを結合します。

```sh
pwsh ./txtconcat.ps1
```

サブフォルダも含めます。

```sh
pwsh ./txtconcat.ps1 -Recurse
```

入力フォルダを指定します。

```sh
pwsh ./txtconcat.ps1 -SourceDir ./src
```

複数フォルダを指定します。

```sh
pwsh ./txtconcat.ps1 -SourceDirs ./src,./docs
```

出力先を指定します。

```sh
pwsh ./txtconcat.ps1 -OutputDir ./out
```

拡張子を指定します。

```sh
pwsh ./txtconcat.ps1 -Extensions .txt,.md,.py
```

拡張子ではなく、ファイル内容からテキストファイルを自動判定します。

```sh
pwsh ./txtconcat.ps1 -AutoText
```

## オプション

| Option | Default | Description |
| --- | --- | --- |
| `-SourceDir` | current directory | 入力フォルダを1つ指定します。 |
| `-SourceDirs` | current directory | 入力フォルダを複数指定します。`-SourceDir` とは同時指定できません。 |
| `-OutputDir` | current directory | 出力先フォルダを指定します。 |
| `-Recurse` | off | サブフォルダを含めます。 |
| `-AutoText` | off | 拡張子ではなく内容からテキストファイルを判定します。 |
| `-Extensions` | 対象ファイルの選び方を参照 | `-AutoText` 未指定時の対象拡張子または完全一致ファイル名です。 |
| `-ExcludeDirs` | 対象ファイルの選び方を参照 | `-Recurse` 時などに除外するディレクトリ名です。 |
| `-Delimiter` | `==========` | ファイル境界の区切り文字です。 |
| `-Prefix` | `txtconcat` | 出力ファイル名の接頭辞です。 |
| `-ExcludeGeneratedFiles` | `$true` | `txtconcat_*.txt` と `txtconcat_*_list.txt` を入力対象から除外します。 |
| `-UseHomePlaceholder` | `$true` | ホーム配下のパスを `~` 表記にします。 |

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
拡張子に関係なくテキストらしいファイルを拾いたい場合は `-AutoText` を使います。

`-AutoText` を指定した場合は、拡張子ではなくファイル内容からテキストファイルかどうかを判定します。
先頭最大8192バイトを読み、次の条件で判定します。

- 空ファイルはテキスト扱い
- NULバイトを含むファイルはバイナリ扱い
- UTF-8 / UTF-16 / UTF-32 のBOMを持つファイルはテキスト扱い
- 制御文字の割合が30%未満ならテキスト扱い

既定では、生成済みの `txtconcat_*.txt` と `txtconcat_*_list.txt` は入力対象から除外します。
また、`-Recurse` 時などは次のディレクトリを既定で除外します。

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

移行前の用途別PowerShellスクリプトは `legacy/` に残しています。
今後は原則として `txtconcat.ps1` を使います。
