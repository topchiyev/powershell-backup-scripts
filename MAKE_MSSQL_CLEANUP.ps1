param (
    $BackupStore
)

if ([string]::IsNullOrEmpty($BackupStore)) {
    $msg =
        "Some required parameters are not provided. `r`n" +
        "These parameters are mandatory: `r`n" +
        "    -BackupStore `r`n"
    Out-String -InputObject $msg
    Return
}

$filenameFormat = 'yyyy-MM-dd_HH-mm-ss'
$fileExtension = 'bak'


Function GetDate
{
    param([string] $filename)

    $date = [DateTime]::MinValue
    try {
        $date = [DateTime]::ParseExact($filename, "$filenameFormat.$fileExtension", $null)
    } catch {
        $date = [DateTime]::MinValue
    }
    return $date
}

function GetFilename
{
    param([DateTime] $date)

    $filename = $date.ToString("$filenameFormat.$fileExtension")
    return $filename
}

function DatesEqual
{
    param([DateTime]$a, [DateTime]$b)

    if (
        $a.Year -ne $b.Year -or $a.Month -ne $b.Month -or $a.Day -ne $b.Day -or
        $a.Hour -ne $b.Hour -or $a.Minute -ne $b.Minute -or $a.Second -ne $b.Second
    )
    {
        return $false
    }
    else
    {
        return $true
    }

    
}

Function ProcessDate
{
    param([DateTime[]]$dates, [DateTime]$date, [DateTime]$today)

    Out-String -InputObject "Processing date: $date"


    # Leave all backups of last month

    # Leave 1 backup per day of previous month

    # Leave 1 backup per month of previous years

    $delete = $false

    if ($date.Year -eq $today.Year -and $date.Month -eq $today.Month)
    {
        Out-String -InputObject "This is a current month backup. Skipping..."
    }
    elseif ($date.Year -eq $today.Year -and $date.Month -eq ($today.Month - 1))
    {
        Out-String -InputObject "This is a previous month backup..."

        $dayDates = [Linq.Enumerable]::Where($dates, [Func[DateTime,bool]] { $args[0].Year -eq $date.Year -and $args[0].Month -eq $date.Month -and $args[0].Day -eq $date.Day })
        $dayDates = [Linq.Enumerable]::OrderByDescending($dayDates, [Func[DateTime,DateTime]] { $args[0] })
        $lastDayDate = [Linq.Enumerable]::FirstOrDefault($dayDates)

        Out-String -InputObject "lastDayDate: $lastDayDate"
            
        # Check if it's the last backup of the day
        if ( DatesEqual -a $date -b $lastDayDate )
        {
            Out-String -InputObject "This is the last backup of a day of the previous month. Skipping..."
        }
        else
        {
            $delete = $true
            Out-String -InputObject "This is an ordinary backup of the previous month. Deleting..."

        }
    }
    elseif ($date.Year -eq $today.Year -and $date.Month -lt ($today.Month - 1))
    {
        Out-String -InputObject "This is a backup of an earlier month..."

        $monthDates = [Linq.Enumerable]::Where($dates, [Func[DateTime,bool]] { $args[0].Year -eq $date.Year -and $args[0].Month -eq $date.Month })
        $monthDates = [Linq.Enumerable]::OrderByDescending($monthDates, [Func[DateTime,DateTime]] { $args[0] })
        $lastMonthDate = [Linq.Enumerable]::FirstOrDefault($monthDates)

        Out-String -InputObject "lastMonthDate: $lastMonthDate"
            
        # Check if it's the last backup of the month
        if ( DatesEqual -a $date -b $lastMonthDate )
        {
            Out-String -InputObject "This is the last backup of an earlier month. Skipping..."
        }
        else
        {
            $delete = $true
            Out-String -InputObject "This is an ordinary backup of an earlier month. Deleting..."
        }
    }
    elseif ($date.Year -lt $today.Year)
    {
        Out-String -InputObject "This is a backup of an earlier year..."

        $yearDates = [Linq.Enumerable]::Where($dates, [Func[DateTime,bool]] { $args[0].Year -eq $date.Year })
        $yearDates = [Linq.Enumerable]::OrderByDescending($yearDates, [Func[DateTime,DateTime]] { $args[0] })
        $lastYearDate = [Linq.Enumerable]::FirstOrDefault($yearDates)

        Out-String -InputObject "lastYearDate: $lastYearDate"
            
        # Check if it's the last backup of the year
        if ( DatesEqual -a $date -b $lastYearDate )
        {
            Out-String -InputObject "This is the last backup of an earlier year. Skipping..."
        }
        else
        {
            $delete = $true
            Out-String -InputObject "This is an ordinary backup of an earlier year. Deleting..."
        }
    }

    if ($delete)
    {
        $filename = GetFilename -date $date
        $path = "$BackupStore\$filename"
        Remove-Item -Path $path
    }
}


Out-String -InputObject "Processing store:  $BackupStore"
$backups = Get-ChildItem -Name -File -Include "*.$fileExtension" -Path $BackupStore
$backups = [string[]] $backups

if ($backups.Count -eq 0) {
    Out-String -InputObject "Store is empty. Skipping"
    return
}

$dates = [Linq.Enumerable]::Select($backups, [Func[string,DateTime]] { GetDate -filename $args[0] })
$dates = [Linq.Enumerable]::Where($dates, [Func[DateTime,bool]] { $args[0] -ne [DateTime]::MinValue })
$dates = [Linq.Enumerable]::OrderBy($dates, [Func[DateTime,DateTime]] { $args[0] })
$dates = [Linq.Enumerable]::ToArray($dates)

$today = Get-Date

while ($dates.Length -gt 0)
{
    $date = $dates[0]
    ProcessDate -dates $dates -date $date -today $today
    $dates = [Linq.Enumerable]::Where($dates, [Func[DateTime,bool]] { $args[0] -ne $date })
    $dates = [Linq.Enumerable]::ToArray($dates)
}
