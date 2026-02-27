function Set-ProGetFeedDropPath {
    <#
    .SYNOPSIS
    Creates or updates the drop path for a ProGet feed.

    .DESCRIPTION
    The `Set-ProGetFeedDropPath` function allows you to set or update the drop path for a specified ProGet feed.
    The drop path is used to specify a directory where packages can be dropped for processing by the feed.

    .PARAMETER Feed
    The name of the feed for which the drop path is being set. This parameter is mandatory.

    .PARAMETER DropPath
    The directory path to set as the drop path for the feed. If not specified, the drop path will be cleared.

    .EXAMPLE
    Set-ProGetFeedDropPath -Feed "MyFeed" -DropPath "C:\Packages\Drop"

    Sets the drop path for the feed "MyFeed" to "C:\Packages\Drop".

    .EXAMPLE
    Set-ProGetFeedDropPath -Feed "MyFeed"

    Drop Path will default to C:\Drop\MyFeed.

    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/Pagootle/Commands/Set-ProGetFeedDropPath')]
    param(
        [Parameter(Mandatory)]
        [String]
        $Feed,

        [Parameter()]
        [String]
        $DropPath
    )

    $dropArgs = @{
        Feed = $Feed
    }

    if ($DropPath) {
        $dropArgs.Add('DropPath', $DropPath)
    }

    Invoke-NewDropPathStoredProc @dropArgs
}