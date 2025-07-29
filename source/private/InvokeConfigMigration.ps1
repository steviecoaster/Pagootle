function InvokeConfigMigration {
    param(
        # The name of the configuration to migrate
        [string]$Name,

        # The version we're migrating to
        [version]$Version
    )
    $OldConfig = Import-Configuration -CompanyName "Pagootle" -Name $Name

    # Modify the configuration based on any updates made
    switch ($Version) {
        {$_ -gt '1.0.0'} {}
        {$_ -gt '1.1.0'} {
            # After version 1.1.0, we changed the default name and location for the configuration
            $ConfigToLoad = @{
                CompanyName = $env:USERNAME
                Name = if ($Name -eq 'Default') {
                    'ProGet'
                } else {
                    $Name
                }
            }

            $OldConfig = Import-Configuration @ConfigToLoad

            # We only use 'Port'
            $OldConfig.Port = @($OldConfig.NonSslPort, $OldConfig.SslPort)[$OldConfig.ContainsKey("UseSSL")]
            $null = $OldConfig.Remove("NonSslPort")
            $null = $OldConfig.Remove("SslPort")

            # We added an EndpointUrl value
            $OldConfig.EndpointUrl= "http$(if ($OldConfig.UseSSL) {'s'})://$($OldConfig.HostName):$($OldConfig.Port)/"

            # We use a SecureString for storing the API Key
            if ($OldConfig.ApiKey.Username) {
                $OldConfig.ApiKey = $OldConfig.ApiKey.Password
            }

            # We no longer support Credential
            if ($OldConfig.Credential -and -not $OldConfig.ApiKey) {
                $OldConfig.ApiKey = CreateApiKeyFromCredential -Credential $Credential -Name $Name
            }

            if ($OldConfig.Credential) {
                $null = $OldConfig.Remove("Credential")
            }
        }
    }

    # Update the "last updated" version
    $OldConfig.ModuleVersion = (Get-Module Pagootle).Version

    # Export the updated configuration to the config file
    $OldConfig | Export-Configuration -CompanyName "Pagootle" -Name $Name
}