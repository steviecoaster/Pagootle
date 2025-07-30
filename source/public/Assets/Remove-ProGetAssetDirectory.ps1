function Remove-ProGetAssetDirectory {
    <#
    .SYNOPSIS
    Removes a folder on an asset directory feed.

    .DESCRIPTION
    Removes a folder within an asset directory feed, on the currently available ProGet server.

    .EXAMPLE
    Remove-ProGetAssetDirectory -AssetDirectory Internal -Folder oldfiles

    # Removes the specified directory.

    .EXAMPLE
    Remove-ProGetAssetDirectory -AssetDirectory Internal -Folder some/files -Recurse -Confirm:$false

    # Recursively remove everything in the specified directory.

    .EXAMPLE
    Get-ProGetAssetDirectoryItem | Where-Object {$_.Name -eq v1.03 -and $_.Type -eq 'dir'} | Remove-ProGetAssetDirectory -Recurse -Confirm:$false

    # Removes piped in folders recursively.

    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High", HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Remove-ProGetAssetDirectory')]
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
                $_.Type -eq 'dir' -and
                "$($_.Parent, $_.Name -join '/')".TrimStart('/') -like "*$WordToComplete*"
            } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/'),
                    $_.Name,
                    "ParameterValue",
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/')
                )
            }
        })]
        [Alias("Parent")]
        [string]
        $Folder,

        [switch]
        $Recurse
    )
    process {
        $RequestParams = @{
            Slug = "/endpoints/$($AssetDirectory)/delete/$($Folder.TrimStart('/').TrimEnd('/'))?recursive=$($Recurse)"
            Method = "Post"
        }

        if ($PSCmdlet.ShouldProcess($RequestParams.Slug, "Removing Folder$(if ($Recurse) {' and children'}) from AssetDirectory")) {
            $null = Invoke-ProGet @RequestParams
        }
    }
}