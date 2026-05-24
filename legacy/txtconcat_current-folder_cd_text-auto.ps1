param(
    [Alias("u")]
    [bool]$UseUserProfilePlaceholder = $true,
    [Alias("x")]
    [bool]$ExcludeGeneratedFiles = $true,
    [string]$SourceDir,
    [string[]]$SourceDirs,
    [string]$OutputDir = (Get-Location).Path
)

if ($SourceDirs -and $SourceDir) {
    throw "Specify either -SourceDir or -SourceDirs, not both."
}

if (-not $SourceDirs) {
    if ([string]::IsNullOrWhiteSpace($SourceDir)) {
        $SourceDirs = @((Get-Location).Path)
    } else {
        $SourceDirs = @($SourceDir)
    }
}

$dirs = $SourceDirs | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }
$output = (Resolve-Path -LiteralPath $OutputDir -ErrorAction Stop).Path
$delim = "=========="
$ts = Get-Date -Format "yyyyMMdd-HHmmssfff"
$out = Join-Path $output ("txtconcat_{0}.txt" -f $ts)
$list = Join-Path $output ("{0}_list.txt" -f ([IO.Path]::GetFileNameWithoutExtension($out)))

function Test-IsTextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$SampleSize = 8192
    )

    try {
        $fs = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            if ($fs.Length -eq 0) { return $true }
            $len = [int][Math]::Min([int64]$SampleSize, $fs.Length)
            $buffer = New-Object byte[] $len
            [void]$fs.Read($buffer, 0, $len)
        } finally {
            $fs.Dispose()
        }

        if ($buffer -contains 0) { return $false }

        if ($len -ge 3 -and $buffer[0] -eq 0xEF -and $buffer[1] -eq 0xBB -and $buffer[2] -eq 0xBF) { return $true }
        if ($len -ge 2 -and (($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE) -or ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF))) { return $true }
        if (
            $len -ge 4 -and (
                ($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE -and $buffer[2] -eq 0x00 -and $buffer[3] -eq 0x00) -or
                ($buffer[0] -eq 0x00 -and $buffer[1] -eq 0x00 -and $buffer[2] -eq 0xFE -and $buffer[3] -eq 0xFF)
            )
        ) { return $true }

        $control = 0
        foreach ($b in $buffer) {
            if (($b -lt 0x09) -or ($b -ge 0x0E -and $b -lt 0x20) -or $b -eq 0x7F) { $control++ }
        }

        return (($control / [double]$len) -lt 0.3)
    } catch {
        return $false
    }
}

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

$files = $dirs | ForEach-Object {
    Get-ChildItem -LiteralPath $_ -File
} |
Where-Object {
    $_.FullName -ne $out -and
    $_.FullName -ne $list -and
    (-not $ExcludeGeneratedFiles -or -not (Test-IsGeneratedConcatFile -Path $_.FullName)) -and
    (Test-IsTextFile -Path $_.FullName)
} |
Sort-Object FullName

$files.FullName | ForEach-Object { Convert-DisplayPath $_ } | Set-Content -Encoding utf8 $list

$files | ForEach-Object {
    $p = $_.FullName
    Convert-DisplayPath $p
    $delim
    try {
        Get-Content -LiteralPath $p -Encoding utf8 -ErrorAction Stop
    } catch {
        Get-Content -LiteralPath $p -Encoding default
    }
    $delim
} | Set-Content -Encoding utf8 $out
