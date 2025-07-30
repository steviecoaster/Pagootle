function Get-ProGetAssetDirectoryItem {
    <#
    .SYNOPSIS
    Returns the content of an asset directory on a feed.

    .DESCRIPTION
    Returns a list of files contained within a specified directory within a feed, on the currently available ProGet server.

    .EXAMPLE
    Get-ProGetAssetDirectoryItem -AssetDirectory Internal -Recurse

    # Returns all items in the Internal asset directory.

    .EXAMPLE
    Get-ProGetAssetDirectoryItem -AssetDirectory Internal -Folder ops

    # Returns all items in the ops folder of the Internal asset directory.

    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Get-ProGetAssetDirectoryItem')]
    [OutputType("ProGetAssetDirectoryItem")]
    param(
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
        [string]
        $AssetDirectory,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
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

        [switch]
        $Recurse
    )
    process {
        $RequestParams = @{
            Slug = "/endpoints/$($AssetDirectory)/dir$(if($Folder){'/'})$($Folder.TrimStart('/').TrimEnd('/'))?recursive=$($Recurse)"
        }

        # ProGet returns an empty array if the path does not exist, or if there's nothing there.
        [ProGetAssetDirectoryItem[]](Invoke-ProGet @RequestParams).Where{$_}
    }
}