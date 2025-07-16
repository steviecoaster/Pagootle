function DownloadProGetFile {
    <#
    .SYNOPSIS
    Downloads a file from ProGet

    .DESCRIPTION
    Downloads a file from the currently active ProGet server.

    .EXAMPLE

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Slug,

        [string]$OutputPath,

        [switch]$PassThru
    )
    begin {
        $Configuration = Get-ProGetConfiguration

        $ApiCredential = if ($Configuration.ApiKey) {
            $Configuration.ApiKey.GetNetworkCredential().Password
        } elseif ($Configuration.Credential) {
            $Configuration.Credential.GetNetworkCredential().Password
        }
        
        $Downloader = [System.Net.WebClient]::new()
        $Downloader.Headers.Add("X-ApiKey", $ApiCredential)
    }
    process {
        $SavePath = if (Test-Path $OutputPath -PathType Container) {
            Join-Path $OutputPath (Split-Path ([uri]"$($Configuration.EndpointUrl.TrimEnd('/'))/$($Slug.TrimStart('/'))").LocalPath -Leaf)
        } else {
            if (-not (Test-Path ($ParentDir = Split-Path $OutputPath -Parent) -PathType Container)) {
                $null = mkdir $ParentDir -Force
            }
            $OutputPath
        }

        Write-Verbose "[GET] '$($Configuration.EndpointUrl.TrimEnd('/'))/$($Slug.TrimStart('/'))' -> '$($SavePath)'"
        $Downloader.DownloadFile("$($Configuration.EndpointUrl.TrimEnd('/'))/$($Slug.TrimStart('/'))", $SavePath)

        if ($PassThru) {
            Get-Item $SavePath
        }
    }
    end {
        $Downloader.Dispose()
    }
}