Param 
    (
        [Parameter(Mandatory=$true)][string]$fromFolder,                # The folder the files are going to be moved from
        [Parameter(Mandatory=$true)][string]$toFolder,                  # The folder the files are going to
        [int]$fileAge=365,                                                  # Number of before files are moved from fromFolder to toFolder
        [switch]$leaveFolders,                                              # Leave the folder structure in $fromFolder in place, this is only valid if it is a move operation
        [switch]$inverseRun,                                                # Run the inverse (toFolder goes to fromFolder, newer than fileAge)
        [switch]$keepDates,                                                 # Ensures the created and modification dates are the same 
        [switch]$setDatesFromFilename,                                      # Sets the dates from the filename - makes the assumption that the first ten characaters are the ISO date Standard YYYY-MM-DD
        [int]$testLimit = -1,                                               # The iteration will run this number of times to test behavior, not set will default to -1 which this or 0 will disable this 
        [switch]$dryRun                                                     # Does not perform the action, only outputs the log reference
    )


#requires -version 2
<#
.SYNOPSIS
  This moves items in the fromFolder to the toFolder but only if it is older than the specified number of days (defaults to 365) unless the inverse is selected.

.DESCRIPTION

.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>

.INPUTS
    Parameters for to and from folders, and the file age to move
    
.OUTPUTS
    Adding/Removing group memberships in AD
  
.NOTES
  Version:        0.1
  Author:         Justin Simmonds
  Creation Date:  2023-04-05
  Purpose/Change: Initial script development
  
.EXAMPLE
  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName
$logFile = "$PSScriptRoot\Logs\$(Get-Date -UFormat '+%Y-%m-%d-%H-%M')-$(if($dryRun){"DRYRUN-"})$([io.path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)).log"

#Script Variables - Declared to stop it being generated multiple times per run

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-Log ($logToWrite)
{
    Write-Output "$(Get-Date -UFormat '+%Y-%m-%d %H:%M:%S') - $logToWrite"
    Add-content $Logfile -value "$(Get-Date -UFormat '+%Y-%m-%d %H:%M:%S') - $logToWrite"
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Create Log folder if it does not exist
if (-not (Test-Path -Path $PSScriptRoot\Logs))
{
    New-Item -Path $PSScriptRoot\Logs -ItemType Directory -Force -Confirm:$false | Out-Null
}

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
Write-Log "Starting Processing"

#Handle Inversion
if (-not $inverseRun)
{
    Write-Log "Files will move from $fromFolder, to $toFolder where they are OLDER than $fileAge days"
    $fileAge = -$fileAge
}
else 
{
    Write-Log "Files will move from $fromFolder, to $toFolder where they are NEWER than $fileAge days"
    Write-Log "Inverse Run Enabled: Inversing Folders and File Age"
    $tempFolder = $null
    $tempFolder = $fromFolder
    $fromFolder = $toFolder
    $toFolder = $tempFolder
    $tempFolder = $null
}

# Test the folder paths
Write-Log "Testing Folder Paths"

#From Folder
Write-Log "Testing From Folder"
if(-not (Test-Path -Path $fromFolder))
{
    Write-Log "From Folder ($fromFolder) Does Not Exist, Exiting"
    exit 99
}
else 
{
    Write-Log "From Folder Exists, Continuing"
}

#To Folder
Write-Log "Testing To Folder"
if(-not (Test-Path -Path $toFolder))
{
    Write-Log "From Folder ($toFolder) Does Not Exist, Attempting to Create"
    try 
    {
        if (!$dryRun)
        {
            New-Item -Path $toFolder -ItemType Directory | Out-Null
            Write-Log "Creation of $toFolder successful, Continuing" 
        }
        else 
        {
            New-Item -Path $toFolder -ItemType Directory -WhatIf
        }
    }
    catch 
    {
        Write-Log "Creation of $toFolder failed, Exiting"
        exit 99
    }
}
else 
{
    Write-Log "To Folder Exists, Continuing"
}

$count = 0 # This is for testing purposes only

foreach ($item in (Get-ChildItem -Path $fromFolder -Recurse | Where-Object {$_.LastWriteTime -lt (get-date).AddDays($daysPast)}))
{
    
    $originPath = $null
    $originPath = ($item.FullName).Substring(0,($item.FullName).LastIndexOf("\"))
    $destinationPath = $null
    $destinationPath = "$toFolder$($item.FullName.Replace($fromFolder,''))"
    $destinationPath = $destinationPath.Substring(0,$destinationPath.LastIndexOf("\"))
    
    if(!(Test-Path -Path $destinationPath -PathType Container))
    {
        if (!$dryRun)
        {
            Write-Log "Creating Folder $destinationPath"
            New-Item -Path $destinationPath -ItemType Directory | Out-Null
        }
        else 
        {
            Write-Log "Creating Folder $destinationPath"
            New-Item -Path $destinationPath -ItemType Directory -WhatIf
        }
    }

    if (!($item.PSIsContainer))
    {
        Write-Log "Moving $($item.Name)"
        if (!$dryRun)
        {
            Move-Item $item.FullName $destinationPath
        }
        else 
        {
            Move-Item $item.FullName $destinationPath -WhatIf
        }
    }

    if ($setDatesFromFilename) 
    {
        $newItem = $null
        $newItem = Get-Item -Path "$destinationPath\$($item.Name)"

        if (($newItem.BaseName.Length -ge 10) -and ($newItem.BaseName.Substring(0,10) -match '\d{4}-\d{2}-\d{2}'))
        {
            
                if ($newItem.LastWriteTime -ne $Matches[0])
                {
                    Write-Log "Setting Modified Date (Last Write Date) to Filename Date ($($Matches[0])) on $($newItem.Name)"
                    if (!$dryRun)
                    {
                        $newItem.LastWriteTime = $Matches[0]
                    }
                }
                if ($newItem.Creation -ne $Matches[0])
                {
                    Write-Log "Setting Creation Date to Filename Date ($($Matches[0])) on $($newItem.Name)"
                    if (!$dryRun)
                    {
                        $newItem.CreationTime = $Matches[0]
                    }
                }
        }
    }

    if ($keepDates)
    {
        $newItem = $null
        $newItem = Get-Item -Path "$destinationPath\$($item.Name)"
        if ($newItem.LastWriteTime -gt $item.LastWriteTime)
        {
            Write-Log "Correcting Modified Date (Last Write Time) on $($newItem.Name)"
            if (!$dryRun)
            {
                $newItem.LastWriteTime = $item.LastWriteTime
            }
        }

        if ($newItem.CreationTime -gt $item.CreationTime)
        {
            Write-Log "Correcting Created Date on $($newItem.Name) - Origin File"
            if (!$dryRun)
            {
                $newItem.CreationTime = $item.CreationTime
            }
        }

        if ($newItem.CreationTime -gt $newItem.LastWriteTime)
        {
            Write-Log "Correcting Created Date on $($newItem.Name) - Last Write Date"
            if (!$dryRun)
            {
                $newItem.CreationTime = $newItem.LastWriteTime
            }
        }
    }

    if (!$leaveFolders)
    {
        
        if ((Get-ChildItem -Path $originPath).Count -eq 0)
        {
            Write-Log "Removing orgin folder $originPath as it is now empty"
            
            if (!$dryRun)
            {
                Remove-Item -Path $originPath
            }
            else 
            {
                Remove-Item -Path $originPath -WhatIf
            }
        }
    }


    if ($testLimit -gt 0 -and $count -lt $testLimit)  
    {
        $count++
    }
    elseif ($testLimit -gt 0 -and $count -ge $testLimit)
    {
        Exit
    }
}