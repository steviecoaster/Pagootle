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
        $ContentType = 'application/json',

        [Parameter()]
        [hashtable]
        $AdditionalParameters
    )
    begin {
        $Configuration = Get-ProGetConfiguration
    }
    end {
        $params = @{
            Uri                  = "$($Configuration.EndpointUrl.TrimEnd('/'))/$($Slug.TrimStart('/'))"
            Method               = $Method
            ContentType          = $ContentType
            Headers              = @{
                'X-ApiKey' = ([System.Net.NetworkCredential]::new("ApiKey", $Configuration.ApiKey)).Password
            }
            Verbose              = $false
        }

        if ($env:PagootleIgnoreInvalidCertificate -and (Get-Command Invoke-RestMethod).Parameters.SkipCertificateCheck) {
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
        }

        if ($AdditionalParameters) {
            $AdditionalParameters.GetEnumerator().ForEach{
                $params.$_ = $AdditionalParameters.$_
            }
        }

        Write-Verbose "[$($Method.ToUpper())] $($params.Uri)"
        Invoke-RestMethod @params
    }
}