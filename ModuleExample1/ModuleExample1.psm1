<#
.Synopsis
   Display a visual representation of a calendar

.DESCRIPTION
   Display a visual representation of a calendar. This function supports multiple months
   and lets you hightlight specific date ranges or days. 

.PARAMETER Start
   The first month to display

.PARAMETER End
   The last month to display

.PARAMETER FirstDayOfWeek
   The day of the month on which the week begins.

.PARAMETER HighlightDay
   Specific days (numbered) to highlight. Used for date ranges like (25..31). 
   Date ranges are specified by the Windows PowerShell range syntax. These dates
   are enclosed in square brackets. 

.PARAMETER HighlightDate
   Specific days (named) to highlight. These dates are surrounded by asterisks.  
  
.EXAMPLE
   # Show a default display of this month. 
   Show-Calendar

.EXAMPLE
   # Display a date range. 
   Show-Calendar -Start "March, 2010" -End "May, 2010"

.EXAMPLE
   # Highlight a range of days. 
   Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "December 25, 2008"
#>
function Show-Calendar
{
    [CmdletBinding()]
    Param
    (
        [DateTime] $start = [DateTime]::Today,
        [DateTime] $end = $start,
        $firstDayOfWeek,
        [int[]] $highlightDay,
        [string[]] $highlightDate = [DateTime]::Today.ToString()
    )

    Process
    {
        ## Determine the first day of the start and end months.
        $start = New-Object System.DateTime($start.Year,$start.Month,1)
        $end = New-Object System.DateTime($end.Year,$end.Month,1)

        #Write-Host "First day of the start month: $start"
        #Write-Host "The first of the end month: $end"

        ## Convert the highlighted dates into real dates
        [DateTime[]] $highlightDates = [DateTime[]] $highlightDate

        <#
        foreach ($hd in $highlightDates)
        {
            Write-Host "Highlight Date: $hd"
        }
        #>

        ## Retrieve the DateTimeFormat information so that the 
        ## calendar can be manipulated
        $dateTimeFormat = (Get-Culture).DateTimeFormat

        if($firstDayOfWeek)
        {
          $dateTimeFormat.FirstDayOfWeek = $firstDayOfWeek
        }

        $currentDay = $start

        ## Process the requried months
        while($start -le $end)
        {
           ## Return to an eariler point in the function if the first day of 
           ## the month is in the middle of the week.

           While($currentDay.DayOfWeek -ne $dateTimeFormat.FirstDayOfWeek)
           {
              $currentDay = $currentDay.AddDays(-1)
           }

           Write-Host "Current Day: $currentDay"
           ## Prepare to store information about this date range.
           $currentWeek = New-Object PsObject
           $dayNames = @()
           $weeks = @()


           ## Continue processing dates until the function reaches the end of
           ## the month. The function continues until the week is completed with
           ## days from the next month. 
           While(($currentDay -lt $start.AddMonths(1)) -or 
                 ($currentDay.DayOfWeek -ne $dateTimeFormat.FirstDayOfWeek))
           {
             ## Determine the day names to use to label the columns.
             $dayName = "{0:ddd}" -f $currentDay
             if($dayNames -notcontains $dayName)
             {
                $dayNames += $dayName
             }

             ## Pad the day number for display, hilightling if necessary.
             $displayDay = " {0,2} " -f $currentDay.Day

             ## Determine whether to highlight a specific date.
             if($highlightDate)
             {
                $compareDate = New-Object System.DateTime($currentDay.Year,$currentDay.Month,$currentDay.Day)
                if($highlightDate -contains $compareDate)
                {
                  $displayDay = "*" + ("{0,2}" -f $currentDay.Day) + "*"
                }

             }

             ## Otherwise, highlight as part of a date range.
             if($highlightDay -and ($highlightDay[0] -eq $currentDay.Day))
             {
                $displayDay = "[" + ("{0,2}" -f $currentDay.Day) + "]"
                $null,$highlightDay = $highlightDay
             }

             ## Add the day of the week and the day of the month as note properties.
             $currentWeek | Add-Member NoteProperty $dayName $displayDay

             ##Move to the next day of the month
             $currentDay = $currentDay.AddDays(1)

             ## If the function reaches the next week, store the current week
             ## in the week list and continue.
             if($currentDay.DayOfWeek -eq $dateTimeFormat.FirstDayOfWeek)
             {
                $weeks += $currentWeek
                $currentWeek = New-Object PsObject
             }
           }
           ## Format the week as a table.
           $calendar = $weeks | Format-Table $dayNames -auto | Out-String

           ## Add a centered header. 
           $width = ($calendar.Split("'n") | Measure-Object -Maximum Length).Maximum
           $header = "{0:MMMM yyyy}" -f $start
           $padding = "" * (($width - $header.Length) / 2)
           $displayCalendar = " 'n" + $padding + $header + "'n " + $calendar
           $displayCalendar.TrimEnd()

           ## Move to the next month
           $start = $start.AddMonths(1)

        }
    }
    
}

export-modulemember -function Show-Calendar
#Show-Calendar
#Show-Calendar -Start "June, 2015" -End "July, 2015"
#Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "December 25, 2008"