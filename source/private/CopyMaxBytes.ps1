function CopyMaxBytes {
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.IO.FileStream]   
        $source,
    
        [Parameter()]
        [System.IO.Stream]
        $target,
    
        [Parameter()]
        [Int]
        $maxBytes,

        [Parameter()]
        [Int]
        $startOffset, 
    
        [Parameter()]
        [Int]
        $totalSize
    )
    end {
        $buffer = [byte[]]::CreateInstance([byte], 32767)
        $totalBytesRead = 0
        while ($true) {
            $bytesRead = $source.Read($buffer, 0, [Math]::Min($maxBytes - $totalBytesRead, $buffer.Length))
            if (!$bytesRead) { break }
            $target.Write($buffer, 0, $bytesRead)
            $totalBytesRead += $bytesRead
            if ($totalBytesRead -ge $maxBytes) { break }
            $overallProgress = $startOffset + $totalBytesRead
            Write-Progress -Activity "Uploading $Path..." -Status "$overallProgress/$totalSize" -PercentComplete ($overallProgress / $totalSize * 100)
        }
    }
}