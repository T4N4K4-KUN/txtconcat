param(
    [Alias("u")]
    [bool]$UseUserProfilePlaceholder = $true,
    [Alias("x")]
    [bool]$ExcludeGeneratedFiles = $true
)

$dir=Join-Path (Get-Location).Path "temp"
$delim="=========="
$ts=Get-Date -Format "yyyyMMdd-HHmmssfff"
$out=Join-Path $dir ("txtconcat_{0}.txt" -f $ts)
$list=Join-Path $dir ("{0}_list.txt" -f ([IO.Path]::GetFileNameWithoutExtension($out)))

function Test-IsGeneratedConcatFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    $name = [IO.Path]::GetFileName($Path)
    return ($name -like "txtconcat_*.txt") -or ($name -like "txtconcat_*_list.txt")
}

function Convert-DisplayPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not $UseUserProfilePlaceholder) { return $Path }
    $userProfile = [Environment]::GetEnvironmentVariable("USERPROFILE")
    if ([string]::IsNullOrWhiteSpace($userProfile)) { return $Path }
    $root = $userProfile.TrimEnd('\')
    if ($Path -ieq $root) { return "%USERPROFILE%" }
    if ($Path -like "$root\*") { return "%USERPROFILE%" + $Path.Substring($root.Length) }
    return $Path
}

$files=Get-ChildItem -Path $dir -Recurse -File -Include *.txt,*.md,*.json,*.jsonl,*.html,*.htm,*.py |
Where-Object {
    $_.FullName -ne $out -and
    $_.FullName -ne $list -and
    (-not $ExcludeGeneratedFiles -or -not (Test-IsGeneratedConcatFile -Path $_.FullName))
} |
Sort-Object FullName

$files | ForEach-Object { Convert-DisplayPath $_.FullName } | Set-Content -Encoding utf8 $list
$files | ForEach-Object {
    $p=$_.FullName
    Convert-DisplayPath $p
    $delim
    try {
        Get-Content -LiteralPath $p -Encoding utf8 -ErrorAction Stop
    } catch {
        Get-Content -LiteralPath $p -Encoding oem
    }
    $delim
} | Set-Content -Encoding utf8 $out
