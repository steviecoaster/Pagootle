function Save-ProGetAssetDirectoryArchive {
    <#
    .SYNOPSIS
    Saves a ProGet asset folder to disk as an archive.

    .DESCRIPTION
    Saves a folder from a ProGet asset feed (on the currently available ProGet server) to the local machine.

    .EXAMPLE
    Save-ProGetAsset -AssetDirectory Internal -Path /some/folder

    .EXAMPLE
    Save-ProGetAsset -AssetDirectory Internal -Parent some/folder -OutputPath c:\temp\downloads\folder.zip

    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Save-ProGetAssetDirectory')]
    [OutputType([System.IO.FileInfo])]
    param(
        # The asset directory to download the folder from.
        [Parameter(Mandatory)]
        [ValidateScript({
            if ($_ -notin (Get-ProGetFeed -Type asset -Verbose:$false).Name) {
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
        [string]
        $AssetDirectory,

        # The folder to download.
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
        [Alias('Path')]
        [string]
        $Folder,

        # If selected, downloads nested levels within the folder - otherwise just downloads the top level.
        [switch]
        $Recurse,

        # The path to output the file to.
        [string]
        $OutputPath = $PWD.Path,

        # The format to download - supports zip or tgz.
        [ValidateSet("zip", "tgz")]
        [string]
        $Format = "zip"
    )
    end {
        $Result = "/endpoints/$($AssetDirectory)/export/$($Folder)?format=$($Format)&recursive=$($Recurse)" | DownloadProGetFile -OutputPath $OutputPath -PassThru

        if (-not $Result.extension) {
            $Result | Rename-Item -NewName {$_.Name + '.' + $Format} -PassThru
        }
    }
}