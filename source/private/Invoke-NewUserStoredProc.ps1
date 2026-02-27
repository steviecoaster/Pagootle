function Invoke-NewUserStoredProc {
  <#
    .SYNOPSIS
    Private function that executes dbo.Users_CreateOrUpdateUser stored procedure in ProGet Database
  #>
  param (
    [Parameter()]
    [string]
    $ConnectionString = 'Server=Localhost\SQLEXPRESS;Database=ProGet;Trusted_Connection=true;',

    [Parameter(Mandatory)]
    [Hashtable]
    $Params,

    [Parameter()]
    [switch]
    $UseRemoting,

    [Parameter()]
    [string]
    $RemoteComputer,

    [Parameter()]
    [pscredential]
    $Credential
  )
  $ScriptBlock = {
    param ($Params, $GetDatabase)

    $Connection = & $GetDatabase

    switch ($Connection.Type) {
      "SQLServer" {
        Add-Type -AssemblyName "System.Data"

        $connection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString)
        $connection.Open()

        try {
          $command = $connection.CreateCommand()
          $command.CommandType = [System.Data.CommandType]::StoredProcedure
          $command.CommandText = 'dbo.Users_CreateOrUpdateUser'

          foreach ($key in $Params.Keys) {
            $null = $command.Parameters.AddWithValue($key, $Params[$key])
          }

          $null = $command.ExecuteNonQuery()
        } catch {
          Write-Error "An error occurred: $_"
        } finally {
          $connection.Close()
        }
      }
      "PostgreSQL" {
        try {
          $TemporaryFile = New-TemporaryFile
          Set-Content -Path $TemporaryFile -Value @(
            'Call "Users_CreateOrUpdateUser"('
            "    '$($Params.User_Name)'::varchar,"  # "@User_Name" character varying
            "    '$($Params.Display_Name)'::varchar,"  # "@Display_Name" character varying
            if ($Params.Email_Address) {
              "    '$($Params.Email_Address)'::varchar,"  # "@Email_Address" character varying
            } else {
              '    null,'
            }
            "    '$($Params.Groups_Xml)'::xml"  # "@Groups_Xml" xml
            ');'
          )

          if (Resolve-Path $env:ProgramFiles\ProGet\Service\proget.exe) {
            $null = & (Join-Path $env:ProgramFiles "ProGet\Service\proget.exe") query --file="$($TemporaryFile.FullName)"
          } else {
            Write-Error "Could not find proget.exe"
          }
        } finally {
            Remove-Item $TemporaryFile.FullName
        }
      }
    }
  }

  if ($UseRemoting) {
      # Execute on a remote machine using PowerShell remoting
      $RemoteArgs = @{
        ComputerName = $RemoteComputer
        ScriptBlock  = $ScriptBlock
        ArgumentList = $Params, (Get-Command Get-ProGetDatabase)
      }
      if ($Credential) {
        $RemoteArgs.Credential = $Credential
      }
      Invoke-Command @RemoteArgs
    } else {
      # Execute locally
      & $ScriptBlock $Params (Get-Command Get-ProGetDatabase)
    }
}