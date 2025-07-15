class ProGetAssetDirectoryItem {
    # See: https://github.com/Inedo/pgutil/blob/thousand/Inedo.ProGet/AssetDirectories/AssetDirectoryItem.cs
    [string]$AssetDirectory
    [string]$Name        # The name of the Asset item (File or Folder)
    [string]$Parent      # The full path of the parent directory of the item
    [int64]$Size         # The number of bytes in size of the item.
    [string]$Type        # Either the Content-Type of the the item, or "dir" if the item represents a folder.
    [string]$Content     # The full URL of the item.
    [datetime]$Created   # The UTC date of the original creation time of the item
    [datetime]$Modified  # The UTC date of the last time of the item was updated
    [string]$MD5         # The MD5 hash of the item in hexadecimal format
    [string]$SHA1        # The SHA1 hash of the item in hexadecimal format
    [string]$SHA256      # The SHA256 hash of the item in hexadecimal format
    [string]$SHA512      # The SHA512 hash of the item in hexadecimal format
    $UserMetadata
    $CacheHeader

    ProGetAssetDirectoryItem ($InputObject) {
        $this.AssetDirectory = $InputObject.content -replace '^(?<Endpoint>.+)/endpoints/(?<AssetDirectory>.+?)/content/(?<FileName>.+)$', '${AssetDirectory}'
        $this.Modified = [DateTime]::Parse($InputObject.Modified, ([cultureinfo]::new("en-US", $false)), "AssumeUniversal")
        $this.Created = [DateTime]::Parse($InputObject.Created, ([cultureinfo]::new("en-US", $false)), "AssumeUniversal")
        
        foreach ($Property in $InputObject.PSObject.Properties.Name) {
            if ($this.PSObject.Properties.Where{$_.MemberType -eq 'Property'}.Name -contains $Property) {
                if (-not $this.$Property) {
                    $this.$Property = $InputObject.$Property
                }
            } else {
                Write-Debug "Unexpected property '$Property' found."
            }
        }
    }
}