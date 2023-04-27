Param 
    (
        [Parameter(Mandatory=$true)][string]$baseFolder,                # The folder the files are going to be moved from
        [switch]$setDatesFromFilename,                                      # Sets the dates from the filename - makes the assumption that the first ten characaters are the ISO date Standard YYYY-MM-DD
        [switch]$copyDates,                                                 # Copies Modified Date (Last Write Time) to Creation Date
        [switch]$dryRun                                                     # Does not perform the action, only outputs the log reference
    )

#requires -version 2
<#
.SYNOPSIS
  This moves items in the baseFolder to the toFolder but only if it is older than the specified number of days (defaults to 365) unless the inverse is selected.

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

# Test the folder paths
Write-Log "Testing Folder Paths"

#Base Folder
Write-Log "Testing From Folder"
if(-not (Test-Path -Path $baseFolder))
{
    Write-Log "Base Folder ($baseFolder) Does Not Exist, Exiting"
    exit 99
}
else 
{
    Write-Log "From Folder Exists, Continuing"
}

foreach ($item in (Get-ChildItem -Path $baseFolder -Recurse))
{
    
    if ($setDatesFromFilename) 
    {
        if (($item.BaseName.Length -ge 10) -and ($item.BaseName.Substring(0,10) -match '\d{4}-\d{2}-\d{2}'))
        {
            
                if ($item.LastWriteTime -ne $Matches[0])
                {
                    Write-Log "Setting Modified Date (Last Write Date) to Filename Date $($Matches[0]) on $($item.Name)"
                    if (!$dryRun)
                    {
                        $item.LastWriteTime = $Matches[0]
                    }
                }
                if ($item.Creation -ne $Matches[0])
                {
                    Write-Log "Setting Creation Date to Filename Date $($Matches[0]) on $($item.Name)"
                    if (!$dryRun)
                    {
                        $item.CreationTime = $Matches[0]
                    }
                }
        }
    }

    if ($copyDates)
    {
        if ($item.CreationTime -gt $item.LastWriteTime)
        {
            Write-Log "Correcting Created Date on $($item.Name) - Last Write Date"
            if (!$dryRun)
            {
                $item.CreationTime = $item.LastWriteTime
            }
        }
    }
}