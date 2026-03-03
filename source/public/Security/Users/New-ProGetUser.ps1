function New-ProGetUser {
    <#
    .SYNOPSIS
    Create a new ProGet user

    .DESCRIPTION
    Create a new ProGet user with the provided properties

    .PARAMETER Credential
    The credential object will set the username and password for the user

    .PARAMETER DisplayName
    The friendly name of the user account

    .PARAMETER EmailAddress
    The email address

    .PARAMETER Group
    Any groups the user should be included in

    .EXAMPLE
    New-ProGetUser -Credential (Get-Credential) -DisplayName 'Bobby Tables' -Group Users,Chocolatey

    .EXAMPLE
    New-ProGetUser -Credential $cred -DisplayName 'Jim Thome' -EmailAddress jim@fabrikam.com -Group Administrators
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/New-ProGetUser')]
    Param(
        [Parameter(Mandatory)]
        [PSCredential]
        $Credential,

        [Parameter(Mandatory)]
        [String]
        $DisplayName,

        [Parameter()]
        [string]
        $EmailAddress,

        [Parameter(Mandatory)]
        [String[]]
        $Group
    )
    $params = @{
        User_Name = $Credential.UserName
        Display_Name = $DisplayName
        Groups_Xml = ConvertTo-XmlString -Group $Group
    }

    if($EmailAddress){
        $params.add('Email_Address',$EmailAddress)
    }

    Invoke-NewUserStoredProc -Params $params
    Set-ProGetUserPassword -Credential $Credential
}