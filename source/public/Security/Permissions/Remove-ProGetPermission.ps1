function Remove-ProGetPermission {
    <#
        .SYNOPSIS
            Removes a given ProGet permission.

        .DESCRIPTION
            Removes a given ProGet permission.

        .EXAMPLE
            Remove-ProGetPermission -Id 2
            # Removes the permission with id 2.

        .EXAMPLE
            Get-ProGetPermission | Where-Object Principal_Name -eq Anonymous | Remove-ProGetPermission
            # Removes anonymous permissions.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The Id of the permission to remove.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Privilege_Id')]
        [int]$Id
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Deleting Permission')) {
            # Invoke-ProGet -Slug /api/security/permissions/delete -Method DELETE -Body @{
            #     permissionId = $Id
            # }  # TODO: Consider using the proper API when available
            $Id | Invoke-RemovePrivilege  # TODO: Improve pipelineability.
        }
    }
}