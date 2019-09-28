# Parameters

param (
    $BackupStore,
    $RemoteHost,
    $SqlInstance,
    $SqlDatabase,
    $SqlUser,
    $SqlPassword,
    $SmbShareLocalAbsolutePath,
    $SmbShareRemoteRelativePath,
    $SmbUser,
    $SmbPassword
)

# Collect all parameters for easier check

$params =
    $BackupStore,
    $RemoteHost,
    #$SqlInstance,
    $SqlDatabase,
    $SqlUser,
    $SqlPassword,
    $SmbShareLocalAbsolutePath,
    $SmbShareRemoteRelativePath,
    $SmbUser,
    $SmbPassword

# Check received all required parameters

foreach ($item in $params) {
    if ([string]::IsNullOrEmpty($item)) {
        $msg =
            "Some required parameters are not provided. `r`n" +
            "These parameters are mandatory: `r`n" +
            "    -BackupStore `r`n" +
            "    -RemoteHost `r`n" +
            "    -SqlDatabase `r`n" +
            "    -SqlUser `r`n" +
            "    -SqlPassword `r`n" +
            "    -SmbShareLocalAbsolutePath `r`n" +
            "    -SmbShareRemoteRelativePath `r`n" +
            "    -SmbUser `r`n" +
            "    -SmbPassword `r`n" +
            "These parameters are optional: `r`n" +
            "    -SqlInstance `r`n"
        Out-String -InputObject $msg
        Return
    }
}

# Prepare variables

$filenameFormat = 'yyyy-MM-dd_HH-mm-ss'
$fileExtension = 'bak'

$date = Get-date; $date = $date.ToString($filenameFormat);
$file = "$date.$fileExtension"
$localPath = "$BackupStore\$file"
$remotePath = "$SmbShareLocalAbsolutePath\$file"
$smbSharePath = "\\$RemoteHost\$SmbShareRemoteRelativePath"
$smbFilePath = "$smbSharePath\$file"

$sqlPasswordSecure = ConvertTo-SecureString -String $SqlPassword -AsPlainText -Force
$sqlCredentials = New-Object System.Management.Automation.PSCredential ($SqlUser, $sqlPasswordSecure)
$sqlInstancePath = $RemoteHost
if (![string]::IsNullOrEmpty($SqlInstance)) {
    $sqlInstancePath = "$sqlInstancePath\$SqlInstance"
}

$smbPasswordSecure = ConvertTo-SecureString -String $SmbPassword -AsPlainText -Force
$smbCredentials = New-Object System.Management.Automation.PSCredential ($SmbUser, $smbPasswordSecure)
$smbTempDrive = 'SMB_TEMP_DRIVE'

# Remove old file if exists
if (Test-Path -Path $localPath) {
    Remove-Item -Path $localPath
}

# Generate backup
Backup-SqlDatabase -ServerInstance $sqlInstancePath -Database $SqlDatabase -Credential $sqlCredentials -BackupFile $remotePath

# Connect SMB share
New-PSDrive $smbTempDrive -PSProvider FileSystem -Root $smbSharePath -Credential $smbCredentials

# Copy backup file from Remote SMB share to Local destination
Copy-Item $smbFilePath -Destination $localPath

# Remove backup file from Remote SMB share 
Remove-Item $smbFilePath

# Disonnect SMB share
Remove-PSDrive $smbTempDrive

Out-String -InputObject "Backup saved at ""$localPath"""