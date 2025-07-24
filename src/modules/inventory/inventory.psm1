function Test-Inventory {
    param (
        [Parameter(Mandatory)]
        [array]$Files,

        [string]$InventoryPath = "$PSScriptRoot/../../datafiles/FileInventory.csv"
    )

    if (-not (Test-Path $InventoryPath)) {
        Write-Verbose "Inventory file not found at '$InventoryPath'. Returning all files."
        return $Files
    }

    $existingFullNames = Import-Csv $InventoryPath |
        Where-Object { $_.Status -eq 'Success' } |
        Select-Object -ExpandProperty FullName -Unique

    $todo = $Files | Where-Object {
        $path = $_.FullName
        -not ($existingFullNames -contains $path)
    }

    return $todo
}

function Update-InventoryRecord {
    param (
        [Parameter(Mandatory)]
        [string]$InventoryPath,

        [Parameter(Mandatory)]
        [string]$FullName,

        [Parameter(Mandatory)]
        [string]$Status,

        [string]$ErrorMessage
    )

    if (-not (Test-Path $InventoryPath)) {
        throw "Inventory file not found at '$InventoryPath'"
    }

    $updated = $false
    $rows = Import-Csv $InventoryPath | ForEach-Object {
        if ($_.FullName -eq $FullName) {
            $_.Status = $Status
            $_.ErrorMessage = $ErrorMessage
            $_.Timestamp = (Get-Date)
            $updated = $true       
        }
        $_
    }
    if (-not $updated) {
        throw "File '$FullName' not found in inventory."
    }
    $rows | Export-Csv -Path $InventoryPath -NoTypeInformation
}

function Write-InventoryRecord {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Record,

        [string]$InventoryPath = "$PSScriptRoot/../../datafiles/FileInventory.csv"
    )

    $columns = @(
        'FullName', 'Name', 'Extension', 'Length',
        'LastWriteTime', 'CreationTime', 'Owner',
        'RelativePath', 'OneDrivePath', 'Status',
        'ErrorMessage', 'Timestamp'
    )

    $exists = Test-Path $InventoryPath

    # Ensure columns match expected order
    $out = $Record | Select-Object $columns

    if (-not $exists) {
        $out | Export-Csv -Path $InventoryPath -NoTypeInformation
    } else {
        $out | Export-Csv -Path $InventoryPath -NoTypeInformation -Append
    }
}

function New-InventoryRecord {
    param (
        [Parameter(Mandatory)][System.IO.FileInfo]$File,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$OneDrivePath,
        [Parameter(Mandatory)][string]$Status
    )

    $owner = try {
        (Get-Acl $File.FullName).Owner
    } catch {
        'Unknown'
    }

    return [PSCustomObject]@{
        FullName      = $File.FullName
        Name          = $File.Name
        Extension     = $File.Extension
        Length        = $File.Length
        LastWriteTime = $File.LastWriteTime
        CreationTime  = $File.CreationTime
        Owner         = $owner
        RelativePath  = $RelativePath
        OneDrivePath  = $OneDrivePath
        Status        = $Status
        ValidPathLength = $File.FullName.Length -le 400
        Timestamp     = (Get-Date)
    }
}