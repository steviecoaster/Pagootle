function Get-ProGetDatabase {
    [CmdletBinding()]
    param(
        [string]$Path = $(Join-Path $env:ProgramData "\Inedo\SharedConfig\ProGet.config")
    )
    $Content = [xml](Get-Content $Path)
    if (-not $Content.InedoAppConfig) {
        throw "Configuration file at '$Path' seems to be malformed."
    }

    if ($Content.InedoAppConfig.PostgresConnectionString) {
        # Configured Postgres
        [PSCustomObject]@{Type = 'PostgreSQL'; ConnectionString = $Content.InedoAppConfig.PostgresConnectionString}
    } elseif ($Content.InedoAppConfig.ConnectionString) {
        # Configured SQL Server
        [PSCustomObject]@{Type = 'SQLServer'; ConnectionString = $Content.InedoAppConfig.ConnectionString}
    } else {
        # Default Postgres
        [PSCustomObject]@{Type = 'PostgreSQL'; ConnectionString = '?'}
    }
}