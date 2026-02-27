function Invoke-GetTaskStoredProc {
    [CmdletBinding()]
    param()
    $Connection = Get-ProGetDatabase

    switch ($Connection.Type) {
        "SQLServer" {
            Add-Type -AssemblyName "System.Data"

            $connection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString)
            $connection.Open()

            try {
                $command = $connection.CreateCommand()
                $command.CommandType = [System.Data.CommandType]::StoredProcedure
                $command.CommandText = 'dbo.Security_GetTasks'

                $reader = $command.ExecuteReader()
                $results = [System.Collections.Generic.List[pscustomobject]]::new()

                while ($reader.Read()) {
                    $row = @{}
                    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                        $column = $reader.GetName($i)
                        $row[$column] = $reader.GetValue($i)
                    }
                    $results.Add([PSCustomObject]$row)
                }
                $reader.Close()

                $results
            } catch {
                Write-Error "An error occurred: $_"
            } finally {
                $connection.Close()
            }
        }
        "PostgreSQL" {
            try {
                $TemporaryFile = New-TemporaryFile
                Set-Content -Path $TemporaryFile -Value 'SELECT "Task_Id", "Task_Name" FROM "Security_GetTasks"();'

                if (Resolve-Path $env:ProgramFiles\ProGet\Service\proget.exe) {
                    & (Join-Path $env:ProgramFiles "ProGet\Service\proget.exe") query --file="$($TemporaryFile.FullName)" | ConvertFrom-CSV
                } else {
                    Write-Error "Could not find proget.exe"
                }
            } finally {
                Remove-Item $TemporaryFile.FullName
            }
        }
    }
}