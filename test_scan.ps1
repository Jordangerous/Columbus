# Test script to diagnose Start-Scan issues
$testDir = 'C:\Windows\System32'
$sessionDir = 'C:\temp\test'

# Create session directory
New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null

# Import modules
Import-Module './src/modules/scanner/scanner.psm1' -Force
Import-Module './src/modules/models/schema.psm1' -Force
Import-Module './src/modules/inventory/inventory.psm1' -Force

try {
    Write-Host "Testing Start-Scan function..."
    $result = Start-Scan -SourcePath $testDir -SessionPath $sessionDir -UserPrincipalName 'test@test.com' -FilterScript '$_.Name -eq "notepad.exe"'
    Write-Host "Success! Found $($result.Matched.Count) matched files"
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    Write-Host "Stack trace:"
    Write-Host $_.ScriptStackTrace
}
