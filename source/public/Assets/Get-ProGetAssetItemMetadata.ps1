function Get-ProGetAssetItemMetadata {
    <#
    .SYNOPSIS
    Gets metadata from an asset.

    .DESCRIPTION
    Gets metadata from an asset, from the currently available ProGet server.

    .EXAMPLE
    Get-ProGetAssetItemMetadata -AssetDirectory -Path /some/file.txt

    # Returns the asset metadata for the specified asset.

    .LINK
    https://docs.inedo.com/docs/proget/api/assets/metadata/get
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Commands/Get-ProGetAssetItemMetadata')]
    [OutputType("ProGetAssetDirectoryItem")]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
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

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 1)]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetAssetDirectoryItem -AssetDirectory $FakeBoundParameters.AssetDirectory -Recurse | Where-Object {
                $_.Type -ne 'dir' -and
                $_.Content -like "*$($FakeBoundParameters.AssetDirectory)/content/*$WordToComplete*"
            } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    "$($_.Content -replace ".+/endpoints/$($FakeBoundParameters.AssetDirectory)/content/(?<Path>.+)$", '${Path}')",
                    "$($_.Name)",
                    "ParameterValue",
                    "$($_.Content -replace ".+/endpoints/$($FakeBoundParameters.AssetDirectory)/content/(?<Path>.+)$", '${Path}')"
                )
            }
        })]
        [string]
        $Path
    )
    process {
        $RequestParams = @{
            Slug = "/endpoints/$AssetDirectory/metadata/$($Path.TrimStart('/'))"
        }
        
        [ProGetAssetDirectoryItem[]](Invoke-ProGet @RequestParams).Where{$_} | Add-Member -TypeName "ProGetAssetItemMetadata" -PassThru
    }
}