function Get-ProGetApiKey {
    <#
        .SYNOPSIS
        Returns a list of API keys.

        .DESCRIPTION
        Returns a list of API keys for the currently available ProGet server.
        These can be filtered by source and authentication.

        .EXAMPLE
        Get-ProGetApiKey

        # Returns all existing API keys.

        .EXAMPLE
        Get-ProGetApiKey -User "bob"

        # Returns all API keys for user 'bob'.

        .LINK
        https://docs.inedo.com/docs/proget/api/apikeys/list
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Get-ProGetApiKey')]
    [OutputType("ProGetApiKey")]
    param(
        # The name of the user to return keys for.
        [Parameter(ValueFromPipeline)]
        [string[]]
        $User
    )
    begin {
        $RequestParams = @{
            Slug = '/api/api-keys/list'
        }
        [ProGetApiKey[]]$Result = Invoke-ProGet @RequestParams
    }
    process {
        if ($User) {
            $Result.Where{$_.User -in $User}
        } else {
            $Result
        }
    }
}