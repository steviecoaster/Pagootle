function Set-ProGetUserPassword {
<#
    .SYNOPSIS
    Sets the password for a ProGet user account

    .PARAMETER Credential
    The credential object that contains the username and updated password for the account you wish to update

    .EXAMPLE
    Set-ProGetUserPassword -Credential (Get-Credential)

    Pass a PSCredential object with the username and new password and the user account will be updated.
#>
    [Cmdletbinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Set-ProGetUserPassword')]
    Param(
        [Parameter(Mandatory)]
        [Alias('Username')]
        [PSCredential]
        $Credential
    )
    end {

        $iterations = 10000
        $saltLength = 10
        $hashLength = 20

        $rfc2898 = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Credential.GetNetworkCredential().Password, $saltLength, $iterations)
        $passwordBytes = $rfc2898.GetBytes($hashLength)
        $saltBytes = $rfc2898.Salt

        $Params = @{
            User_Name      = $Credential.UserName
            Password_Bytes = $passwordBytes
            Salt_Bytes     = $saltBytes
        }

        Invoke-UserPasswordStoredProc -Params $Params
    }
}