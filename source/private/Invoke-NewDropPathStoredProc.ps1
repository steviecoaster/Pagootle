function Invoke-NewDropPathStoredProc {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]
        $Feed,

        [Parameter()]
        [String]
        $DropPath = 'C:\drop'
    )
    # Create the Drop Path directory
    if (-not $PSBoundParameters.ContainsKey('DropPath')) {
        $DropPath = Join-Path $DropPath -ChildPath $Feed
    }

    if (-not (Test-Path $DropPath)) {
        $null = New-Item $DropPath -ItemType Directory
    }

    # Assign permissions to the Inedo service user to the Drop Path
    $ServiceUser = (Get-CimInstance Win32_Service -Filter "Name = 'INEDOPROGETSVC'").StartName
    Set-ServiceUserPermission -FilePath $DropPath -ServiceUser $ServiceUser -Permissions Modify

    $Connection = Get-ProGetDatabase

    switch ($Connection.Type) {
        "SQLServer" {
            # Define SQL connection
            $connection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString)
            $connection.Open()

            # Create and execute SQL command
            $command = $connection.CreateCommand()
            $command.CommandText = @"
DECLARE @Feed_Id INT
SET @Feed_Id = (SELECT Feed_Id FROM Feeds WHERE Feed_Name = @Feed)

EXEC [dbo].[Feeds_SetFeedProperty]
@Feed_Id = @Feed_Id,
@DropPath_Text = @DropPath
"@
            $null = $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Feed", $Feed)))
            $null = $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@DropPath", $DropPath)))
            $null = $command.ExecuteNonQuery()

            # Close connection
            $connection.Close()
        }
        "PostgreSQL" {
            try {
                $TemporaryFile = New-TemporaryFile
                Set-Content -Path $TemporaryFile -Value @(
                    'DO $$'
                    '    DECLARE feed_id integer;'
                    'BEGIN'
                    '    SELECT "Feed_Id"'
                    '    INTO feed_id'
                    '    FROM "Feeds_GetFeeds"(true)'
                    '    WHERE "Feed_Name" = '
                    "    '$($Feed)'::varchar;"
                    '    CALL "Feeds_SetFeedProperty"('
                    '        feed_id,null,null,null,null,null,'
                    "        '$($DropPath)'"
                    '    );'
                    'END $$;'
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