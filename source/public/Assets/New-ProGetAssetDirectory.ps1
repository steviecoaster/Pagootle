function New-ProGetAssetDirectory {
    <#
    .SYNOPSIS
    Creates an directory.

    .DESCRIPTION
    Creates an directory in a specified asset directory feed, on the currently active ProGet server.

    .EXAMPLE
    New-ProGetAssetDirectory -AssetDirectory Internal -Path /some/path

    # Creates the specified directory.

    .EXAMPLE
    $Directories = Get-ProGetAssetDirectory -AssetDirectory Internal | Where type -eq 'dir'
    Set-ProGetConfiguration -Hostname Otherhost -Apikey $ApiKey
    New-ProGetFeed -Name 'Internal' -Type asset -Active
    $Directories | New-ProGetAssetDirectory

    # Recreate the directories you have on an existing server on a new asset directory.

    .LINK
    https://docs.inedo.com/docs/proget/api/assets/folders/create
    #>
    [CmdletBinding(SupportsShouldProcess, HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Commands/New-ProGetAssetDirectory')]
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
                    "$($_.Parent, $_.Name -join '/')/".TrimStart('/'),
                    $_.Name,
                    "ParameterValue",
                    "$($_.Parent, $_.Name -join '/')/".TrimStart('/')
                )
            }
        })]
        [Alias("Parent")]
        [string]
        $Path
    )
    process {
        $RequestParams = @{
            Slug = "/endpoints/$($AssetDirectory)/dir/$($Path.TrimStart('/'))"
            Method = "Post"
        }

        if ($PSCmdlet.ShouldProcess($Path, "Creating Directory in AssetDirectory '$AssetDirectory'")) {
            $null = Invoke-ProGet @RequestParams
        }
    }
}