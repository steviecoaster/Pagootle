function Import-ProGetAssetDirectoryFromArchive {
    <#
    .SYNOPSIS
    Uploads an archive to a folder in an asset directory.

    .DESCRIPTION
    Uploads an archive to a folder in an asset directory on the currently active ProGet server.

    .EXAMPLE
    Import-ProGetAssetDirectoryFromArchive -AssetDirectory Internal -Folder /boinstall -ArchivePath ~\Downloads\boinstallfiles.zip -Overwrite

    # Overwrites the current contents of the 'boinstall' folder with the contents of the boinstallfiles zip file.

    #>
    [CmdletBinding(SupportsShouldProcess, HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Import-ProGetAssetDirectoryFromArchive')]
    param(
        # The asset directory to upload to.
        [Parameter(Mandatory)]
        [ValidateScript({
            if ($_ -notin (Get-ProGetFeed -Type asset -Verbose:$false).Name) {
                throw "'$_' was not present on the connected ProGet server."
            }
            $true
        })]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetFeed -Type asset | Where-Object Name -like "$WordToComplete*" | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_.Name)
            }
        })]
        [string]
        $AssetDirectory,

        # The folder to unpack the archive into.
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            Get-ProGetAssetDirectoryItem -AssetDirectory $FakeBoundParameters.AssetDirectory -Recurse | Where-Object {
                $_.Type -eq 'dir' -and
                "$($_.Parent, $_.Name -join '/')".TrimStart('/') -like "*$WordToComplete*"
            } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/'),
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/'),
                    "ParameterValue",
                    "$($_.Parent, $_.Name -join '/')".TrimStart('/')
                )
            }
        })]
        [string]
        $Folder,

        # The archive to upload.
        [string]
        $ArchivePath,

        # If set, overwrites any existing files with the archive contents.
        [switch]
        $Overwrite
    )
    end {
        $RequestParams = @{
            Slug = "/endpoints/$($AssetDirectory)/import/$($Folder.TrimStart('/'))?format=$((Get-Item $ArchivePath).Extension.TrimStart('.'))&overwrite=$($Overwrite)"
            Method = "POST"
            File = Convert-Path $ArchivePath
        }
        if ($PSCmdlet.ShouldProcess("Uploading '$($ArchivePath | Split-Path -Leaf)' to $($AssetDirectory)/$($Folder.TrimStart('/'))")) {
            $null = Invoke-ProGet @RequestParams
        }
    }
}