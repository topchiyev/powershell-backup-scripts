Push-Location $PSScriptRoot

.\MAKE_FILE_BACKUP `
    -BackupStore 'C:\Backups\FILE\EXAMPLE.COM'`
    -RemoteHost '123.45.67.89' `
    -RemoteStoreAbsolutePath 'C:\Websites\example.com-resources\storage' `
    -RemoteUser 'EXAMPLEDOMAIN\exampleuser' `
    -RemotePassword 'examplepassword' `
    -SmbShareLocalAbsolutePath 'C:\Share' `
    -SmbShareRemoteRelativePath 'Share' `
    -SmbUser 'EXAMPLEDOMAIN\exampleuser' `
    -SmbPassword '@Smart3310'

Pop-Location