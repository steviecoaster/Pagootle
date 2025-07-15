function Set-ProGetAssetItemMetadata {
    <#
    .SYNOPSIS
    Sets metadata for an asset.

    .DESCRIPTION
    Sets metadata for an asset, on the currently available ProGet server.

    .EXAMPLE
    Set-ProGetAssetItemMetadata -AssetDirectory Internal -Path /some/file.txt -UserMetadata @{myKey = 'myValue'}

    # Adds to the metadata of the existing asset.

    .EXAMPLE
    Set-ProGetAssetItemMetadata -AssetDirectory Internal -Path /some/file.txt -UserMetadata @{myKey = 'myValue'} -UserMetadataUpdateMode 'Replace'

    # Overwrites the metadata of the existing asset.

    .EXAMPLE
    Set-ProGetAssetItemMetadata -AssetDirectory Internal -Path /some/file.txt -CacheHeader @{type = 'TTL'; value = '60'}

    # Modifies the cache header assigned to the asset.

    .EXAMPLE
    Set-ProGetAssetItemMetadata -AssetDirectory Internal -Path /some/file.txt -CacheHeader @{type = 'Inherit'}

    # Modifies the cache header assigned to the asset.

    .LINK
    https://docs.inedo.com/docs/proget/api/assets/metadata/set

    .LINK
    https://github.com/Inedo/pgutil/blob/thousand/Inedo.ProGet/AssetDirectories/AssetItemMetadataUpdate.cs
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Commands/Set-ProGetAssetItemMetadata')]
    param(
        # The asset directory within which the asset to modify is contained.
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

        # The path to asset to modify.
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
        $Path,

        # The Content-Type assigned to the object, e.g. image/jpeg
        [string]$Type,

        # Additional user metadata to store and return on the object.
        [Parameter(Mandatory, ParameterSetName = 'User')]
        [hashtable]$UserMetadata,

        # Whether to merge (update) the user metadata, or overwrite it entirely (replace).
        [Parameter(ParameterSetName = 'User')]
        [ValidateSet("Update", "Replace")]
        $UserMetadataUpdateMode = "Update",

        # Cache headers returned with the object to influence external caching, e.g. @{type='TTL';value=60}, @{type='Inherit'} etc.
        [Parameter(Mandatory, ParameterSetName = 'Cache')]
        [ValidateScript({
            # https://github.com/Inedo/pgutil/blob/thousand/Inedo.ProGet/AssetDirectories/AssetDirectoryItemCacheHeader.cs
            if ($false -notin $_.Keys.ForEach{$_ -notin @('Type', 'Value')}) {throw "CacheHeader must only contain 'Type' and (optionally) 'Value'"}
            if (-not $_.Type) {throw "CacheHeader must contain a Type"}
            $true
        })]
        [hashtable]$CacheHeader
    )
    process {
        $RequestParams = @{
            Slug = "/endpoints/$AssetDirectory/metadata/$Path"
            Method = "Post"
            Body = @{
                type = $type
                userMetadataUpdateMode = $UserMetadataUpdateMode.ToLower()
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            "Cache" {
                $RequestParams.Body.cacheHeader = $CacheHeader
            }
            "User" {
                $RequestParams.Body.userMetadata = $UserMetadata
            }
        }

        $null = Invoke-ProGet @RequestParams
    }
}