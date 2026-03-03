function Invoke-GetUserStoredProc {
    <#
        .SYNOPSIS
       Private function that executes dbo.Users_GetUsers stored procedure in ProGet Database
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]
        $Username
    )
    $Connection = Get-ProGetDatabase

    switch ($Connection.Type) {
        "SQLServer" {
            Add-Type -AssemblyName "System.Data"

            $connection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString)
            $connection.Open()

            try {
                $command = $connection.CreateCommand()
                $command.CommandType = [System.Data.CommandType]::StoredProcedure
                $command.CommandText = 'dbo.Users_GetUsers'

                $parameter = $command.Parameters.Add("@User_Name", [System.Data.SqlDbType]::NVarChar, 50)
                $parameter.Value = if ($Username) {
                    $Username
                } else {
                    [DBNull]::Value
                }

                $reader = $command.ExecuteReader()
                $results = [System.Collections.Generic.List[pscustomobject]]::new()

                while ($reader.Read()) {
                    $row = @{}
                    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                        $column = $reader.GetName($i)
                        $exclude = @('Password_Bytes', 'Salt_Bytes')
                        if ($column -notin $exclude) {
                            $row[$column] = $reader.GetValue($i)
                        }
                    }
                    $results.Add([PSCustomObject]$row)
                }
                $reader.Close()

                $results
            }
            catch {
                Write-Error "An error occurred: $_"
            }
            finally {
                $connection.Close()
            }
        }
        "PostgreSQL" {
            try {
                $TemporaryFile = New-TemporaryFile
                Set-Content -Path $TemporaryFile -Value @(
                    'SELECT "User_Name", "Display_Name", "Email_Address" FROM "Users_GetUsers"('
                    if ($Username) {
                        "    '$($Username)'::varchar"
                    }
                    ');'
                )

                if (Resolve-Path $env:ProgramFiles\ProGet\Service\proget.exe) {
                    & (Join-Path $env:ProgramFiles "ProGet\Service\proget.exe") query --file="$($TemporaryFile.FullName)" | ConvertFrom-Csv
                } else {
                    Write-Error "Could not find proget.exe"
                }
            } finally {
                Remove-Item $TemporaryFile.FullName
            }
        }
    }
}