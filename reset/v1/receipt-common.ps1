Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue)) {
    $global:LASTEXITCODE = 0
}

function Get-PortableReceiptRoot {
    param([string]$CodexHome)

    return Join-Path $CodexHome "portable-receipts"
}

function Get-PortableCurrentReceipt {
    param([string]$CodexHome)

    $path = Join-Path (Get-PortableReceiptRoot -CodexHome $CodexHome) "current.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }

    try {
        $receipt = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    }
    catch {
        throw "invalid current installation receipt: $path"
    }
    if ($receipt.schema_version -ne 1 -or -not $receipt.id) {
        throw "unsupported current installation receipt: $path"
    }
    return $receipt
}

function Get-PortableReceipt {
    param(
        [string]$CodexHome,
        [string]$Receipt
    )

    if ([string]::IsNullOrWhiteSpace($Receipt)) {
        throw "receipt id must be non-empty"
    }
    if ($Receipt -match '[\\/]' -or $Receipt -notmatch '^[A-Za-z0-9._-]+$') {
        throw "receipt id must be a filename-safe id, not a path"
    }

    $fileName = if ($Receipt.EndsWith(".json", [System.StringComparison]::OrdinalIgnoreCase)) {
        $Receipt
    }
    else {
        "$Receipt.json"
    }
    $path = Join-Path (Get-PortableReceiptRoot -CodexHome $CodexHome) $fileName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "installation receipt not found: $Receipt"
    }

    try {
        $data = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    }
    catch {
        throw "invalid installation receipt: $path"
    }
    if ($data.schema_version -ne 1 -or -not $data.id) {
        throw "unsupported installation receipt: $path"
    }
    return $data
}

function Test-PortableReceiptOwnsTarget {
    param(
        [AllowNull()]
        [object]$Receipt,
        [string]$Target
    )

    if ($null -eq $Receipt) {
        return $false
    }
    foreach ($artifact in @($Receipt.artifacts)) {
        if ($artifact.target -and $artifact.target.Equals($Target, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-PortableReceiptArtifact {
    param(
        [AllowNull()]
        [object]$Receipt,
        [string]$Target
    )

    if ($null -eq $Receipt) {
        return $null
    }
    foreach ($artifact in @($Receipt.artifacts)) {
        if ($artifact.target -and $artifact.target.Equals($Target, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $artifact
        }
    }
    return $null
}

function Get-PortableReparseIdentity {
    param(
        [object]$Item,
        [string]$RelativePath
    )

    $isReparsePoint = ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    if (-not $isReparsePoint) {
        return $null
    }

    $linkTypeProperty = $Item.PSObject.Properties["LinkType"]
    $targetProperty = $Item.PSObject.Properties["Target"]
    $linkType = if ($null -ne $linkTypeProperty) {
        [string]$linkTypeProperty.Value
    }
    else {
        ""
    }
    $targets = @(
        if ($null -ne $targetProperty) {
            @($targetProperty.Value | ForEach-Object { [string]$_ } | Sort-Object)
        }
    )

    return [ordered]@{
        path = $RelativePath
        link_type = $linkType
        targets = $targets
    }
}

function Get-PortablePathFingerprint {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [ordered]@{
            exists = $false
            kind = "missing"
            files = @()
            directories = @()
            reparse_points = @()
        }
    }

    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer) {
        $targetReparseIdentity = Get-PortableReparseIdentity -Item $item -RelativePath ""
        return [ordered]@{
            exists = $true
            kind = "file"
            files = @(
                [ordered]@{
                    path = ""
                    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
                }
            )
            directories = @()
            reparse_points = @(
                if ($null -ne $targetReparseIdentity) {
                    $targetReparseIdentity
                }
            )
        }
    }

    $root = $item.FullName
    $separatorChars = @(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) | Select-Object -Unique
    $entries = @(Get-ChildItem -LiteralPath $root -Recurse -Force | Sort-Object FullName)
    $files = @(
        foreach ($file in @($entries | Where-Object { -not $_.PSIsContainer })) {
            [ordered]@{
                path = $file.FullName.Substring($root.Length).TrimStart($separatorChars).Replace("\", "/")
                sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
            }
        }
    )
    $directories = @(
        foreach ($directory in @($entries | Where-Object { $_.PSIsContainer })) {
            $directory.FullName.Substring($root.Length).TrimStart($separatorChars).Replace("\", "/")
        }
    )
    $reparsePoints = @(
        $targetReparseIdentity = Get-PortableReparseIdentity -Item $item -RelativePath ""
        if ($null -ne $targetReparseIdentity) {
            $targetReparseIdentity
        }
        foreach ($entry in $entries) {
            $relativePath = $entry.FullName.Substring($root.Length).TrimStart($separatorChars).Replace("\", "/")
            $entryReparseIdentity = Get-PortableReparseIdentity -Item $entry -RelativePath $relativePath
            if ($null -ne $entryReparseIdentity) {
                $entryReparseIdentity
            }
        }
    )

    return [ordered]@{
        exists = $true
        kind = "directory"
        files = $files
        directories = $directories
        reparse_points = $reparsePoints
    }
}

function Get-PortableFingerprintParentDirectories {
    param([object[]]$Files)

    $parents = @(
        foreach ($file in @($Files)) {
            $parts = @(([string]$file.path).Replace("\", "/") -split "/" | Where-Object { $_ })
            for ($length = 1; $length -lt $parts.Count; $length += 1) {
                $parts[0..($length - 1)] -join "/"
            }
        }
    )
    return @($parents | Sort-Object -Unique)
}

function Test-PortableFingerprintMatches {
    param(
        [AllowNull()]
        [object]$Expected,
        [string]$Path
    )

    if ($null -eq $Expected) {
        return $false
    }
    $actual = Get-PortablePathFingerprint -Path $Path
    if ([bool]$Expected.exists -ne [bool]$actual.exists) {
        return $false
    }
    if ([string]$Expected.kind -ne [string]$actual.kind) {
        return $false
    }

    $expectedFiles = @($Expected.files)
    $actualFiles = @($actual.files)
    if ($expectedFiles.Count -ne $actualFiles.Count) {
        return $false
    }
    for ($index = 0; $index -lt $expectedFiles.Count; $index += 1) {
        if ([string]$expectedFiles[$index].path -ne [string]$actualFiles[$index].path) {
            return $false
        }
        if ([string]$expectedFiles[$index].sha256 -ne [string]$actualFiles[$index].sha256) {
            return $false
        }
    }

    $directoryProperty = $Expected.PSObject.Properties["directories"]
    $expectedDirectories = @(
        if ($null -ne $directoryProperty) {
            @($directoryProperty.Value | ForEach-Object { [string]$_ } | Sort-Object)
        }
        else {
            @(Get-PortableFingerprintParentDirectories -Files $expectedFiles)
        }
    )
    $actualDirectories = @($actual.directories | ForEach-Object { [string]$_ } | Sort-Object)
    if ($expectedDirectories.Count -ne $actualDirectories.Count) {
        return $false
    }
    for ($index = 0; $index -lt $expectedDirectories.Count; $index += 1) {
        if ($expectedDirectories[$index] -ne $actualDirectories[$index]) {
            return $false
        }
    }

    $reparseProperty = $Expected.PSObject.Properties["reparse_points"]
    $expectedReparsePoints = @(
        if ($null -ne $reparseProperty) {
            @($reparseProperty.Value | Sort-Object { [string]$_.path })
        }
    )
    $actualReparsePoints = @($actual.reparse_points | Sort-Object { [string]$_.path })
    if ($expectedReparsePoints.Count -ne $actualReparsePoints.Count) {
        return $false
    }
    for ($index = 0; $index -lt $expectedReparsePoints.Count; $index += 1) {
        $expectedReparsePoint = $expectedReparsePoints[$index]
        $actualReparsePoint = $actualReparsePoints[$index]
        if ([string]$expectedReparsePoint.path -ne [string]$actualReparsePoint.path) {
            return $false
        }
        if ([string]$expectedReparsePoint.link_type -ne [string]$actualReparsePoint.link_type) {
            return $false
        }

        $expectedTargets = @($expectedReparsePoint.targets | ForEach-Object { [string]$_ } | Sort-Object)
        $actualTargets = @($actualReparsePoint.targets | ForEach-Object { [string]$_ } | Sort-Object)
        if ($expectedTargets.Count -ne $actualTargets.Count) {
            return $false
        }
        for ($targetIndex = 0; $targetIndex -lt $expectedTargets.Count; $targetIndex += 1) {
            if ($expectedTargets[$targetIndex] -ne $actualTargets[$targetIndex]) {
                return $false
            }
        }
    }
    return $true
}

function Write-PortableReceipt {
    param(
        [string]$CodexHome,
        [object]$Receipt
    )

    $receiptRoot = Get-PortableReceiptRoot -CodexHome $CodexHome
    New-Item -ItemType Directory -Force $receiptRoot | Out-Null

    $json = $Receipt | ConvertTo-Json -Depth 12
    $receiptPath = Join-Path $receiptRoot "$($Receipt.id).json"
    $currentPath = Join-Path $receiptRoot "current.json"
    $tempReceipt = "$receiptPath.tmp-$([guid]::NewGuid().ToString('N'))"
    $tempCurrent = "$currentPath.tmp-$([guid]::NewGuid().ToString('N'))"

    [System.IO.File]::WriteAllText($tempReceipt, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tempReceipt -Destination $receiptPath -Force
    [System.IO.File]::WriteAllText($tempCurrent, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tempCurrent -Destination $currentPath -Force

    return $receiptPath
}

function Test-PortablePathUnderAnyRoot {
    param(
        [string]$Path,
        [string[]]$Roots
    )

    foreach ($root in $Roots) {
        if (-not $root) {
            continue
        }
        try {
            Assert-PathUnderRoot -Path $Path -Root $root
            return $true
        }
        catch {
        }
    }
    return $false
}
