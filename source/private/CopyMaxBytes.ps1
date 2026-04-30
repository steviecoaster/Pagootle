function CopyMaxBytes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileStream]   
        $source,
    
        [Parameter(Mandatory)]
        [System.IO.Stream]
        $target,

        [Parameter(Mandatory)]
        [long]
        $maxBytes,

        [Parameter(Mandatory)]
        [long]
        $startOffset,

        [Parameter(Mandatory)]
        [long]
        $totalSize
    )

    end {
        $buffer = [byte[]]::new(5MB)
        [long]$totalBytesRead = 0

        while ($totalBytesRead -lt $maxBytes) {
            [int]$bytesToRead = [int][Math]::Min($buffer.Length, $maxBytes - $totalBytesRead)

            [int]$bytesRead = $source.Read($buffer, 0, $bytesToRead)
            if ($bytesRead -le 0) { break }

            $target.Write($buffer, 0, $bytesRead)
            $totalBytesRead += [long]$bytesRead

            if ($totalSize -gt 0) {
                [long]$overallProgress = $startOffset + $totalBytesRead
                [int]$percentComplete = [int][Math]::Min(100, [Math]::Floor(($overallProgress * 100.0) / $totalSize))

                Write-Progress -Activity "Uploading..." -Status "$overallProgress/$totalSize" -PercentComplete $percentComplete
            }
        }
    }
}