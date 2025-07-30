function Remove-ProGetAssetDirectoryItem {
    <#
    .SYNOPSIS
    Removes an asset on an asset directory feed.

    .DESCRIPTION
    Removes an asset within an asset directory feed, on the currently available ProGet server.

    .EXAMPLE
    Remove-ProGetAssetDirectoryItem -AssetDirectory Internal -Path old-file.txt

    # Removes the specified file.

    .EXAMPLE
    Get-ProGetAssetDirectoryItem -AssetDirectory Internal | Where-Object Modified -lt (Get-Date).AddYears(-1) | Remove-ProGetAssetDirectoryItem -Confirm:$false

    # Removes assets that haven't been modified in a year.

    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High", HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Remove-ProGetAssetDirectoryItem', DefaultParameterSetName = "Pipeline")]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0, ParameterSetName = "Split")]
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

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 1, ParameterSetName = "Split")]
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
        $Path,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "Pipeline")]
        [string]
        $Content = "/endpoints/$($AssetDirectory)/content/$($Path.TrimStart('/').TrimEnd('/'))"
    )
    process {
        $RequestParams = @{
            Slug = $Content -replace ".*(?<Slug>/endpoints/(?<AssetDirectory>.+?)/content/(?<Path>.+?))$", '${Slug}'
            Method = "Delete"
        }

        if ($PSCmdlet.ShouldProcess($Slug, "Removing Asset from AssetDirectory")) {
            $null = Invoke-ProGet @RequestParams
        }
    }
}