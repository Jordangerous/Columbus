#crawl directory recursively and streams files to csv
$defaultDir = Join-Path $env:USERPROFILE 'Desktop'

$inputDir = Read-Host "Enter the directory to scan (press Enter for default: '$defaultDir')"
if (-not $inputDir) {
    $inputDir = $defaultDir
}
$sessionDir = Join-Path '../datafiles' (Get-Date -Format "yyyy-MM-dd-HH-mm-ss")
New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
$folderManifest = (Join-Path $sessionDir 'manifest.csv')
New-Item -ItemType File -Path $folderManifest -Force | Out-Null
write-Output "Starting scan in directory:"
#use stream 
$filestream = [System.IO.StreamWriter]::new($folderManifest, $false, [System.Text.Encoding]::UTF8)
$filestream.WriteLine("FullName,Name,Extension,Length,LastWriteTime,CreationTime,Owner,RelativePath,OneDrivePath,Status,ErrorMessage,Timestamp,PathLength")
# Get all files in the directory recursively

if (-not (Test-Path $inputDir)) {
    Write-Error "The specified directory does not exist: $inputDir"
    exit 1
}

# Initialize counter for periodic flushing
$fileCount = 0
$bufferCount = 0
$totalBytesProcessed = 0
$flushThresholdBytes = 10 * 1024 * 1024  # 10 MB in bytes   
$startTime = Get-Date
Get-ChildItem -Path $inputDir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_
    $fileCount++
    $bufferCount++
    # Add file size to running total
    #i want this to be the stream's buffer size
    # so that it flushes every 10MB of file data processed
    
    $totalBytesProcessed += $file.Length
    
    $relativePath = $file.FullName.Substring($inputDir.Length).TrimStart('\')
    $oneDrivePath = "migration/$relativePath" -replace '\\', '/'
    # Create a record object
    $record = [pscustomobject]@{
        FullName       = $file.FullName
        Name           = $file.Name
        Extension      = $file.Extension
        Length         = $file.Length
        LastWriteTime  = $file.LastWriteTime
        CreationTime   = $file.CreationTime
        Owner          = (Get-Acl $file.FullName).Owner
        RelativePath   = $relativePath
        OneDrivePath   = $oneDrivePath
        Status         = 'Pending'
        ErrorMessage   = ''
        Timestamp      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        PathLength     = $file.FullName.Length
        ProcessId      = $PID
    }
    
    # Write the record to the CSV file (skip header)
    $csvLine = ($record | ConvertTo-Csv -NoTypeInformation)[1]
    $filestream.WriteLine($csvLine)
    #inline counter
    Write-Host "`rProcessed items: $fileCount" -NoNewline
    # Flush every 10MB of file data processed
    if ($bufferCount -ge 1000) { 
        $filestream.Flush()
        $bufferCount = 0  # Reset after flushing
        $totalBytesProcessed = 0  # Reset after flushing
        Write-Host "`nFlushed stream after processing $fileCount files"
    }
    

}
$filestream.Flush()
$filestream.Close()
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "`nScan completed in $($elapsedTime.TotalSeconds) seconds."