function Get-ProGetPermission {
    <#
        .SYNOPSIS
            Gets existing permissions in ProGet.

        .DESCRIPTION
            Returns a full list of existing permissions in ProGet

        .EXAMPLE
            Get-ProGetPermission
            # Returns all permissions currently set on the current ProGet server.
    #>
    [CmdletBinding()]
    param()
    # Invoke-ProGet -Slug /api/security/permissions/list  # TODO: Consider using the proper API when available
    Invoke-GetPrivileges
}