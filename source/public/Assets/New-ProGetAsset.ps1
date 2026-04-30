function New-ProGetAsset {
    <#
        .Synopsis
        Transfers a file to a ProGet asset directory.

        .Description
        Transfers a file to a ProGet asset directory. This function performs automatic chunking
        if the file is larger than a specified threshold.

        .Parameter Path
        Name of the file to upload from the local file system.

        .Parameter AssetDirectory
        Name of the asset feed to upload the file to.

        .Parameter Folder
        Folder within the asset feed to store the file in.

        .Parameter ContentType
        ContentType of the asset.

        .Parameter AssetName
        Name of the asset to create in ProGet's asset directory.

        .Parameter ChunkSize
        Uploads larger than 2GB will be uploaded using multiple requests of this size. The default is 5 MB. Uploading may be faster with larger chunk sizes!

        .Parameter ForceMultipartUpload
        Forces use of the multipart upload logic. If you're having a hard time uploading a large file, try this!

        .Parameter Force
        By default, the function will not upload if a file already exists with the expected name. Force overwrites existing files.

        .Example
        New-ProGetAsset -AssetDirectory -Path C:\Files\Image.jpg

    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/New-ProGetAsset')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if ($_ -notin (Get-ProGetFeed -Type asset).Name) {
                throw "'$_' was not present on the connected ProGet server."
            }
            $true
        })]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetFeed -Type asset | Where-Object Name -like "$WordToComplete*" | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_.Name)
            }
        })]
        [String]
        $AssetDirectory,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("Parent")]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetAssetDirectoryItem -AssetDirectory $FakeBoundParameters.AssetDirectory -Recurse | Where-Object {
                $_.Type -eq 'dir' -and
                "$($_.Parent, $_.Name -join '/')".TrimStart('/') -like "*$WordToComplete*"
            } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/'),
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/'),
                    "ParameterValue",
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/')
                )
            }
        })]
        [string]
        $Folder,

        [Parameter()]
        [string]
        $ContentType = 'application/octet-stream',

        [Parameter()]
        [string]
        $AssetName = $(Split-Path $Path -Leaf),

        [Parameter()]
        [uint64]
        $ChunkSize = 5MB,

        [switch]
        $Force,

        [switch]
        $ForceMultipartUpload
    )
    begin {
        $Configuration = Get-ProGetConfiguration
    }
    process {
        $slugSegments = @(
            "/endpoints"
            $AssetDirectory
            "metadata"
            if ($Folder) {$Folder.TrimStart('/').TrimEnd('/')}
            [Uri]::EscapeUriString($AssetName.Replace('\', '/'))
        )

        if (-not $Force) {
            try { 
                if (Invoke-ProGet -Slug ($slugSegments -join '/')) { throw "$_ Run with -Force to overwrite!" }
            }
            catch {
                if ($_.ErrorDetails.Message -ne "Asset not found.") { throw $_ }
            }
        }

        $fileInfo = Get-Item -Path $Path

        $parts = $slugSegments.Clone()
        $parts[2] = "content"
        $ContentSlug = $parts -join '/'
        
        # simple upload
        if (-not $ForceMultipartUpload -and $fileInfo.Length -lt 2GB) {
            $method = if ($Force) {"Post"} else {"Put"}
            $null = Invoke-ProGet -Method $method -ContentType $ContentType -Slug $ContentSlug -File $fileInfo.FullName
            return
        }

        # multipart upload
        $baseUrl = $Configuration.EndpointUrl.TrimEnd('/') + "/" + $ContentSlug.TrimStart('/')
        $sourceStream = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read, 4096, [System.IO.FileOptions]::SequentialScan)
        try {
            $fileLength = $sourceStream.Length
            $totalParts = [long](($fileLength + $ChunkSize - 1) / $ChunkSize)

            $uuid = (New-Guid).ToString("N")

            for ($i = 0; $i -lt $totalParts; $i++) {
                $offset = $i * $ChunkSize
                $currentChunkSize = if ($i -eq ($totalParts - 1)) { $fileLength - $offset } else { $ChunkSize }

                $url = "$($baseUrl)?multipart=upload&id=$uuid&index=$i&offset=$offset&totalSize=$fileLength&partSize=$currentChunkSize&totalParts=$totalParts"

                $req = [System.Net.WebRequest]::CreateHttp($url)
                $req.Method = 'POST'
                $req.Headers.Add("X-ApiKey", ([System.Net.NetworkCredential]::new("ApiKey", $Configuration.ApiKey)).Password)
                $req.ContentLength = $currentChunkSize
                $req.AllowWriteStreamBuffering = $false
                
                Write-Verbose "[$($req.Method)] $($req.RequestUri)"
                $reqStream = $req.GetRequestStream()
                try {
                    CopyMaxBytes -source $sourceStream -target $reqStream -maxBytes $currentChunkSize -startOffset $offset -totalSize $fileLength
                }
                finally { if ($reqStream) { $reqStream.Dispose() } }

                $response = $null
                try {
                    $response = $req.GetResponse()
                }
                finally { if ($response) { $response.Dispose() } }
            }

            Write-Progress -Activity "Uploading $Path..." -Status "Completing upload..." -PercentComplete -1
            Write-Verbose "Completing Multipart Upload of '$Path'"
            $null = Invoke-ProGet -Method 'Post' -ContentType $ContentType -Slug "$($ContentSlug)?multipart=complete&id=$uuid"
            Write-Progress -Activity "Uploading $Path..." -Status "Completing upload..." -Completed
        }
        finally { if ($sourceStream) { $sourceStream.Dispose() } }
    }
}