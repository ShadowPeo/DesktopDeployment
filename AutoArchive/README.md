# AutoArchive

## Overview

This script is **mostly** complete; it accepts several inputs as outlined below and moves the files to the specified output directory. In my case, this is to create a hot/cold storage system using different storage providers.

## Parameters
**Bolded are required**
| Parameter | Description |
| ----------- | ----------- |
| **fromFolder** | The folder the files are going to be moved from |
| **toFolder** | The folder the files are going to |
| fileAge | Number of before files are moved from fromFolder to toFolder - Default is 365 |
| leaveFolders | Leave the folder structure in $fromFolder in place; this is only valid if it is a move operation |
| inverseRun | Run the inverse (toFolder goes to fromFolder, newer than fileAge) |
| keepDates | Ensures the created and modification dates are the same |
| setDatesFromFilename | Sets the dates from the filename - assumes that the first ten characters are the ISO date Standard YYYY-MM-DD |
| testLimit | The iteration will run this number of times to test behaviour, not set will default to -1, which this or 0 will disable this |
| dryRun | Does not act, only outputs the log reference |

## To Do
-   Exclusions for paths
    -   Based .gitignore type system as a file

# Filename Dates to Properties

## Overview

This script takes the first ten digits of the filename, checking to see if they are a valid ISO date, and sets the file properties to this date, alternatively, it can also set the creation date as the modified date


## Parameters
**Bolded are required**
| Parameter | Description |
| ----------- | ----------- |
| **baseFolder** | The folder of the files that are going to be processed |
| setDatesFromFilename | Sets the dates from the filename - makes the assumption that the first ten characaters are the ISO date Standard YYYY-MM-DD |
| copyDates | Copies Modified Date (Last Write Time) to Creation Date |
| dryRun | Does not perform the action, only outputs the log reference |
