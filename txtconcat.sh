#!/bin/sh
set -eu

usage() {
    cat <<'EOF'
Usage: ./txtconcat.sh [options]

Options:
  --source-dir DIR              Read files from one directory.
  --source-dirs DIRS            Read files from comma-separated directories.
  --output-dir DIR              Write output files to DIR. Default: current directory.
  --recurse                     Include subdirectories.
  --auto-text                   Detect text files by content instead of extension.
  --extensions EXTENSIONS       Comma-separated extensions or exact file names.
  --exclude-dirs DIRS           Comma-separated directory names to skip.
  --delimiter TEXT              Separator text. Default: ==========
  --prefix TEXT                 Output file prefix. Default: txtconcat
  --include-generated-files     Include generated txtconcat output files.
  --no-home-placeholder         Keep absolute home paths instead of replacing with ~.
  -h, --help                    Show this help.
EOF
}

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

resolve_dir() {
    [ -n "$1" ] || die "Directory path is empty."
    [ -d "$1" ] || die "Directory not found: $1"
    (cd "$1" && pwd -P)
}

append_csv_lines() {
    printf '%s\n' "$1" | awk '
        {
            n = split($0, parts, ",")
            for (i = 1; i <= n; i++) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
                if (parts[i] != "") print parts[i]
            }
        }
    '
}

normalize_extensions() {
    awk '
        {
            value = tolower($0)
            if (value == "") next
            if (substr(value, 1, 1) != ".") value = "." value
            print value
        }
    ' | sort -u
}

contains_line() {
    contains_line_needle=$1
    contains_line_file=$2
    grep -Fxq -- "$contains_line_needle" "$contains_line_file"
}

is_under_excluded_dir() {
    path=$1
    excluded_file=$2

    [ -s "$excluded_file" ] || return 1
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        case "$path" in
            */"$name"/*) return 0 ;;
        esac
    done < "$excluded_file"
    return 1
}

is_generated_concat_file() {
    path=$1
    generated_prefix=$2
    name=${path##*/}
    case "$name" in
        "$generated_prefix"_*.txt|"$generated_prefix"_*_list.txt) return 0 ;;
    esac
    return 1
}

is_text_file() {
    path=$1
    [ -s "$path" ] || return 0
    LC_ALL=C grep -Iq . "$path"
}

display_path() {
    path=$1
    if [ "$use_home_placeholder" -eq 0 ] || [ -z "${HOME:-}" ]; then
        printf '%s\n' "$path"
        return
    fi

    home_root=$(resolve_dir "$HOME")
    case "$path" in
        "$home_root") printf '~\n' ;;
        "$home_root"/*) printf '~/%s\n' "${path#"$home_root"/}" ;;
        *) printf '%s\n' "$path" ;;
    esac
}

collect_files_for_dir() {
    dir=$1
    if [ "$recurse" -eq 1 ]; then
        find "$dir" -type f
    else
        find "$dir" \( -type d ! -path "$dir" -prune \) -o -type f -print
    fi
}

source_dir=
source_dirs=
output_dir=.
recurse=0
auto_text=0
extensions='.txt,.md,.markdown,.json,.jsonl,.yaml,.yml,.toml,.xml,.html,.htm,.css,.scss,.js,.jsx,.ts,.tsx,.py,.ps1,.sh,.bash,.zsh,.sql,.csv,.tsv,.log,.env,.ini,.cfg,.conf,.gitignore,.dockerignore'
exclude_dirs='.git,out,temp,node_modules,dist,build,target,.venv,venv,__pycache__,.cache,.next,.nuxt,coverage'
delimiter='=========='
prefix='txtconcat'
exclude_generated_files=1
use_home_placeholder=1

while [ "$#" -gt 0 ]; do
    case "$1" in
        --source-dir) [ "$#" -ge 2 ] || die "--source-dir requires a value."; source_dir=$2; shift 2 ;;
        --source-dirs) [ "$#" -ge 2 ] || die "--source-dirs requires a value."; source_dirs=$2; shift 2 ;;
        --output-dir) [ "$#" -ge 2 ] || die "--output-dir requires a value."; output_dir=$2; shift 2 ;;
        --recurse) recurse=1; shift ;;
        --auto-text) auto_text=1; shift ;;
        --extensions) [ "$#" -ge 2 ] || die "--extensions requires a value."; extensions=$2; shift 2 ;;
        --exclude-dirs) [ "$#" -ge 2 ] || die "--exclude-dirs requires a value."; exclude_dirs=$2; shift 2 ;;
        --delimiter) [ "$#" -ge 2 ] || die "--delimiter requires a value."; delimiter=$2; shift 2 ;;
        --prefix) [ "$#" -ge 2 ] || die "--prefix requires a value."; prefix=$2; shift 2 ;;
        --include-generated-files) exclude_generated_files=0; shift ;;
        --no-home-placeholder) use_home_placeholder=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[ -z "$source_dir" ] || [ -z "$source_dirs" ] || die "Specify either --source-dir or --source-dirs, not both."

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/txtconcat.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

source_file=$tmp_dir/source_dirs
extensions_file=$tmp_dir/extensions
exclude_dirs_file=$tmp_dir/exclude_dirs
candidates_file=$tmp_dir/candidates
files_file=$tmp_dir/files

if [ -n "$source_dirs" ]; then
    append_csv_lines "$source_dirs" > "$source_file"
elif [ -n "$source_dir" ]; then
    printf '%s\n' "$source_dir" > "$source_file"
else
    pwd -P > "$source_file"
fi

resolved_source_file=$tmp_dir/resolved_source_dirs
while IFS= read -r dir; do
    resolve_dir "$dir"
done < "$source_file" > "$resolved_source_file"
mv "$resolved_source_file" "$source_file"

output_dir=$(resolve_dir "$output_dir")
append_csv_lines "$extensions" | normalize_extensions > "$extensions_file"
append_csv_lines "$exclude_dirs" > "$exclude_dirs_file"

if [ "$auto_text" -eq 0 ] && [ ! -s "$extensions_file" ]; then
    die "Specify at least one extension, or use --auto-text."
fi

timestamp=$(date '+%Y%m%d-%H%M%S')
stamp_tail=$(printf '%03d' "$(( $$ % 1000 ))")
output_file=$output_dir/${prefix}_${timestamp}${stamp_tail}.txt
list_file=$output_dir/${prefix}_${timestamp}${stamp_tail}_list.txt

: > "$candidates_file"
while IFS= read -r dir; do
    collect_files_for_dir "$dir" >> "$candidates_file"
done < "$source_file"

sort -u "$candidates_file" | while IFS= read -r file; do
    [ "$file" != "$output_file" ] || continue
    [ "$file" != "$list_file" ] || continue
    ! is_under_excluded_dir "$file" "$exclude_dirs_file" || continue
    if [ "$exclude_generated_files" -eq 1 ] && is_generated_concat_file "$file" "$prefix"; then
        continue
    fi
    if [ "$auto_text" -eq 1 ]; then
        is_text_file "$file" || continue
    else
        name=$(printf '%s\n' "${file##*/}" | awk '{ print tolower($0) }')
        ext=
        case "$name" in
            *.*) ext=.${name##*.} ;;
        esac
        if ! contains_line "$name" "$extensions_file" && ! contains_line "$ext" "$extensions_file"; then
            continue
        fi
    fi
    printf '%s\n' "$file"
done > "$files_file"

: > "$list_file"
: > "$output_file"

while IFS= read -r file; do
    display=$(display_path "$file")
    printf '%s\n' "$display" >> "$list_file"
    {
        printf '%s\n' "$display"
        printf '%s\n' "$delimiter"
        cat "$file"
        printf '\n%s\n' "$delimiter"
    } >> "$output_file"
done < "$files_file"

printf 'OutputFile\tListFile\tFileCount\n'
printf '%s\t%s\t%s\n' "$output_file" "$list_file" "$(wc -l < "$files_file" | tr -d ' ')"
