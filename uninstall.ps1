# Stops Health reminders and removes its Start menu and Startup shortcuts. The folder itself is left alone.
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*HealthReminders.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
foreach ($dir in [Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('Startup')) {
    $p = Join-Path $dir 'Health reminders.lnk'
    if (Test-Path $p) { Remove-Item $p; Write-Host "  Removed: $p" }
}
Write-Host 'Done. You can now delete this folder.'
