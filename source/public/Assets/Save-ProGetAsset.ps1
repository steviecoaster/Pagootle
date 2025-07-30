function Save-ProGetAsset {
    <#
    .SYNOPSIS
    Saves a ProGet asset to disk.

    .DESCRIPTION
    Saves a file from a ProGet asset feed (on the currently available ProGet server) to the local machine.

    .EXAMPLE
    Save-ProGetAsset -AssetDirectory Internal -Path /some/folder/file.txt

    .EXAMPLE
    Get-ProGetAssetDirectoryItem -AssetDirectory Internal -Parent bob | Where Type -ne dir | Save-ProGetAsset

    .EXAMPLE
    Save-ProGetAsset -AssetDirectory Internal -Parent some/folder -Name file.txt -OutputPath c:\temp\downloads

    #>
    [CmdletBinding(DefaultParameterSetName = "SplitFile", HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Save-ProGetAsset')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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

        [Parameter(ParameterSetName = "Path", Mandatory)]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetAssetDirectoryItem -AssetDirectory $FakeBoundParameters.AssetDirectory -Folder $FakeBoundParameters.Folder -Recurse | Where-Object {
                $_.Type -ne 'dir' -and
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
        $Path,

        [Parameter(ParameterSetName = "SplitFile", ValueFromPipelineByPropertyName)]
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
        [Alias("Folder")]
        [string]
        $Parent,

        [Parameter(ParameterSetName = "SplitFile", Mandatory, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetAssetDirectoryItem -AssetDirectory $FakeBoundParameters.AssetDirectory -Folder $FakeBoundParameters.Parent -Recurse | Where-Object {
                $_.Type -ne 'dir' -and
                $_.Name -like "*$WordToComplete*"
            } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    $_.Name,
                    $_.Name,
                    "ParameterValue",
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/')
                )
            }
        })]
        [string]
        $Name,

        [Parameter()]
        [string]
        $OutputPath = $PWD.Path
    )
    process {
        if ($PSCmdlet.ParameterSetName -ne 'Path') {
            $Path = $Parent, $Name -join '/'
        }
        "endpoints/$($AssetDirectory)/content/$($Path.TrimStart('/'))" | DownloadProGetFile -OutputPath $OutputPath -PassThru
    }
}