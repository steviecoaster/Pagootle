function New-ProGetApiKey {
    <#
    .SYNOPSIS
    Creates an API key.

    .DESCRIPTION
    Creates an API key on the currently available ProGet server.

    .EXAMPLE
    New-ProGetApiKey -DisplayName Test -Description 'A test key' -SystemApi full_control

    # Creates a test system level API key with full control.

    .EXAMPLE
    New-ProGetApiKey -DisplayName PackagePusher -Description 'Key for pushing packages' -FeedGroup Chocolatey -PackagePermissions view,add

    # Creates a feedgroup level API key with permission to view, download, and push packages.

    .EXAMPLE
    New-ProGetApiKey -DisplayName PackagePusher -Description 'Key for pushing packages' -Feed ChocolateyInternal -PackagePermissions view

    # Creates a feed level API key with permission to view and download packages.

    .EXAMPLE
    New-ProGetApiKey -DisplayName "Bob's Key" -Description 'Key for Bob to use for pushing packages' -User bob

    # Creates a user level API key with all permissions of that user. Not available on the free license.

    .LINK
    https://docs.inedo.com/docs/proget/api/apikeys/create

    .LINK
    https://github.com/Inedo/pgutil/blob/thousand/Inedo.ProGet/ApiKeyInfo.cs
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "System", HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/New-ProGetApiKey')]
    param(
        # Used in lists of keys, and when not specified, a name like "(ID=1000)" is displayed.
        [Parameter()]
        [string]
        $DisplayName,

        # Used to describe the usage or other context about the key.
        [Parameter()]
        [string]
        $Description,

        # APIs a system key may use. Value is either ["full-control"] or a combination of "feeds", "sca", "sbom-upload".
        [Parameter(ParameterSetName = "System", Mandatory)]
        [ProGetApiKeySystemApis]
        $SystemApi,

        # Permissions a feed key may have. Value is a combination of "view", "add", "promote", "delete".
        [Parameter(ParameterSetName = "FeedGroup", Mandatory)]
        [Parameter(ParameterSetName = "Feed", Mandatory)]
        [ProGetApiKeyPackagePermission]
        $PackagePermissions,

        # Name of the feed group the key applies to.
        [Parameter(ParameterSetName = "FeedGroup", Mandatory)]
        [string]
        $FeedGroup,

        # Name of the feed the feed key applies to.
        [Parameter(ParameterSetName = "Feed", Mandatory)]
        [ValidateScript({
            if ($_ -ne '*' -and $_ -notin (Get-ProGetFeed).Name) {
                throw "'$_' was not present on the connected ProGet server."
            }
            $true
        })]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetFeed | Where-Object Name -like "$WordToComplete*" | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_.Name)
            }
        })]
        [string]
        $Feed,

        # Name of the user the personal key applies to.
        [Parameter(ParameterSetName = "Personal", Mandatory)]
        [string]
        $User,

        # Date and time to expire the key.
        [Parameter()]
        [datetime]
        $Expiration
    )
    process {
        $RequestParams = @{
            Slug   = "/api/api-keys/create"
            Method = "Post"
            Body   = @{
                type               = $PSCmdlet.ParameterSetName.ToLower() -replace "^feedgroup$","feed"
                displayName        = $DisplayName
                description        = $Description
                expiration         = if ($Expiration) {$Expiration.ToUniversalTime()} else {$null}
                user               = $null
                packagePermissions = @($null)
                systemApis         = @($null)
                feed               = $null
                feedGroup          = $null
            }
        }

        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "User" {
                $RequestParams.Body.user = $User
            }
            "System" {
                $RequestParams.Body.systemApis = $SystemApi.ToString().Split(', ') -replace "_","-"
            }
            "Feed*" {
                $RequestParams.Body.packagePermissions = $PackagePermissions.ToString().Split(', ')
            }
            "Feed" {
                if ($Feed -ne '*') {
                    $RequestParams.Body.feed = $Feed
                }
            }
            "FeedGroup" {
                $RequestParams.Body.feedGroup = $FeedGroup
            }
        }

        if ($PSCmdlet.ShouldProcess("$($PSCmdlet.ParameterSetName) (Name: '$DisplayName', Description: '$Description')", "Creating API Key")) {
            Invoke-ProGet @RequestParams
        }
    }
}