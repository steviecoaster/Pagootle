function New-ProGetFeed {
    <#
    .SYNOPSIS
    Creates a new feed in ProGet.

    .DESCRIPTION
    The `New-ProGetFeed` function allows you to create a new feed in ProGet with various configurable options, such as feed type, connectors, retention rules, and more. It supports multiple feed types, including NuGet, Chocolatey, Docker, and others.

    .PARAMETER Name
    The name of the feed to create. This parameter is mandatory.

    .PARAMETER AlternateNames
    Alternate names for the feed.

    .PARAMETER Type
    The type of the feed. Supported types include 'asset', 'bower', 'conda', 'chocolatey', 'debianlegacy', 'debian', 'docker', 'helm', 'maven', 'npm', 'nuget', 'powershell', 'universal', 'pypi', 'romp', 'rpm', 'rubygems', and 'vsix'. Defaults to 'NuGet'.

    .PARAMETER Active
    Specifies whether the feed is active.

    .PARAMETER CacheConnectors
    Specifies whether connectors should be cached.

    .PARAMETER SymbolServerEnabled
    Enables the symbol server for the feed.

    .PARAMETER StripSymbols
    Specifies whether symbols should be stripped from packages.

    .PARAMETER StripSource
    Specifies whether source files should be stripped from packages.

    .PARAMETER EndpointUrl
    The endpoint URL for the feed.

    .PARAMETER Connectors
    A list of connectors to associate with the feed.

    .PARAMETER RetentionRules
    A list of retention rules to apply to the feed.

    .PARAMETER Variables
    A hashtable of variables to associate with the feed.

    .PARAMETER CanPublish
    Specifies whether publishing to the feed is allowed.

    .PARAMETER PackageStatisticsEnabled
    Enables package statistics for the feed.

    .PARAMETER RestrictPackageStatistics
    Restricts access to package statistics.

    .PARAMETER DeploymentRecordsEnabled
    Enables deployment records for the feed.

    .PARAMETER UsageRecordsEnabled
    Enables usage records for the feed.

    .PARAMETER VulnerabilitiesEnabled
    Enables vulnerability tracking for the feed.

    .PARAMETER LicensesEnabled
    Enables license tracking for the feed.

    .PARAMETER UseWithProjects
    Specifies whether the feed can be used with projects.

    .EXAMPLE
    New-ProGetFeed -Name "MyFeed" -Type "nuget" -Active -CanPublish

    Creates a new NuGet feed named "MyFeed" that is active and allows publishing.

    .EXAMPLE
    New-ProGetFeed -Name "DockerFeed" -Type "docker" -Connectors @("Connector1", "Connector2") -RetentionRules @("Rule1", "Rule2")

    Creates a new Docker feed named "DockerFeed" with specified connectors and retention rules.

    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/New-ProGetFeed')]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $AlternateNames,

        [Parameter()]
        [ValidateSet('asset', 'bower', 'conda', 'chocolatey', 'debianlegacy', 'debian', 'docker', 'helm', 'maven', 'npm', 'nuget', 'powershell', 'universal', 'pypi', 'romp', 'rpm', 'rubygems', 'vsix')]
        [String]
        $Type = 'NuGet',

        [Parameter()]
        [Switch]
        $Active,

        [Parameter()]
        [Switch]
        $CacheConnectors,

        [Parameter()]
        [Switch]
        $SymbolServerEnabled,

        [Parameter()]
        [Switch]
        $StripSymbols,

        [Parameter()]
        [Switch]
        $StripSource,

        [Parameter()]
        [String]
        $EndpointUrl,

        [Parameter()]
        [String[]]
        $Connectors,

        [Parameter()]
        [String[]]
        $RetentionRules,

        [Parameter()]
        [Hashtable]
        $Variables,

        [Parameter()]
        [Switch]
        $CanPublish,

        [Parameter()]
        [Switch]
        $PackageStatisticsEnabled,

        [Parameter()]
        [Switch]
        $RestrictPackageStatistics,

        [Parameter()]
        [Switch]
        $DeploymentRecordsEnabled,

        [Parameter()]
        [Switch]
        $UsageRecordsEnabled,

        [Parameter()]
        [Switch]
        $VulnerabilitiesEnabled,

        [Parameter()]
        [Switch]
        $LicensesEnabled,

        [Parameter()]
        [Switch]
        $UseWithProjects
    )

    end {
        $params = @{
            Slug   = '/api/management/feeds/create'
            Method = 'POST'
            Body   = @{
                name                      = $Name
                alternateNames            = $AlternateNames
                feedType                  = $Type
                active                    = $Active.IsPresent
                cacheConnectors           = $CacheConnectors.IsPresent
                symbolServerEnabled       = $SymbolServerEnabled.IsPresent
                stripSymbols              = $StripSymbols.IsPresent
                stripsource               = $StripSource.IsPresent
                endpointUrl               = $EndpointUrl
                connectors                = $Connectors
                retentionRules            = $RetentionRules
                variables                 = $Variables
                canPublish                = $CanPublish.IsPresent
                packageStatisticsEnabled  = $PackageStatisticsEnabled.IsPresent
                restrictPackageStatistics = $RestrictPackageStatistics.IsPresent
                deploymentRecordsEnabled  = $DeploymentRecordsEnabled.IsPresent
                usageRecordsEnabled       = $UsageRecordsEnabled.IsPresent
                vulnerabilitiesEnabled    = $VulnerabilitiesEnabled.IsPresent
                licenseEnabled            = $LicensesEnabled.IsPresent
                useWithProjects           = $UseWithProjects.IsPresent
            }
        }

        if ($Type -eq 'chocolatey') {
            $params.Body.Add('useApiV3', $True)
        }

        Invoke-ProGet @params
    }
}