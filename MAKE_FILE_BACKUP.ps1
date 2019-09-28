# Parameters

param (
    $BackupStore,
    $RemoteHost,
    $RemoteStoreAbsolutePath,
    $RemoteUser,
    $RemotePassword,
    $SmbShareLocalAbsolutePath,
    $SmbShareRemoteRelativePath,
    $SmbUser,
    $SmbPassword
)

# Collect all parameters for easier check

$params =
    $BackupStore,
    $RemoteHost,
    $RemoteStoreAbsolutePath,
    $RemoteUser,
    $RemotePassword,
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
            "    -RemoteStoreAbsolutePath 'r'n"
            "    -RemoteUser 'r'n" +
            "    -RemotePassword 'r'n" +
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
$fileExtension = 'zip'

$date = Get-date; $date = $date.ToString($filenameFormat);
$file = "$date.$fileExtension"
$localPath = "$BackupStore\$file"
$remotePath = "$SmbShareLocalAbsolutePath\$file"
$smbSharePath = "\\$RemoteHost\$SmbShareRemoteRelativePath"
$smbFilePath = "$smbSharePath\$file"

$remotePasswordSecure = ConvertTo-SecureString -String $RemotePassword -AsPlainText -Force
$remoteCredentials = New-Object System.Management.Automation.PSCredential ($RemoteUser, $remotePasswordSecure)

$smbPasswordSecure = ConvertTo-SecureString -String $SmbPassword -AsPlainText -Force
$smbCredentials = New-Object System.Management.Automation.PSCredential ($SmbUser, $smbPasswordSecure)
$smbTempDrive = 'SMB_TEMP_DRIVE'

# Remove old file if exists
if (Test-Path -Path $localPath) {
    Remove-Item -Path $localPath
}

# Connect Remote PS Session
$remoteSession = New-PSSession -ComputerName $RemoteHost -Credential $remoteCredentials

# Construct and call Archive command on the remote session
$remoteCommand = "Compress-Archive -Path '$RemoteStoreAbsolutePath\*' -CompressionLevel Optimal -DestinationPath '$remotePath'"
$remoteScriptBlock = [Scriptblock]::Create( $remoteCommand )
Invoke-Command -Session $remoteSession -ScriptBlock $remoteScriptBlock

# Disconnect Remote PS Session
Remove-PSSession $remoteSession


# Connect SMB share
New-PSDrive $smbTempDrive -PSProvider FileSystem -Root $smbSharePath -Credential $smbCredentials

# Copy backup file from Remote SMB share to Local destination
Copy-Item $smbFilePath -Destination $localPath

# Remove backup file from Remote SMB share 
Remove-Item $smbFilePath

# Disonnect SMB share
Remove-PSDrive $smbTempDrive

Out-String -InputObject "Backup saved at '$localPath'"