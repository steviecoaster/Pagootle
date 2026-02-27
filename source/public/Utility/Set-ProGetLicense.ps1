function Set-ProGetLicense {
    <#
    .SYNOPSIS
    Adds a new license to the ProGet instance.

    .DESCRIPTION
    Uses the API to update the license on a given instance, before which you can't configure ProGet.

    .NOTES
    This should work before setting up the ProGet configuration. It uses the same calls as:
        pgutil sources add --name=Default --url=$Endpoint
        pgutil settings set --name=Licensing.Key --value=$License

    .EXAMPLE
    Set-ProGetLicense -License $License
    # Sets the license on the currently loaded configuration of ProGet.

    .EXAMPLE
    Set-ProGetLicense -License $License -Endpoint http://localhost:8624
    # Sets the license on the provided instance of ProGet, not requiring configuration.
    #>
    [CmdletBinding()]
    param(
        # The license string to register.
        [Parameter(Mandatory)]
        [string]$License,

        # The ProGet endpoint to apply the license to, e.g. http://localhost:8624.
        # If not provided, uses the current ProGet configuration.
        [uri]$Endpoint
    )
    if ($Endpoint) {
        $null = Invoke-RestMethod -Method POST -Uri "$($Endpoint.ToString().TrimEnd('/'))/api/settings/set?name=Licensing.Key&value=$License"
    } else {
        $params = @{
            Slug   = "/api/settings/set?name=Licensing.Key&value=$License"
            Method = 'POST'
        }

        $null = Invoke-ProGet @params
    }
}