function Invoke-RemovePrivilege {
    [CmdletBinding()]
    param(
        # The Id of the permission to remove.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Privilege_Id')]
        [int]$Id
    )
    begin {
        $Connection = Get-ProGetDatabase

        if ($Connection.Type -eq 'SQLServer') {
            $SqlConnection = [System.Data.SqlClient.SqlConnection]::new($SqlConnection.ConnectionString)
            $SqlConnection.Open()
        }
    }
    process {
        switch ($Connection.Type) {
            "SQLServer" {
                Add-Type -AssemblyName "System.Data"

                $command = $SqlConnection.CreateCommand()
                $command.CommandType = [System.Data.CommandType]::StoredProcedure
                $command.CommandText = 'dbo.Security_RemovePrivilege'

                $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@User_Name", [Data.SqlDbType]::Int))).Value = $Id

                try {
                    $null = $command.ExecuteNonQuery()
                } catch {
                    Write-Error "An error occurred: $_"
                }
            }
            "PostgreSQL" {
                try {
                    $TemporaryFile = New-TemporaryFile
                    Set-Content -Path $TemporaryFile -Value @(
                        'Call "Security_RemovePrivilege"('
                        "    $($Id)"
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
    end {
        if ($Connection.Type -eq 'SQLServer' -and $SqlConnection.State -eq 'Open') {
            $SqlConnection.Close()
        }
    }
}