function Get-ProGetConfiguration {
<#
    .SYNOPSIS
    Retrieves the configuration for connecting to ProGet.

    .DESCRIPTION
    The `Get-ProGetConfiguration` function retrieves the configuration for ProGet. By default, it retrieves the configuration for ProGet unless a different configuration name is provided.

    .PARAMETER Configuration
    The name of the configuration to retrieve. Defaults to 'Default'.

    .EXAMPLE
    Get-ProGetConfiguration

    Retrieves the configuration for ProGet.

    .EXAMPLE
    Get-ProGetConfiguration -Configuration "CustomConfig"

    Retrieves the configuration for the configuration named "CustomConfig".
#>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Get-ProGetConfiguration')]
    Param(
        [Parameter()]
        [Alias('Name')]
        [String]
        $Configuration = $script:CurrentConfiguration
    )
    end {
        $Config = Import-Configuration -CompanyName "Pagootle" -Name $Configuration

        if ($Config.ModuleVersion -lt (Get-Module Pagootle).Version) {
            Write-Verbose "Migrating configuration from '$($Config.ModuleVersion)' to '$((Get-Module Pagootle).Version)'"
            InvokeConfigMigration -Name $Configuration -Version (Get-Module Pagootle).Version
            $Config = Import-Configuration -CompanyName "Pagootle" -Name $Configuration
        }

        $Config
    }
}