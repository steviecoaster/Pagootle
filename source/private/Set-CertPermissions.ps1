function Set-CertPermissions {
    <#
    .SYNOPSIS
    Sets the permissions on the private key for a given certificate
    
    .DESCRIPTION
    Long description
    
    .PARAMETER Thumbprint
    Parameter description
    
    .PARAMETER Location
    Parameter description
    
    .PARAMETER Store
    Parameter description
    
    .PARAMETER ServiceUser
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Thumbprint,

        [Parameter(Mandatory)]
        [String]
        $Location,
  
        [Parameter(Mandatory)]
        [String]
        $Store,

        [Parameter(Mandatory)]
        [String]
        $ServiceUser

    )
    end {

        # Load the certificate from the specified store
        $certStore = New-Object System.Security.Cryptography.X509Certificates.X509Store $Store, $Location
        $certStore.Open("ReadOnly")
        $certificate = $certStore.Certificates | Where-Object { $_.Thumbprint -eq $thumbprint }

        if (-not $certificate) {
            Write-Error "Certificate with thumbprint $thumbprint not found in LocalMachine\My."
            $certStore.Close()
            return
        }

        # Get the private key file path
        $privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certificate)
        $uniqueName = $privateKey.key.uniquename
        $keyPath = Join-Path $env:ProgramData "Microsoft\Crypto\RSA\MachineKeys\$($uniquename)"
        
        # Close the certificate store if we have a private key, otherwise error that there is a problem finding a private key
        if (Test-Path $keyPath) {
            $certStore.Close()
        }
        else {
            Write-Error "Unable to locate the private key for the certificate."
            $certStore.Close()
            return
        }

        # Grant Inedo Service user read access to the private key
        Set-ServiceUserPermission -FilePath $keyPath -ServiceUser $ServiceUser -Permissions Read
    }
}