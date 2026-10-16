# Adds Health reminders to the Start menu and to Startup (so it starts with Windows), then starts it.
# Run once from this folder; no admin needed. Keep the folder where it is afterwards.
$root    = $PSScriptRoot
$shell   = New-Object -ComObject WScript.Shell
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$launch    = "`"$(Join-Path $root 'launch.vbs')`""

foreach ($dir in [Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('Startup')) {
    $lnk = $shell.CreateShortcut((Join-Path $dir 'Health reminders.lnk'))
    $lnk.TargetPath = $wscript
    $lnk.Arguments = $launch
    $lnk.WorkingDirectory = $root
    $lnk.Description = 'Water and stretch reminders'
    $lnk.Save()
    Write-Host "  Shortcut: $dir"
}
Start-Process $wscript $launch
Write-Host 'Done. Look for the blue water-drop icon next to the clock (it may be under the ^ arrow).'
