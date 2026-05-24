#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string]$SourceDir,
    [string[]]$SourceDirs,
    [string]$OutputDir = (Get-Location).Path,
    [switch]$Recurse,
    [switch]$AutoText,
    [string[]]$Extensions = @(".txt", ".md", ".json", ".jsonl", ".html", ".htm", ".py", ".ps1", ".log"),
    [string[]]$ExcludeDirs = @(".git", "out", "temp"),
    [string]$Delimiter = "==========",
    [string]$Prefix = "txtconcat",
    [Alias("x")]
    [bool]$ExcludeGeneratedFiles = $true,
    [Alias("u")]
    [bool]$UseHomePlaceholder = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($SourceDir -and $SourceDirs) {
    throw "Specify either -SourceDir or -SourceDirs, not both."
}

function Resolve-InputDirectories {
    param(
        [string]$SingleDir,
        [string[]]$MultipleDirs
    )

    $paths = if ($MultipleDirs) {
        $MultipleDirs
    } elseif ([string]::IsNullOrWhiteSpace($SingleDir)) {
        @((Get-Location).Path)
    } else {
        @($SingleDir)
    }

    foreach ($path in (Expand-CommaSeparatedValues -Values $paths)) {
        (Resolve-Path -LiteralPath $path).Path
    }
}

function Expand-CommaSeparatedValues {
    param([string[]]$Values)

    foreach ($value in $Values) {
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        $value -split "," |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }
}

function Normalize-Extensions {
    param([string[]]$Values)

    Expand-CommaSeparatedValues -Values $Values |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object {
            $value = $_.Trim()
            if ($value.StartsWith(".")) { $value.ToLowerInvariant() } else { ".$($value.ToLowerInvariant())" }
        } |
        Sort-Object -Unique
}

function Test-IsGeneratedConcatFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$GeneratedPrefix
    )

    $name = [IO.Path]::GetFileName($Path)
    return ($name -like "$GeneratedPrefix`_*.txt") -or ($name -like "$GeneratedPrefix`_*_list.txt")
}

function Test-IsUnderExcludedDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string[]]$DirectoryNames
    )

    if (-not $DirectoryNames -or $DirectoryNames.Count -eq 0) { return $false }

    $comparison = if ($IsWindows) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
    $excluded = [Collections.Generic.HashSet[string]]::new($comparison)
    foreach ($name in (Expand-CommaSeparatedValues -Values $DirectoryNames)) {
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            [void]$excluded.Add($name.Trim())
        }
    }

    $parts = $Path -split "[/\\]+"
    foreach ($part in $parts) {
        if ($excluded.Contains($part)) { return $true }
    }

    return $false
}

function Test-IsTextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$SampleSize = 8192
    )

    $stream = $null
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        if ($stream.Length -eq 0) { return $true }

        $length = [int][Math]::Min([int64]$SampleSize, $stream.Length)
        $buffer = [byte[]]::new($length)
        [void]$stream.Read($buffer, 0, $length)

        if ($buffer -contains 0) { return $false }

        if ($length -ge 3 -and $buffer[0] -eq 0xEF -and $buffer[1] -eq 0xBB -and $buffer[2] -eq 0xBF) { return $true }
        if ($length -ge 2 -and (($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE) -or ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF))) { return $true }
        if (
            $length -ge 4 -and (
                ($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE -and $buffer[2] -eq 0x00 -and $buffer[3] -eq 0x00) -or
                ($buffer[0] -eq 0x00 -and $buffer[1] -eq 0x00 -and $buffer[2] -eq 0xFE -and $buffer[3] -eq 0xFF)
            )
        ) { return $true }

        $control = 0
        foreach ($byte in $buffer) {
            if (($byte -lt 0x09) -or ($byte -ge 0x0E -and $byte -lt 0x20) -or $byte -eq 0x7F) {
                $control++
            }
        }

        return (($control / [double]$length) -lt 0.3)
    } catch {
        return $false
    } finally {
        if ($stream) { $stream.Dispose() }
    }
}

function Convert-DisplayPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [bool]$UsePlaceholder
    )

    if (-not $UsePlaceholder) { return $Path }

    $homePath = if (-not [string]::IsNullOrWhiteSpace($HOME)) {
        $HOME
    } else {
        [Environment]::GetEnvironmentVariable("USERPROFILE")
    }

    if ([string]::IsNullOrWhiteSpace($homePath)) { return $Path }

    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $root = [IO.Path]::TrimEndingDirectorySeparator((Resolve-Path -LiteralPath $homePath).Path)

    if ([string]::Equals($Path, $root, $comparison)) {
        return "~"
    }

    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if ($Path.StartsWith($prefix, $comparison)) {
        return "~" + [IO.Path]::DirectorySeparatorChar + $Path.Substring($prefix.Length)
    }

    return $Path
}

function Get-SourceFiles {
    param(
        [string[]]$Directories,
        [bool]$IncludeSubdirectories,
        [bool]$UseAutoText,
        [string[]]$AllowedExtensions,
        [string[]]$ExcludedDirectoryNames,
        [string[]]$OutputPaths,
        [bool]$SkipGenerated,
        [string]$GeneratedPrefix
    )

    $excluded = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($path in $OutputPaths) {
        [void]$excluded.Add($path)
    }

    $childItemArgs = @{
        File = $true
    }
    if ($IncludeSubdirectories) {
        $childItemArgs.Recurse = $true
    }

    $candidates = foreach ($directory in $Directories) {
        Get-ChildItem -LiteralPath $directory @childItemArgs
    }

    $candidates |
        Where-Object {
            if ($excluded.Contains($_.FullName)) { return $false }
            if (Test-IsUnderExcludedDirectory -Path $_.FullName -DirectoryNames $ExcludedDirectoryNames) { return $false }
            if ($SkipGenerated -and (Test-IsGeneratedConcatFile -Path $_.FullName -GeneratedPrefix $GeneratedPrefix)) { return $false }
            if ($UseAutoText) { return (Test-IsTextFile -Path $_.FullName) }
            return ($AllowedExtensions -contains $_.Extension.ToLowerInvariant())
        } |
        Sort-Object FullName -Unique
}

$sourceDirectories = @(Resolve-InputDirectories -SingleDir $SourceDir -MultipleDirs $SourceDirs)
$outputDirectory = (Resolve-Path -LiteralPath $OutputDir).Path
$normalizedExtensions = @(Normalize-Extensions -Values $Extensions)

if (-not $AutoText -and $normalizedExtensions.Count -eq 0) {
    throw "Specify at least one extension, or use -AutoText."
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmssfff"
$outputFile = Join-Path $outputDirectory ("{0}_{1}.txt" -f $Prefix, $timestamp)
$listFile = Join-Path $outputDirectory ("{0}_{1}_list.txt" -f $Prefix, $timestamp)

$files = @(
    Get-SourceFiles `
        -Directories $sourceDirectories `
        -IncludeSubdirectories $Recurse.IsPresent `
        -UseAutoText $AutoText.IsPresent `
        -AllowedExtensions $normalizedExtensions `
        -ExcludedDirectoryNames $ExcludeDirs `
        -OutputPaths @($outputFile, $listFile) `
        -SkipGenerated $ExcludeGeneratedFiles `
        -GeneratedPrefix $Prefix
)

$files |
    ForEach-Object { $_.FullName } |
    ForEach-Object { Convert-DisplayPath -Path $_ -UsePlaceholder $UseHomePlaceholder } |
    Set-Content -LiteralPath $listFile -Encoding utf8

$content = foreach ($file in $files) {
    Convert-DisplayPath -Path $file.FullName -UsePlaceholder $UseHomePlaceholder
    $Delimiter
    try {
        Get-Content -LiteralPath $file.FullName -Encoding utf8
    } catch {
        Get-Content -LiteralPath $file.FullName
    }
    $Delimiter
}

$content | Set-Content -LiteralPath $outputFile -Encoding utf8

[PSCustomObject]@{
    OutputFile = $outputFile
    ListFile = $listFile
    FileCount = $files.Count
}
