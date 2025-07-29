class ProGetApiKey {
    # See: https://github.com/steviecoaster/Pagootle/blob/main/source/private/Invoke-NewUserStoredProc.ps1
    [int]$Id                                            # ProGet-generated unique ID for an API key; used when deleting a key and can never be set
    [ProGetApiKeyType]$Type                             # Type of API key; may be feed, feedgroup?, system, user
    [securestring]$SecureKey                            # Api may provide Api Key text itself if hashing is disabled; This is a securestring version of that.
    [string]$DisplayName                                # Used in lists of keys, and when not specified, a name like "(ID=1000)" is displayed
    [string]$Description                                # Used to describe the usage or other context about the key
    [datetime]$Expiration                               # Expiry of the key; if unset, will currently present as 0001-01-01 ([datetime]0)
    [string]$User                                       # Name of the user the personal key applies to; required when Type is Personal (otherwise must be null)
    [ProGetApiKeyPackagePermission]$PackagePermissions  # Permissions a feed key may have; Value is a combination of "view","add","promote","delete"
    hidden [ProGetApiKeySystemApis]$_SystemApis         # APIs a system key may use; Value is either ["full-control"] or a combination of "feeds", "sca", "sbom-upload"
    [string]$Feed                                       # Name of the feed the feed key applies to
    [string]$FeedGroup                                  # Name of the feed group the key applies to
    $Logging

    ProGetApiKey ($InputObject) {
        # Handle conversion of the SystemApis back into enum friendly characters
        if ($InputObject.SystemApis.Count) {
            $TempSystemApis = @()
            $InputObject.SystemApis.ForEach{
                $TempSystemApis += $_ -replace '-','_'
            }
            $this._SystemApis = $TempSystemApis
        }
        # Add a "read-only" property to access SystemApis, so it doesn't try and cast bad values later
        $this.PSObject.Properties.Add(
            (New-Object PSScriptProperty 'SystemApis', {$this._SystemApis})
        )

        # The key may not be available if hashing is enabled
        if ($InputObject.Key) {
            $this.SecureKey = ConvertTo-SecureString $InputObject.Key -AsPlainText -Force
        }

        # Grab any missing properties and assign them
        foreach ($Property in $InputObject.PSObject.Properties.Name) {
            if ($this.PSObject.Properties.Where{$_.MemberType -eq 'Property'}.Name -contains $Property) {
                if (-not $this.Property) {
                    $this.$Property = $InputObject.$Property
                }
            } else {
                Write-Debug "Unexpected property '$Property' found."
            }
        }
    }
}