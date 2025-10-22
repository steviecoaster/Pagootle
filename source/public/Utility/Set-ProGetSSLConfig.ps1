function Set-ProGetSslConfig {
    <#
  .SYNOPSIS
  Updates the ProGet configuration file and restarts the ProGet services.
  
  .DESCRIPTION
  This script updates the ProGet configuration file with specified parameters, handles SSL certificate settings, and restarts the ProGet services. It processes parameters, updates the XML configuration file, and ensures the correct attributes are set.
  
  .PARAMETER ConfigFile
  Specifies the path to the ProGet configuration file. Default is 'C:\ProgramData\Inedo\SharedConfig\ProGet.config'.
  
  .PARAMETER Location
  Specifies the location of the certificate store. Valid values are 'User' and 'LocalMachine'.
  
  .PARAMETER Store
  Specifies the certificate store. Valid values are 'My', and 'Root'.
  
  .PARAMETER Subject
  Specifies the subject name of the certificate.
  
  .PARAMETER AllowInvalid
  A switch parameter that allows invalid certificates if specified.
  
  .PARAMETER CertPassword
  Specifies the password for the certificate.
  
  .PARAMETER Urls
  Specifies the URLs for the web server to bind too.
  
  .EXAMPLE
  Set-ProGetSslConfig -Location 'Machine' -Store 'My' -Subject 'example.com' -AllowInvalid -CertPassword 'password' -Urls 'http://*:8624/'
  
  This command updates the ProGet configuration to use a certificate with the subject 'example.com' from the specified Windows certificate store.
  
  .EXAMPLE
  Set-ProGetSslConfig -CertFile "C:\proget_cert\cert.pfx" -CertPassword ('poshacme' | ConvertTo-SecureString -AsPlainText -Force) -Urls http://*:8624/,https://*:8443/
  
  Updates ProGet configuration to use the provided pfx file and pfx password to secure the ProGet instance. Also allows for non-http binding to port 8624
  
  .EXAMPLE
  Set-ProGetSslConfig -CertFile "C:\proget_cert\cert.pem" -KeyFile "C:\proget_cert\cert.key" -Urls http://*:8624/,https://*:8443/
  
  Updates ProGet configuration to use the provided pem and key file to secure the ProGet instance with SSL
  
  .NOTES
  
  #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Set-ProGetSslConfig')]
    Param(
        [Parameter(ParameterSetName = 'WindowsStore')]
        [Parameter(ParameterSetName = 'CertFile')]
        [Parameter(ParameterSetName = 'Pfx')]
        [String]
        $ConfigFile = 'C:\ProgramData\Inedo\SharedConfig\ProGet.config',
  
        [Parameter(Mandatory, ParameterSetName = 'WindowsStore')]
        [ValidateSet('User', 'LocalMachine')]
        [String]
        $Location,
  
        [Parameter(Mandatory, ParameterSetName = 'WindowsStore')]
        [ValidateSet('TrustedPeople', 'My', 'WebHosting')]
        [String]
        $Store,
  
        [Parameter(Mandatory, ParameterSetName = 'WindowsStore')]
        [String]
        $Subject,
  
        [Parameter(ParameterSetName = 'WindowsStore')]
        [Switch]
        $AllowInvalid,
  
        [Parameter(Mandatory, ParameterSetName = 'CertFile')]
        [Parameter(Mandatory,ParameterSetName = 'Pfx')]
        [ValidateScript({ Test-Path $_ })]
        [String]
        $CertFile,
  
        [Parameter(ParameterSetName = 'Pfx')]
        [SecureString]
        $CertPassword,
  
  
        [Parameter(ParameterSetName = 'CertFile')]
        [ValidateScript({ Test-Path $_ })]
        [String]
        $KeyFile,
  
        [Parameter(ParameterSetName = 'CertFile')]
        [Parameter(ParameterSetName = 'Pfx')]
        [Parameter(ParameterSetName = 'WindowsStore')]
        [ValidateScript({
            $_ | Foreach-object {
                if($psitem.EndsWith('/')){
                    $true
                } else {
                    throw "Url must end with a trailing '/'!"
                }
  
            }
        })]
        [String[]]
        $Urls = 'http://*:8624/'
  
    )
  
    end {
  
        #Update the configuration file
        [xml]$xml = Get-Content $ConfigFile
        $webServerNode = $xml.InedoAppConfig.WebServer
  
        #Set some defaults
        $webServerNode.attributes.RemoveAll()
        $webServerNode.SetAttribute('Enabled',$true)
  
        switch($PSCmdlet.ParameterSetName){
            'WindowsStore' {
                $PSBoundParameters.GetEnumerator() | ForEach-Object {
    
                    if ($_.Key -eq 'AllowInvalid') {
                        $webServerNode.SetAttribute($($_.Key), $([bool]$_.Value))
                    }
                    else {
                        $webServerNode.SetAttribute($_.Key, $_.Value)
                    }
                }
        
                if (-not $PSBoundParameters.ContainsKey('AllowInvalid')) {
                    $webServerNode.SetAttribute('AllowInvalid', $false)
                } else {
                    $webServerNode.SetAttribute('AllowInvalid',$AllowInvalid)
                }
                
                $certificateThumbprint = (Get-ChildItem Cert:\$($Location)\$($Store) | Where-Object {$_.Subject -like "CN=$Subject"}).Thumbprint
                $ServiceUser = (Get-CimInstance win32_service -Filter "Name = 'INEDOPROGETSVC'").StartName

                Set-CertPermissions -Thumbprint $certificateThumbprint -Location $Location -Store $Store -ServiceUser $ServiceUser
            }
  
            'CertFile' {
                $PSBoundParameters.GetEnumerator() | ForEach-Object {
                    if(-not ($_.Key -eq 'ConfigFile')){
                        $webServerNode.SetAttribute($_.Key,$_.Value)
                    }
                }
            }
  
            'Pfx' {
                $PSBoundParameters.GetEnumerator() | ForEach-Object {
                    if(-not ($_.Key -eq 'ConfigFile')){
                        if($_.Key -eq 'CertPassword'){
                            $tempCred = [System.Management.Automation.PSCredential]::new('toss',$CertPassword)
                            $CleartextPassword = $tempCred.GetNetworkCredential().Password
                            $webServerNode.SetAttribute('Password',$CleartextPassword)
                        } else {
                            $webServerNode.SetAttribute($_.Key,$_.Value)
                        }
                    }
                }
  
                if($webServerNode.HasAttribute('KeyFile')){
                    $webServerNode.RemoveAttribute('KeyFile')
                }
  
            }
        }
  
        #Handle port bindings
        if($urls){
            if($Urls.Count -gt 1){
                $webServerNode.SetAttribute('Urls',$($Urls -join ';'))
            }
            else {
                $webServerNode.SetAttribute('Urls',$Urls)
            }
        }
  
        #Write the config file
        $xml.Save($ConfigFile)

        #Update the permissions on the certificate private key, to give service user READ permissions
  
        #Restart the ProGet services
        Get-Service inedoproget* | Restart-Service
    }
  }