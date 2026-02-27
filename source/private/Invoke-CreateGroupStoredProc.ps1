function Invoke-CreateGroupStoredProc {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateLength(1,50)]
        [String]$Name
    )
    begin {
        $Connection = Get-ProGetDatabase

        switch ($Connection.Type) {
            "SQLServer" {
                Add-Type -AssemblyName "System.Data"

                # Create and open SQL connection
                $sqlConnection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
                $sqlConnection.Open()
            }
        }
    }
    process {
        switch ($Connection.Type) {
            "SQLServer" {
                # Create SqlCommand and specify it as a stored procedure
                $sqlCommand = $sqlConnection.CreateCommand()
                $sqlCommand.CommandText = "dbo.Users_CreateGroup"
                $sqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure

                # Add parameter
                $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Group_Name", [System.Data.SqlDbType]::NVarChar, 50))).Value = $Name

                # Execute the SqlCommand
                $sqlCommand.ExecuteNonQuery()
            }
            "PostgreSQL" {
                try {
                    $TemporaryFile = New-TemporaryFile

                    Set-Content -Path $TemporaryFile -Value @(
                        'Call "Users_CreateGroup"('
                        "    '$($Name)'::varchar"
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

        Write-Host "Group '$($Name)' added successfully to ProGet."
    }
    end {
        if ($sqlConnection) {
            # Close the connection
            $sqlConnection.Close()
        }
    }
}