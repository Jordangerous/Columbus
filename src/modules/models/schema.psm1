function Get-BlacklistedFileNames {
    return @(
        '.lock',
        'CON',
        'PRN',
        'AUX',
        'NUL',
        'COM0','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9',
        'LPT0','LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9',
        '_vti_',
        'desktop.ini',
        '~$'
    )
}

function Test-Filter {
    param ([string]$FilterString)

    # Example input: FullName.Length ge 400
    $parts = $FilterString -split '\s+'
    if ($parts.Count -ne 3) {
        throw "Invalid filter: $FilterString"
    }

    $path = $parts[0] -split '\.'
    $property  = $path[0]
    $operator  = if ($path.Count -gt 1) { $path[1] } else { '' }
    $condition = "-$($parts[1].ToLower())"
    $value     = $parts[2]

    return @{
        Property  = $property
        Operator  = $operator
        Condition = $condition
        Value     = $value
    }
}
