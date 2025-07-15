function Invoke-ProGet {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [String]
        $Slug,

        [Parameter()]
        [String]
        $Method = 'GET',

        [Parameter()]
        [Hashtable]
        $Body,

        [Parameter()]
        [Hashtable]
        $Form,

        [Parameter()]
        [String]
        $BodyJson,

        [Parameter()]
        [String]
        $File,

        [Parameter()]
        [String]
        $ContentType = 'application/json'
    )
    begin {
        $Configuration = Get-ProGetConfiguration
        
        # If we call this from some commands we have to use a special API key.
        $caller = (Get-PSCallStack)[1].Command
        $ApiKeyRequests = @('New-ProGetFeed', 'Get-ProGetAssetDirectoryItem')
    }
    end {
        $ssl = if ($Configuration['UseSSL']) {
            @{Protocol = 'https' ; Port = $Configuration['SslPort'] }
        }
        else {
            @{Protocol = 'http'; Port = $Configuration['NonSslPort'] }
        }
        $Uri = '{0}:{1}{2}' -f "$($ssl['Protocol'])://$($Configuration['Hostname'])", $ssl['Port'], $Slug.TrimEnd('/')
        $ApiHeader = if ($caller -notin $ApiKeyRequests -and $Configuration.Credential) {
            @{'X-ApiKey' = $Configuration.Credential.GetNetworkCredential().Password }
        } elseif ($Configuration.ApiKey) {
            @{'X-ApiKey' = $Configuration.ApiKey.GetNetworkCredential().Password }
        }

        Write-Verbose -Message $Uri
        $params = @{
            Uri                  = $Uri
            Method               = $Method
            ContentType          = $ContentType
            Headers              = $ApiHeader
            Verbose              = $false
        }

        if ((Get-Command Invoke-RestMethod).Parameters.SkipCertificateCheck) {
            # We should probably remove this?
            $params.SkipCertificateCheck = $true
        }

        if ($Body) {
            $params['Body'] = $Body | ConvertTo-Json -Depth 5
        }

        if ($BodyJson) {
            $params['Body'] = $BodyJson
        }

        if ($Form) {
            $params['Form'] = $Form
            $params.Remove('ContentType')
        }

        if ($File) {
            $fileContent = [System.IO.File]::ReadAllBytes($File)
            $params['Body'] = $fileContent
            $params['ContentType'] = 'application/octet-stream'
            Write-Verbose $params.Uri
        }

        #Write-Verbose ($Body | ConvertTo-Json -Depth 5)
        Invoke-RestMethod @params
    }
}