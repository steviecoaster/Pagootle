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

        .Link
        https://docs.inedo.com/docs/proget/api/assets/files/upload

        .Link
        https://docs.inedo.com/docs/proget/api/assets/files/upload/multipart
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Commands/New-ProGetAsset')]
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
        $fileInfo = Get-Item -Path $Path

        $RequestParams = @{
            Slug = @(
                "/endpoints"
                $AssetDirectory
                "content"
                if ($Folder) {$Folder.TrimStart('/').TrimEnd('/')}
                [Uri]::EscapeUriString($AssetName.Replace('\', '/'))
            ) -join '/'
        }

        if (-not $ForceMultipartUpload -and $fileInfo.Length -lt 2GB) {
            $RequestParams += @{
                Method = if ($Force) {"Post"} else {"Put"}
                File = $FileInfo.FullName
            }
            try {
                $null = Invoke-ProGet @RequestParams
            } catch {
                if ($_.Exception.Response.StatusCode -eq 400) {
                    Write-Error -Message "$_ Run with -Force to overwrite!" -Exception $_.Exception -ErrorAction Stop
                }
                throw
            }
        } else {  # The Multipart Asset File Upload is an HTTP Request specifically for multipart uploads of very large (2GB+) files.
            # As this endpoint doesn't complain if we overwrite a file, check if we aren't forcing upload.
            if (-not $Force -and (Invoke-ProGet @RequestParams)) {
                Write-Error -Message "The specified asset already exists. Run with -Force to overwrite!" -Category InvalidOperation -ErrorAction Stop 
            }

            $sourceStream = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read, 4096, [System.IO.FileOptions]::SequentialScan)

            try {
                $fileLength = $sourceStream.Length
                $remainder = [long]0
                $totalParts = [Math]::DivRem([long]$fileLength, [long]$chunkSize, [ref]$remainder)
                if($remainder -ne 0) { $totalParts++ }
                $uuid = (New-Guid).ToString("N")

                0..($totalParts-1) | ForEach-Object {
                    $index = $_
                    $offset = $index * $chunkSize
                    $currentChunkSize = if ($index -eq ($totalParts - 1)) { $fileLength - $offset } else { $chunkSize }

                    $req = [System.Net.WebRequest]::CreateHttp("$($Configuration.EndpointUrl)$($RequestParams.Slug)?multipart=upload&id=$uuid&index=$index&offset=$offset&totalSize=$fileLength&partSize=$currentChunkSize&totalParts=$totalParts")
                    $req.Method = 'POST'
                    Write-Verbose "[$($req.Method)] $($req.RequestUri)"
                    $req.Headers.Add("X-ApiKey", ([System.Net.NetworkCredential]::new("ApiKey", $Configuration.ApiKey)).Password)
                    $req.ContentLength = $currentChunkSize
                    $req.AllowWriteStreamBuffering = $false
                    $reqStream = $req.GetRequestStream()
                    try { CopyMaxBytes -source $sourceStream -target $reqStream -maxBytes $currentChunkSize -startOffset $offset -totalSize $fileLength }
                    finally { if($reqStream) { $reqStream.Dispose() } }

                    try {
                        $response = $req.GetResponse()
                    } finally { if($response) { $response.Dispose() } }
                }

                Write-Progress -Activity "Uploading $Path..." -Status "Completing upload..." -PercentComplete -1

                Write-Verbose "Completing Multipart Upload of '$($Path)'"
                $req = [System.Net.WebRequest]::CreateHttp("$($Configuration.EndpointUrl)$($RequestParams.Slug)?multipart=complete&id=$uuid")
                $req.Method = 'POST'
                Write-Verbose "[$($req.Method)] $($req.RequestUri)"
                $req.Headers.Add("X-ApiKey", ([System.Net.NetworkCredential]::new("ApiKey", $Configuration.ApiKey)).Password)
                $req.ContentLength = 0
                try {
                    $response = $req.GetResponse()
                } finally { if($response) { $response.Dispose() } }
            }
            finally { if($sourceStream) { $sourceStream.Dispose() } }
        }
    }
}