# Test script to debug the issue
try {
    Import-Module './modules/scanner/scanner.psm1' -Force
    Import-Module './modules/inventory/inventory.psm1' -Force
    Import-Module './modules/models/schema.psm1' -Force
    
    $testFile = Get-ChildItem -Path 'C:\Windows\System32\notepad.exe' -ErrorAction Stop
    Write-Host "File found: $($testFile.FullName)"
    
    $record = New-InventoryRecord -File $testFile -RelativePath 'test' -OneDrivePath 'test' -Status 'Pending'
    Write-Host "Success: Record created"
    $record | Format-List
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Stack trace:"
    Write-Host $_.ScriptStackTrace
}
