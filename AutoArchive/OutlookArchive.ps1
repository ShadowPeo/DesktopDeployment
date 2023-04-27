[Reflection.Assembly]::LoadWithPartialname("Microsoft.Office.Interop.Outlook")

$olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type] 
$outlook = new-object -comobject outlook.application
$namespace = $outlook.GetNameSpace("MAPI")

$account = $namespace.Folders | Where-Object name -eq "<<EMAIL>>"

foreach ($folder in ($account.Folders | Sort-Object name))
{
    if ($folder.Name -eq "Inbox")
    {
        $subFolders = $folder.Folders
        foreach ($subFolder in ($subFolders | Sort-Object name))
        {
            $subFolder.Name
            ($subFolder.Folders -eq $null)
            if ($subFolder.Folders -eq $null)
            {
                Write-Host "This Folder has no Subfolders"
            }
        }
    }

}