function Start-Scan {
    param (
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$SessionPath,
        [Parameter(Mandatory)][string]$UserPrincipalName,
        [Parameter(Mandatory)][string]$FilterScript
    )

    Import-Module "$PSScriptRoot/../models/schema.psm1" -Force
    Import-Module "$PSScriptRoot/../inventory/inventory.psm1" -Force

    $Filter = [scriptblock]::Create($FilterScript)
    $blacklistedExts = Get-BlacklistedFileNames

    $matched = @()
    $unmatched = @()
    $fileCount = 0

    Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $fileCount++
        $file = $_
        #log the file being processed
        Write-Host "Processing file: $($file.FullName)"

        #if ($blacklistedExts -contains $file.Extension.ToLower()) { return }
        #if (Has-InvalidFileNameFormat -FileName $file.Name) { return }

        $relativePath = $file.FullName.Substring($SourcePath.Length).TrimStart('\')
        $oneDrivePath = "migration/$relativePath" -replace '\\', '/'

        $record = New-InventoryRecord -File $file `
                                      -RelativePath $relativePath `
                                      -OneDrivePath $oneDrivePath `
                                      -Status 'Pending'

        if (& $Filter $file) {
            $matched += $record
        } else {
            $unmatched += $record
        }

        if ($fileCount % 100 -eq 0) {
            Write-Host "[$($FilterScript)] Scanned $fileCount files..."
        }
    }

    $columns = 'FullName','Name','Extension','Length','LastWriteTime','CreationTime','Owner','RelativePath','OneDrivePath','Status','ErrorMessage','Timestamp','PathLength'

    $matched | Select-Object $columns | Export-Csv -Path (Join-Path $SessionPath 'inventory_1.csv') -NoTypeInformation -Append
    $unmatched | Select-Object $columns | Export-Csv -Path (Join-Path $SessionPath 'inventory_2.csv') -NoTypeInformation -Append

    Write-Host "Scan complete: $fileCount total, $($matched.Count) matched"

    return @{
        Matched   = $matched
        Unmatched = $unmatched
    }
}
