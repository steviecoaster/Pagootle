function Set-ProGetConfiguration {
    <#
    .SYNOPSIS
    Sets the configuration for connecting to ProGet.

    .DESCRIPTION
    The `Set-ProGetConfiguration` function allows you to configure the connection settings for ProGet, including hostname, credentials, ports, and SSL options. The configuration can be saved with a custom name for later use.

    .PARAMETER Hostname
    The hostname of the ProGet server. This parameter is mandatory.

    .PARAMETER Credential
    A PSCredential object containing the username and password for authenticating with the ProGet server. If provided, we create an API key for you, and store that.

    .PARAMETER Port
    The port to use.

    .PARAMETER UseSSL
    Specifies whether to use SSL for the connection.

    .PARAMETER Name
    The name of the configuration to save. Defaults to 'Default'.

    .PARAMETER ApiKey
    The API key to use for authentication.

    .EXAMPLE
    Set-ProGetConfiguration -Hostname "proget.example.com" -Credential admin

    Sets the configuration for ProGet with the specified hostname and a created API key.

    .EXAMPLE
    Set-ProGetConfiguration -Hostname "proget.example.com" -ApiKey asdf8675309

    Sets the configuration for ProGet with the specified hostname and apikey

    .EXAMPLE
    Set-ProGetConfiguration -Hostname "proget.example.com" -Credential admin -UseSSL -Port 8443

    Sets the configuration for ProGet with SSL enabled and a custom SSL port.

    .EXAMPLE
    Set-ProGetConfiguration -Hostname "proget.example.com" -Credential admin -Name "CustomConfig"

    Sets the configuration for ProGet with a custom configuration name.
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Set-ProGetConfiguration' , DefaultParameterSetName = 'Apikey')]
    param(
        [Parameter(Mandatory)]
        [String]
        $Hostname,

        [Parameter(Mandatory, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory, ParameterSetName = 'Apikey')]
        [String]
        $ApiKey,

        [Parameter()]
        [UInt16]
        $Port = $(if ($UseSSL) {443} else {8624}),

        [Parameter()]
        [Switch]
        $UseSSL,

        [Parameter()]
        [String]
        $Name = $script:CurrentConfiguration
    )
    end {
        $Configuration = @{
            ModuleVersion = (Get-Module Pagootle).Version
            Hostname      = $Hostname
            Port          = [string]$Port
        }

        $Configuration.Add('EndpointUrl', "http$(if ($UseSSL) {'s'})://$($HostName):$($Port)/")

        switch ($PSBoundParameters.Keys) {
            'Credential' {
                $Configuration.ApiKey = CreateApiKeyFromCredential -Credential $Credential -Name $Name
            }
            'ApiKey' {
                $Configuration.Add('ApiKey', (ConvertTo-SecureString $ApiKey -AsPlainText -Force))
            }
        }

        $Configuration | Export-Configuration -CompanyName "Pagootle" -Name $Name
    }
}