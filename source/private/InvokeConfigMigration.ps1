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

            # We added an EndpointUrl value
            $OldConfig.EndpointUrl= "http$(if ($OldConfig.UseSSL) {'s'})://$($OldConfig.HostName):$(@($OldConfig.NonSslPort, $OldConfig.SslPort)[$OldConfig.ContainsKey("UseSSL")])/"
        }
    }

    # Update the "last updated" version
    $OldConfig.ModuleVersion = (Get-Module Pagootle).Version

    # Export the updated configuration to the config file
    $OldConfig | Export-Configuration -CompanyName "Pagootle" -Name $Name
}