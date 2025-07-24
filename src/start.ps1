# Get base directory of the script
$BaseDir = $PSScriptRoot
$WorkerModule = Join-Path $BaseDir 'modules/worker/worker.psm1'

# Prompt user for a directory
$defaultDir = 'C:\'
$inputDir = Read-Host "Enter the directory to scan (press Enter for default: '$defaultDir')"

# Import the worker module to make Invoke-WorkerTask available
Import-Module $WorkerModule -Force

$SessionRoot = Join-Path $BaseDir 'sessions'
$SessionDir = Join-Path $SessionRoot (Get-Date -Format "yyyy-MM-dd-HH-mm-ss")
New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null
# Define inventory schema (empty object with correct properties)

$dummy = [pscustomobject]@{
    FullName       = ''
    Name           = ''
    Length         = 0
    Extension      = ''
    LastWriteTime  = ''
    Status         = ''
    ErrorMessage   = ''
    Timestamp      = ''
    Owner          = ''
    PathLength     = 0
}

# Pre-create empty CSVs with headers
$Inventory1Path = Join-Path $SessionDir 'inventory_1.csv'
$Inventory2Path = Join-Path $SessionDir 'inventory_2.csv'

$dummy | Export-Csv -Path $Inventory1Path -NoTypeInformation
$dummy | Export-Csv -Path $Inventory2Path -NoTypeInformation

#Dispatch worker with target directory, session path and filter query
$SourcePath = if ($inputDir) { $inputDir } else { $defaultDir }
$UserPrincipalName = "$env:USERNAME@domain.mil"
$SchemaModule = Join-Path $BaseDir 'modules/models/schema.psm1'
$ScannerModule = Join-Path $BaseDir 'modules/scanner/scanner.psm1'

#dispatch worker with target directory, session path and filter query
Write-Host "Starting scan on $SourcePath with session path $SessionDir" 
Write-Host "User: $UserPrincipalName"

# Start background jobs for concurrent scanning
Write-Host "Starting background jobs for concurrent scanning..."

$Job1 = Start-Job -ScriptBlock {
    param($WorkerModule, $SourcePath, $SessionDir, $UserPrincipalName, $SchemaModule, $ScannerModule)
    
    Import-Module $WorkerModule -Force
    
    Invoke-WorkerTask -TaskName 'StartScan' -TaskParams @{
        SourcePath          = $SourcePath
        SessionPath         = $SessionDir
        UserPrincipalName   = $UserPrincipalName
        FilterScript        = '$_.FullName.Length -ge 400'
        SchemaModule        = $SchemaModule
        ScannerModule       = $ScannerModule
    }
} -ArgumentList $WorkerModule, $SourcePath, $SessionDir, $UserPrincipalName, $SchemaModule, $ScannerModule -Name "LongPathScan"

$Job2 = Start-Job -ScriptBlock {
    param($WorkerModule, $SourcePath, $SessionDir, $UserPrincipalName, $SchemaModule, $ScannerModule)
    
    Import-Module $WorkerModule -Force
    
    Invoke-WorkerTask -TaskName 'StartScan' -TaskParams @{
        SourcePath          = $SourcePath
        SessionPath         = $SessionDir
        UserPrincipalName   = $UserPrincipalName
        FilterScript        = '$_.FullName.Length -lt 400'
        SchemaModule        = $SchemaModule
        ScannerModule       = $ScannerModule
    }
} -ArgumentList $WorkerModule, $SourcePath, $SessionDir, $UserPrincipalName, $SchemaModule, $ScannerModule -Name "ShortPathScan"

Write-Host "Background jobs started:"
Write-Host "  Job 1 (Long paths >=400): $($Job1.Id)"
Write-Host "  Job 2 (Short paths <400): $($Job2.Id)"
Write-Host "Waiting for jobs to complete..."

# Wait for both jobs to complete
$Jobs = @($Job1, $Job2)
$Jobs | Wait-Job | Out-Null

# Get job results and display any output
Write-Host "`nJob Results:"
foreach ($Job in $Jobs) {
    Write-Host "Job $($Job.Name) ($($Job.Id)): $($Job.State)"
    $JobOutput = Receive-Job -Job $Job
    if ($JobOutput) {
        Write-Host "Output from $($Job.Name):"
        $JobOutput | ForEach-Object { Write-Host "  $_" }
    }
}

# Clean up jobs
$Jobs | Remove-Job

Write-Host "`nBoth scans completed successfully!"

# Combine both CSV files into a single inventory
Write-Host "`nCombining CSV files..."
$CombinedPath = Join-Path $SessionDir 'inventory_combined.csv'

# Read both CSV files (excluding headers from the second file)
$Inventory1 = Import-Csv -Path $Inventory1Path
$Inventory2 = Import-Csv -Path $Inventory2Path

# Filter out empty rows (the dummy rows we created initially)
$Inventory1Filtered = $Inventory1 | Where-Object { $_.FullName -ne '' }
$Inventory2Filtered = $Inventory2 | Where-Object { $_.FullName -ne '' }

# Combine the data
$CombinedInventory = @()
$CombinedInventory += $Inventory1Filtered
$CombinedInventory += $Inventory2Filtered

# Export the combined inventory
$CombinedInventory | Export-Csv -Path $CombinedPath -NoTypeInformation

Write-Host "Combined inventory created: $CombinedPath"
Write-Host "Total files in combined inventory: $($CombinedInventory.Count)"
Write-Host "Files with long paths (>=400 chars): $($Inventory1Filtered.Count)"
Write-Host "Files with short paths (<400 chars): $($Inventory2Filtered.Count)"