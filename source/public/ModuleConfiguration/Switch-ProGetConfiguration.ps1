function Switch-ProGetConfiguration {
    <#
    .SYNOPSIS
    Sets the configuration profile to load when calling Pagootle functions.

    .DESCRIPTION
    Sets a script-level value to the configuration profile used by the functions.
    
    .EXAMPLE
    Switch-ProGetConfiguration ProdServer3

    # Future cmdlets will poll the server defined in the ProdServer3 configuration.

    .EXAMPLE
    Switch-ProGetConfiguration

    # Sets the configuration back to the default, non-specifically named config.
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Switch-ProGetConfiguration')]
    param(
        [Parameter(Position = 0)]
        [Alias('Name')]
        [string]
        $Configuration = "Default"
    )
    $script:CurrentConfiguration = $Configuration
}