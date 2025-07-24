function Split-FilesIntoChunks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [Parameter(Mandatory)]
        [string]$BaseOutputDir,

        [Parameter(Mandatory)]
        [ValidateScript({$_ -gt 0})]
        [Int64]$ChunkSizeBytes
    )

    # Ensure base output directory exists
    if (-not (Test-Path $BaseOutputDir)) {
        New-Item -ItemType Directory -Path $BaseOutputDir -Force | Out-Null
    }

    $iteration = 1
    $currentChunkSize = 0
    $filesInChunk = @()

    Import-Csv $ManifestPath | ForEach-Object {
        $fileSize = [int64]$_.'Length'
        $filePath = $_.'FullName'
        if (($currentChunkSize + $fileSize) -gt $ChunkSizeBytes -and $filesInChunk.Count -gt 0) {
            $outputDir = "${BaseOutputDir}${iteration}"
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            foreach ($f in $filesInChunk) {
                if (![string]::IsNullOrWhiteSpace($f) -and (Test-Path $f)) {
                    try {
                        Copy-Item -Path $f -Destination $outputDir -ErrorAction Stop
                    } catch {
                        Write-Warning "Failed to copy '$f': $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "Skipping invalid file path: '$f'"
                }
            }
            $iteration++
            $currentChunkSize = 0
            $filesInChunk = @()
        }
        if (![string]::IsNullOrWhiteSpace($filePath)) {
            $filesInChunk += $filePath
            $currentChunkSize += $fileSize
        }
    }

    # Copy any remaining files
    if ($filesInChunk.Count -gt 0) {
        $outputDir = "${BaseOutputDir}${iteration}"
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        foreach ($f in $filesInChunk) {
            if (![string]::IsNullOrWhiteSpace($f) -and (Test-Path $f)) {
                try {
                    Copy-Item -Path $f -Destination $outputDir -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to copy '$f': $($_.Exception.Message)"
                }
            } else {
                Write-Warning "Skipping invalid file path: '$f'"
            }
        }
    }
}

Export-ModuleMember -Function Split-FilesIntoChunks