function CreateApiKeyFromCredential {
    [CmdletBinding()]
    param(
        [PSCredential]$Credential,
        [string]$Name
    )
    $Configuration.Add('ApiKey', $Credential.Password)

    Write-Verbose "Using Credential '$($Credential.UserName)' to create API key for usage..."
    $Configuration | Export-Configuration -CompanyName "Pagootle" -Name $Name

    $ApiKeyRequest = @{
        DisplayName = "PagootleAccess"
        Description = "An API key created for use with Pagootle."
        SystemAPI   = "full_control"
    }
    (New-ProGetApiKey @ApiKeyRequest).SecureKey
}