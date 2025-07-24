function Invoke-WorkerTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$TaskName,

        [Parameter()]
        [hashtable]$TaskParams
    )

    switch ($TaskName) {
        'ExampleTask' {
            # ... existing ExampleTask code ...
        }
        'StartScan' {
            # Validate required parameters
            if (-not $TaskParams.SourcePath -or -not $TaskParams.SessionPath -or -not $TaskParams.UserPrincipalName) {
                throw "StartScan requires SourcePath, SessionPath, and UserPrincipalName in TaskParams."
            }

            # Import modules
            Import-Module "$PSScriptRoot/../scanner/scanner.psm1" -Force
            Import-Module "$PSScriptRoot/../models/schema.psm1" -Force
            Import-Module "$PSScriptRoot/../inventory/inventory.psm1" -Force

            try {
                $filterScript = $TaskParams.FilterScript
                if ($filterScript) {
                    $result = Start-Scan -SourcePath $TaskParams.SourcePath -SessionPath $TaskParams.SessionPath -UserPrincipalName $TaskParams.UserPrincipalName -FilterScript $filterScript
                } else {
                    $result = Start-Scan -SourcePath $TaskParams.SourcePath -SessionPath $TaskParams.SessionPath -UserPrincipalName $TaskParams.UserPrincipalName -FilterScript '$_.Name -ne ""'
                }
                Write-Host "Start-Scan completed. Found $($result.Matched.Count) matched files."
            }
            catch {
                Write-Error "Error: $($_.Exception.Message)"
                Write-Host "Stack trace:"
                Write-Host $_.ScriptStackTrace
            }
            return $result
        }
    }
}

Export-ModuleMember -Function Invoke-WorkerTask