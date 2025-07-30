function Get-ProGetConnector {
<#
    .SYNOPSIS
    Retrieves information about connectors in ProGet.

    .DESCRIPTION
    The `Get-ProGetConnector` function retrieves details about one or more connectors in ProGet. If a connector name is provided, it retrieves information for that specific connector. If no name is provided, it lists all connectors.

    .PARAMETER Name
    The name of the connector to retrieve. If not specified, all connectors are listed.

    .EXAMPLE
    Get-ProGetConnector

    Retrieves a list of all connectors in ProGet.

    .EXAMPLE
    Get-ProGetConnector -Name "MyConnector"

    Retrieves details about the connector named "MyConnector".
#>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Get-ProGetConnector')]
    Param(
        [Parameter()]
        [String]
        $Name
    )

    process{
        $params = @{
            Method = 'GET'
        }

        if($Name){
            $params.add('Slug',"/api/management/connectors/get/$Name")
        }
        else {
            $params.Add('Slug','/api/management/connectors/list')
        }

        Invoke-ProGet @params
    }
}