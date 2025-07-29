function Remove-ProGetApiKey {
    <#
    .SYNOPSIS
    Removes a specified API key.

    .DESCRIPTION
    Removes a specific API key from the currently available ProGet server.
    
    .EXAMPLE
    Remove-ProGetApiKey -Id 1000

    # Removes the specified API key.

    .EXAMPLE
    Get-ProGetApiKey -User bob | Remove-ProGetApiKey -Confirm:$false

    # Removes API keys linked to the user 'bob'.

    .EXAMPLE
    Get-ProGetApiKey | Where Type -eq 'SYSTEM' | Remove-ProGetApiKey

    # Removes system API keys.

    .LINK
    https://docs.inedo.com/docs/proget/api/apikeys/delete
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High", HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Remove-ProGetApiKey')]
    param(
        # The ID of the API key to remove.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [int[]]
        $Id
    )
    process {
        foreach ($ApiKeyId in $Id) {
            $RequestParams = @{
                Slug = "/api/api-keys/delete?id=$($ApiKeyId)"
                Method = "Delete"
            }
            if ($PSCmdlet.ShouldProcess($Id, "Removing API Key")) {
                $null = Invoke-ProGet @RequestParams
            }
        }
    }
}