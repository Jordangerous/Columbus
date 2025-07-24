#import chunking module from ./modules/chunking/chunk.psm1
$modulePath = Join-Path $PSScriptRoot 'modules\chunking\chunk.psm1'
if (Test-Path $modulePath) {
	Import-Module $modulePath -Force
} else {
	Write-Error "Module not found at $modulePath"
	exit 1
}

# Example usage:
$manifestPath = Join-Path $PSScriptRoot '..\datafiles\2025-07-24-14-24-20\manifest.csv'
#create this path item
$baseOutputDir = Join-Path $PSScriptRoot '..\datafiles\2025-07-24-14-24-20\migrations'

$chunkSizeBytes = 107374182400 # 100 GB

Split-FilesIntoChunks -ManifestPath $manifestPath -BaseOutputDir $baseOutputDir -ChunkSizeBytes $chunkSizeBytes