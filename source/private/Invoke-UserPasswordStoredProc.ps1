function Invoke-UserPasswordStoredProc {
    <#
        .SYNOPSIS
        Private function that executes Users_SetPassword stored procedure in ProGet Database
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Hashtable]
        $Params
    )
    $Connection = Get-ProGetDatabase

    switch ($Connection.Type) {
        "SQLServer" {
            Add-Type -AssemblyName "System.Data"

            $connection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString)
            $connection.Open()

            $command = $connection.CreateCommand()
            $command.CommandType = [System.Data.CommandType]::StoredProcedure
            $command.CommandText = 'dbo.Users_SetPassword'

            $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@User_Name", [Data.SqlDbType]::NVarChar, 50))).Value = $Params['User_Name']
            $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Password_Bytes", [Data.SqlDbType]::Binary, 20))).Value = $Params['Password_Bytes']
            $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Salt_Bytes", [Data.SqlDbType]::Binary, 10))).Value = $Params['Salt_Bytes']

            try {
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
                    'Call "Users_SetPassword"('
                    "    '$($Params['User_Name'])'::varchar,"
                    "    decode('$(-join($Params.Password_Bytes | ForEach-Object ToString X2))', 'hex'),"
                    "    decode('$(-join($Params.Salt_Bytes | ForEach-Object ToString X2))', 'hex')"
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