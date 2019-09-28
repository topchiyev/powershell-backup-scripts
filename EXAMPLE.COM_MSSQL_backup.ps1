Push-Location $PSScriptRoot

.\MAKE_MSSQL_BACKUP `
    -BackupStore 'C:\Backups\MSSQL\EXAMPLE.COM' `
    -RemoteHost '123.45.67.89' `
    -SqlInstance 'SQLEXPRESS' `
    -SqlDatabase 'EXAMPLE_DATABASE' `
    -SqlUser 'exampleuser' `
    -SqlPassword 'examplepassword' `
    -SmbShareLocalAbsolutePath 'C:\Share' `
    -SmbShareRemoteRelativePath 'Share' `
    -SmbUser 'EXAMPLEDOMAIN\exampleuser' `
    -SmbPassword 'examplepassword'

Pop-Location