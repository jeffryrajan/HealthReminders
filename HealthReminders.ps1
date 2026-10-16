# Health reminders: a tray app that sends a walking character along the taskbar to remind you to
# drink water and to stretch. Start it with launch.vbs (no console window).
#   -Test             show the water character, then the stretch character, now
#   -Preview <folder> render the menu, settings window and characters to PNGs and exit
# Timers count time you are at the PC; 5 minutes away from the keyboard and mouse restarts them.
param([switch]$Test, [string]$Preview)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$Root = $PSScriptRoot
. (Join-Path $Root 'material.ps1')

if (-not $Preview) {
    $mutex = New-Object System.Threading.Mutex($false, 'Local\HealthReminders')
    if (-not $mutex.WaitOne(0)) { exit }   # already running
}

$SettingsPath = Join-Path $Root 'settings.json'
$script:busy = $false
$script:menuWin = $null
$script:walker = $null

# ---------------------------------------------------------------- settings

# settings.json: water_every_min, stretch_every_min (0 = off), on (false = all reminders stopped).
function Import-Settings {
    $s = @{ water_every_min = 30; stretch_every_min = 60; on = $true }
    if (Test-Path $SettingsPath) {
        try {
            $j = Get-Content $SettingsPath -Raw | ConvertFrom-Json
            foreach ($k in @($s.Keys)) { if ($null -ne $j.$k) { $s[$k] = $j.$k } }
        } catch { }
    }
    $script:Settings = $s
}

function Save-Settings {
    $s = $script:Settings
    $json = "{`n  `"water_every_min`": $([int]$s.water_every_min),`n  `"stretch_every_min`": $([int]$s.stretch_every_min),`n" +
            "  `"on`": $(if ($s.on) { 'true' } else { 'false' })`n}`n"
    [IO.File]::WriteAllText($SettingsPath, $json, (New-Object Text.UTF8Encoding $false))
}

Import-Settings

# ---------------------------------------------------------------- idle time

if (-not ('HealthReminders.Idle' -as [type])) {
    Add-Type -Namespace HealthReminders -Name Idle -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)] struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
[DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
public static uint Seconds() {
    LASTINPUTINFO li = new LASTINPUTINFO(); li.cbSize = (uint)Marshal.SizeOf(li);
    GetLastInputInfo(ref li);
    return ((uint)Environment.TickCount - li.dwTime) / 1000;
}
'@
}

# Seconds since the last keyboard or mouse input anywhere in Windows.
function Get-IdleSeconds { [HealthReminders.Idle]::Seconds() }

# ---------------------------------------------------------------- tray icon

# A blue circle with a white water drop.
function New-TrayIcon {
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#2B5EA7'))), 1, 1, 30, 30)
    $drop = New-Object System.Drawing.Drawing2D.GraphicsPath
    $drop.AddBezier(16, 6, 13, 11, 9, 15, 9, 19)
    $drop.AddArc(9, 12, 14, 14, 180, -180)
    $drop.AddBezier(23, 19, 23, 15, 19, 11, 16, 6)
    $g.FillPath([System.Drawing.Brushes]::White, $drop)
    $g.Dispose()
    [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

# ---------------------------------------------------------------- menu

function New-TextBlock($text, $size, $role, $weight = 'Normal') {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $text; $tb.FontSize = $size; $tb.FontWeight = $weight; $tb.VerticalAlignment = 'Center'
    $tb.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, $role)
    $tb
}

# One row of the menu: leading icon glyph and label.
function Add-MenuRow($win, $panel, $text, $glyph, [scriptblock]$action) {
    $b = New-Object System.Windows.Controls.Button
    $b.Style = $win.FindResource('MenuItem')
    $g = New-Object System.Windows.Controls.Grid
    foreach ($w in 36, '*') {
        $cd = New-Object System.Windows.Controls.ColumnDefinition
        $cd.Width = if ($w -eq '*') { New-Object System.Windows.GridLength 1, 'Star' } else { New-Object System.Windows.GridLength $w }
        $g.ColumnDefinitions.Add($cd)
    }
    $lead = New-TextBlock $glyph 16 'OnSurfaceVariant'; $lead.FontFamily = $IconFont
    [void]$g.Children.Add($lead)
    $label = New-TextBlock $text 14 'OnSurface'
    [System.Windows.Controls.Grid]::SetColumn($label, 1); [void]$g.Children.Add($label)
    $b.Content = $g
    $b.Tag = $action
    $b.Add_Click({ $act = $this.Tag; Close-Menu; & $act })
    [void]$panel.Children.Add($b)
}

function Add-MenuDivider($panel) {
    $d = New-Object System.Windows.Controls.Border
    $d.Height = 1; $d.Margin = '0,8'
    $d.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'OutlineVariant')
    [void]$panel.Children.Add($d)
}

function Close-Menu {
    if ($script:menuWin) { $w = $script:menuWin; $script:menuWin = $null; try { $w.Close() } catch { } }
}

function New-TrayMenu {
    $win = New-MaterialWindow -Body '<StackPanel x:Name="Items"/>' -Radius 16 -Padding '0,8' -Width 280 `
        -CardRole 'SurfaceContainer' -InTaskbar $false -Title 'Health reminders menu'
    $items = $win.FindName('Items')
    $lbl = New-TextBlock 'Health reminders' 12 'OnSurfaceVariant' 'SemiBold'; $lbl.Margin = '16,4,16,4'
    [void]$items.Children.Add($lbl)
    if ($script:Settings.on) {
        Add-MenuRow $win $items (Get-HealthLabel 'Water break' $script:waterDue) ([string][char]0xE916) { Show-HealthReminder water }
        Add-MenuRow $win $items (Get-HealthLabel 'Stretch' $script:stretchDue) ([string][char]0xE805) { Show-HealthReminder stretch }
        Add-MenuRow $win $items 'Stop reminders' ([string][char]0xE769) { $script:Settings.on = $false; Save-Settings; Update-Tip }
    } else {
        Add-MenuRow $win $items 'Start reminders' ([string][char]0xE768) { $script:Settings.on = $true; Reset-HealthClocks; Save-Settings; Update-Tip }
    }
    Add-MenuRow $win $items 'Reminder timers...' ([string][char]0xE713) { Invoke-Popup { if (Show-HealthSettings) { Reset-HealthClocks; Update-Tip } } }
    Add-MenuDivider $items
    Add-MenuRow $win $items 'Exit' ([string][char]0xE7E8) { Exit-Tray }
    $win.Add_Deactivated({ Close-Menu })
    $win.Add_PreviewKeyDown({ if ($_.Key -eq 'Escape') { Close-Menu } })
    $win
}

# Open the menu with its corner at the mouse pointer, kept inside the screen's work area.
function Show-TrayMenu {
    Close-Menu
    $win = New-TrayMenu
    $script:menuWin = $win
    $win.WindowStartupLocation = 'Manual'; $win.Left = -20000; $win.Top = -20000
    $win.Show(); $win.UpdateLayout()
    $px = [System.Windows.Forms.Cursor]::Position
    $m = [System.Windows.PresentationSource]::FromVisual($win).CompositionTarget.TransformFromDevice
    $pt = $m.Transform((New-Object System.Windows.Point $px.X, $px.Y))
    $area = [System.Windows.SystemParameters]::WorkArea
    $shadow = 20
    $x = $pt.X - $win.ActualWidth + $shadow
    $y = $pt.Y - $win.ActualHeight + $shadow
    if ($x -lt $area.Left - $shadow) { $x = $pt.X - $shadow }
    if ($y -lt $area.Top - $shadow) { $y = $pt.Y - $shadow }
    $win.Left = [math]::Max($area.Left - $shadow, [math]::Min($x, $area.Right - $win.ActualWidth + $shadow))
    $win.Top  = [math]::Max($area.Top - $shadow, [math]::Min($y, $area.Bottom - $win.ActualHeight + $shadow))
    $win.Activate()
}

function Invoke-Popup([scriptblock]$popup) {
    if ($script:busy) { return }
    $script:busy = $true
    try { & $popup } finally { $script:busy = $false }
}

function Exit-Tray {
    $notify.Visible = $false
    $notify.Dispose()
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
}

# ---------------------------------------------------------------- settings window

# Choose how often each character comes (0 turns one off). Returns $true when saved.
function Show-HealthSettings([string]$PreviewPath) {
    $body = @"
<StackPanel>
  <TextBlock Text="Health reminders" Style="{StaticResource Headline}"/>
  <TextBlock Style="{StaticResource Supporting}" Margin="0,8,0,0"
             Text="Counted while you're at the PC. 5 minutes away restarts the timers."/>
  <TextBlock Text="Water break every" Style="{StaticResource Label}"/>
  <WrapPanel x:Name="WaterChips"/>
  <TextBlock Text="Stretch every" Style="{StaticResource Label}"/>
  <WrapPanel x:Name="StretchChips"/>
  <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,24,0,0">
    <Button x:Name="CancelBtn" Content="Cancel" Style="{StaticResource Text}" Margin="0,0,8,0" IsCancel="True"/>
    <Button x:Name="SaveBtn" Content="Save" Style="{StaticResource Filled}" IsDefault="True"/>
  </StackPanel>
</StackPanel>
"@
    $win = New-MaterialWindow -Body $body -Width 560 -Title 'Health reminders'
    $c = @{}
    foreach ($n in 'WaterChips', 'StretchChips', 'CancelBtn', 'SaveBtn') { $c[$n] = $win.FindName($n) }
    $state = @{ saved = $false }

    # Preset chips, plus the current value if it isn't one of them.
    foreach ($row in @(@{ panel = $c.WaterChips; key = 'water_every_min'; opts = @(15, 20, 30, 45, 60) },
                       @{ panel = $c.StretchChips; key = 'stretch_every_min'; opts = @(30, 45, 60, 90, 120) })) {
        $cur = [int][double]$script:Settings[$row.key]
        $opts = @($row.opts)
        if ($cur -gt 0 -and $opts -notcontains $cur) { $opts = @($opts + $cur | Sort-Object) }
        foreach ($m in $opts + 0) {
            $label = if ($m -eq 0) { 'Off' } else { "$m min" }
            $chip = New-Chip $win $label $row.key $m
            $chip.IsChecked = ($m -eq $cur)
            [void]$row.panel.Children.Add($chip)
        }
    }

    $c.SaveBtn.Add_Click({
        $script:Settings.water_every_min = (@($c.WaterChips.Children) | Where-Object { $_.IsChecked } | Select-Object -First 1).Tag
        $script:Settings.stretch_every_min = (@($c.StretchChips.Children) | Where-Object { $_.IsChecked } | Select-Object -First 1).Tag
        Save-Settings
        $state.saved = $true
        $win.Close()
    })
    $c.CancelBtn.Add_Click({ $win.Close() })
    $win.Add_MouseLeftButtonDown({ try { $win.DragMove() } catch { } })
    $win.Add_Loaded({ $win.Activate() })

    if ($PreviewPath) { Save-WindowPreview $win $PreviewPath; return }
    [void]$win.ShowDialog()
    $state.saved
}

# ---------------------------------------------------------------- walking characters

# A realistic person (Mixamo character "AJ", rendered to transparent PNG frames) walks along the top of
# the taskbar. Frames: assets\health\<variant>\<clip>\000.png..., 180x210 px shown at 90x105 DIP, 20 fps.
# Variants: water (carries a bottle), stretch (no prop). Clips: walkL, walkR, hello, act.
$script:HealthAssetDir = Join-Path $Root 'assets\health'
$script:frameCache = @{}
$HealthFps = 20

# All frames of one clip as frozen bitmaps (loaded once), or an empty array if the folder is missing.
function Get-ClipFrames($variant, $clip) {
    $key = "$variant/$clip"
    if (-not $script:frameCache.ContainsKey($key)) {
        $dir = Join-Path (Join-Path $script:HealthAssetDir $variant) $clip
        $frames = @($(if (Test-Path $dir) { Get-ChildItem $dir -Filter '*.png' }) | Sort-Object Name | ForEach-Object {
            $img = New-Object System.Windows.Media.Imaging.BitmapImage
            $img.BeginInit()
            $img.UriSource = New-Object System.Uri $_.FullName
            $img.CacheOption = 'OnLoad'
            $img.EndInit(); $img.Freeze()
            $img
        })
        $script:frameCache[$key] = $frames
    }
    , $script:frameCache[$key]
}

# True when every clip of a variant has frames, so a missing asset folder never breaks the tray.
function Test-WalkerAssets($variant) {
    foreach ($clip in 'walkL', 'walkR', 'hello', 'act') {
        if ((Get-ClipFrames $variant $clip).Count -eq 0) { return $false }
    }
    $true
}

function New-Walker($kind) {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Health reminder" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ResizeMode="NoResize" SizeToContent="WidthAndHeight" Topmost="True" ShowInTaskbar="False" ShowActivated="False"
        UseLayoutRounding="True" FontFamily="Roboto, Segoe UI Variable Text, Segoe UI" TextOptions.TextFormattingMode="Display">
  <Window.Resources>$MaterialStyles</Window.Resources>
  <StackPanel Width="290">
    <Grid x:Name="Bubble" Margin="16,16,16,0" Visibility="Hidden">
      <Border CornerRadius="16" Background="{DynamicResource CardBg}">
        <Border.Effect><DropShadowEffect BlurRadius="16" ShadowDepth="2" Direction="270" Opacity="0.3" Color="Black"/></Border.Effect>
      </Border>
      <StackPanel Margin="16,14,16,12">
        <TextBlock x:Name="TitleText" Style="{StaticResource Title}" FontSize="15"/>
        <TextBlock x:Name="SubText" Style="{StaticResource Supporting}" FontSize="12" Margin="0,2,0,12"/>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="SnoozeBtn" Style="{StaticResource Tonal}" Height="32" Padding="14,0" Margin="0,0,8,0" Content="Snooze 10 min"/>
          <Button x:Name="DoneBtn" Style="{StaticResource Filled}" Height="32" Padding="18,0" Content="Done"/>
        </StackPanel>
      </StackPanel>
    </Grid>
    <Path x:Name="Tail" Data="M0,0 L18,0 L9,11 Z" Fill="{DynamicResource CardBg}" HorizontalAlignment="Center" Visibility="Hidden"/>
    <Grid Width="90" Height="105" HorizontalAlignment="Center">
      <Ellipse Width="54" Height="10" VerticalAlignment="Bottom" RenderTransformOrigin="0.5,0.5">
        <Ellipse.Fill><RadialGradientBrush><GradientStop Color="#70000000" Offset="0"/><GradientStop Color="#00000000" Offset="1"/></RadialGradientBrush></Ellipse.Fill>
        <Ellipse.RenderTransform><ScaleTransform x:Name="ShadowS"/></Ellipse.RenderTransform>
      </Ellipse>
      <Image x:Name="Sprite" Width="90" Height="105" RenderOptions.BitmapScalingMode="HighQuality"/>
    </Grid>
  </StackPanel>
</Window>
"@
    $win = [System.Windows.Markup.XamlReader]::Parse($xaml)
    Set-MaterialTheme $win 'SurfaceContainerHigh'
    $w = @{ Win = $win; Kind = $kind; Dir = 'left'; Shown = '' }
    foreach ($n in 'Bubble', 'Tail', 'TitleText', 'SubText', 'SnoozeBtn', 'DoneBtn', 'ShadowS', 'Sprite') { $w[$n] = $win.FindName($n) }
    $w
}

# Pose at $t seconds into a phase: 'walk' (clip walkL or walkR from $w.Dir), 'hello', 'act'.
# walk and act loop; hello plays once and holds its last frame.
function Set-WalkerPose($w, [string]$mode, [double]$t) {
    $clip = if ($mode -eq 'walk') { if ($w.Dir -eq 'left') { 'walkL' } else { 'walkR' } } else { $mode }
    $frames = Get-ClipFrames $w.Kind $clip
    if ($frames.Count -eq 0) { return }
    $i = [int][math]::Floor($t * $HealthFps)
    if ($clip -eq 'hello') { $i = [math]::Min($i, $frames.Count - 1) } else { $i = $i % $frames.Count }
    $key = "$clip $i"
    if ($w.Shown -ne $key) { $w.Sprite.Source = $frames[$i]; $w.Shown = $key }
}

function Show-WalkerBubble($w, [bool]$show) {
    $v = if ($show) { 'Visible' } else { 'Hidden' }
    $w.Bubble.Visibility = $v; $w.Tail.Visibility = $v
}

# Walk a character in along the taskbar with a reminder bubble. With -PreviewPath, render one pose to a PNG.
function Show-Walker {
    param([string]$Kind, [string]$Title, [string]$Subtitle, [scriptblock]$OnDone, [scriptblock]$OnSnooze,
          [string]$PreviewPath, [switch]$Walking)
    # One at a time, and never without frames (a missing assets folder just means no character).
    if (-not $PreviewPath -and ($script:walker -or -not (Test-WalkerAssets $Kind))) { return }
    $w = New-Walker $Kind
    $w.TitleText.Text = $Title; $w.SubText.Text = $Subtitle
    if ($PreviewPath) {
        if ($Walking) { Set-WalkerPose $w 'walk' 0.2 } else { Set-WalkerPose $w 'act' 1.2; Show-WalkerBubble $w $true }
        Save-WindowPreview $w.Win $PreviewPath
        return
    }
    $script:walker = $w
    $w.OnDone = $OnDone; $w.OnSnooze = $OnSnooze
    $win = $w.Win
    $win.WindowStartupLocation = 'Manual'; $win.Left = -20000; $win.Top = -20000
    $win.Show(); $win.UpdateLayout()
    # X is the character's centre (DIPs). It enters just off the right edge and stops at 3/4 of the screen.
    $area = [System.Windows.SystemParameters]::WorkArea
    $w.Half = $win.ActualWidth / 2
    $w.X = $area.Right + 40; $w.EndX = $area.Right + 40
    $w.StopX = [math]::Min($area.Left + $area.Width * 0.75, $area.Right - $w.Half)
    $win.Top = $area.Bottom - $win.ActualHeight
    $win.Left = $w.X - $w.Half
    $w.Dir = 'left'
    $w.Phase = 'in'; $w.PhaseAt = 0.0; $w.Last = 0.0
    $w.Clock = [System.Diagnostics.Stopwatch]::StartNew()
    $w.DoneBtn.Add_Click({ $s = $script:walker; if ($s) { & $s.OnDone; Set-WalkerPhase 'out' } })
    $w.SnoozeBtn.Add_Click({ $s = $script:walker; if ($s) { & $s.OnSnooze; Set-WalkerPhase 'out' } })
    $win.Add_Closed({ if ($script:walker) { $script:walker.Timer.Stop() }; $script:walker = $null })
    $w.Timer = New-Object System.Windows.Threading.DispatcherTimer
    $w.Timer.Interval = [timespan]::FromMilliseconds(16)
    $w.Timer.Add_Tick({ Step-Walker })
    $w.Timer.Start()
}

function Set-WalkerPhase($phase) {
    $w = $script:walker
    if (-not $w -or $w.Phase -eq $phase) { return }
    $w.Phase = $phase; $w.PhaseAt = $w.Clock.Elapsed.TotalSeconds
    Show-WalkerBubble $w ($phase -eq 'act')
    if ($phase -eq 'out') { $w.Dir = 'right'; Set-WalkerPose $w 'walk' 0 }
}

# One animation frame: walk in (120 DIP/s), wave hello, act with the bubble for up to 60 s,
# then (on Done, Snooze or no click) walk back off to the right.
function Step-Walker {
    $w = $script:walker
    if (-not $w) { return }
    $now = $w.Clock.Elapsed.TotalSeconds
    $dt = $now - $w.Last; $w.Last = $now
    $t = $now - $w.PhaseAt
    switch ($w.Phase) {
        'in' {
            $w.X = [math]::Max($w.StopX, $w.X - 120 * $dt)
            Set-WalkerPose $w 'walk' $t
            if ($w.X -le $w.StopX) { Set-WalkerPhase 'hello' }
        }
        'hello' {
            Set-WalkerPose $w 'hello' $t
            if ($t -ge 1.8) { Set-WalkerPhase 'act' }
        }
        'act' {
            Set-WalkerPose $w 'act' $t
            if ($t -ge 60) { & $w.OnSnooze; Set-WalkerPhase 'out' }   # ignored: ask again in 10 min
        }
        'out' {
            $w.X += 120 * $dt
            Set-WalkerPose $w 'walk' $t
            if ($w.X -ge $w.EndX) { $w.Win.Close(); return }
        }
    }
    $w.Win.Left = $w.X - $w.Half
}

# ---------------------------------------------------------------- timers

function Set-HealthDue($kind, $minutes) {
    $due = if ($minutes -gt 0) { (Get-Date).AddMinutes($minutes) } else { [datetime]::MaxValue }
    if ($kind -eq 'water') { $script:waterDue = $due } else { $script:stretchDue = $due }
}

function Reset-HealthClocks {
    Set-HealthDue water ([double]$script:Settings.water_every_min)
    Set-HealthDue stretch ([double]$script:Settings.stretch_every_min)
}

$WaterText   = @('Drink some water', 'min since your last sip')
$StretchText = @('Stand up and stretch', 'Arms up, then out wide. Hold 10 s')
Reset-HealthClocks

# Send out the water or stretch character (also from the menu). A stretch with water also due covers both.
function Show-HealthReminder($kind) {
    if ($kind -eq 'stretch') {
        if ((Get-Date) -ge $script:waterDue) {
            Show-Walker stretch 'Time to move' 'Stretch, and grab some water' -OnDone { Reset-HealthClocks } `
                -OnSnooze { Set-HealthDue stretch 10; Set-HealthDue water 10 }
        } else {
            Show-Walker stretch $StretchText[0] $StretchText[1] `
                -OnDone { Set-HealthDue stretch ([double]$script:Settings.stretch_every_min) } -OnSnooze { Set-HealthDue stretch 10 }
        }
    } else {
        Show-Walker water $WaterText[0] "$($script:Settings.water_every_min) $($WaterText[1])" `
            -OnDone { Set-HealthDue water ([double]$script:Settings.water_every_min) } -OnSnooze { Set-HealthDue water 10 }
    }
}

# Menu label: "Water break in 12 min", "Water break due now", or "... off".
function Get-HealthLabel($name, $due) {
    if ($due -eq [datetime]::MaxValue) { return "$name off" }
    $m = [math]::Ceiling(($due - (Get-Date)).TotalMinutes)
    if ($m -le 0) { "$name due now" } else { "$name in $m min" }
}

# 5 minutes away restarts both clocks; a reminder comes only while you're actually at the PC.
function Test-Reminders {
    $idle = Get-IdleSeconds
    if ($idle -ge 300) { Reset-HealthClocks; return }
    if (-not $script:Settings.on -or $idle -ge 120 -or $script:busy -or $script:walker) { return }
    $now = Get-Date
    if ($now -ge $script:stretchDue) { Show-HealthReminder stretch }
    elseif ($now -ge $script:waterDue) { Show-HealthReminder water }
}

function Update-Tip {
    $notify.Text = if ($script:Settings.on) {
        "Health reminders $([char]0x00B7) water $(Get-HealthLabel '' $script:waterDue)".Replace('  ', ' ')
    } else { 'Health reminders (stopped)' }
    if ($notify.Text.Length -gt 63) { $notify.Text = $notify.Text.Substring(0, 63) }
}

# ---------------------------------------------------------------- tray icon + main loop

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = New-TrayIcon
$notify.Add_MouseUp({ Show-TrayMenu })

if ($Preview) {
    if (-not (Test-Path $Preview)) { New-Item -ItemType Directory -Path $Preview | Out-Null }
    Save-WindowPreview (New-TrayMenu) (Join-Path $Preview 'menu.png')
    Show-HealthSettings (Join-Path $Preview 'settings.png')
    Show-Walker water $WaterText[0] "30 $($WaterText[1])" -PreviewPath (Join-Path $Preview 'water-bubble.png')
    Show-Walker stretch $StretchText[0] $StretchText[1] -PreviewPath (Join-Path $Preview 'stretch-bubble.png')
    Show-Walker stretch $StretchText[0] $StretchText[1] -PreviewPath (Join-Path $Preview 'stretch-walking.png') -Walking
    $notify.Dispose()
    exit
}

$notify.Visible = $true
Update-Tip

# Every 2 s: close a menu that lost focus. Every 30 s: check the reminders.
$script:lastSlowTick = [datetime]::MinValue
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [timespan]::FromSeconds(2)
$timer.Add_Tick({
    if ($script:menuWin -and -not $script:menuWin.IsActive -and -not $script:menuWin.IsMouseOver) { Close-Menu }
    if (((Get-Date) - $script:lastSlowTick).TotalSeconds -ge 30) {
        $script:lastSlowTick = Get-Date
        Test-Reminders; Update-Tip
    }
})
$timer.Start()

if ($Test) {
    $script:tests = [System.Collections.Queue]::new()
    $script:tests.Enqueue('water'); $script:tests.Enqueue('stretch')
    $testTimer = New-Object System.Windows.Threading.DispatcherTimer
    $testTimer.Interval = [timespan]::FromSeconds(2)
    $testTimer.Add_Tick({
        if ($script:tests.Count -eq 0) { $testTimer.Stop(); return }
        if ($script:walker) { return }   # let the character finish before the next one
        $k = $script:tests.Dequeue()
        $txt = if ($k -eq 'water') { @($WaterText[0], "TEST - 30 $($WaterText[1])") } else { @($StretchText[0], "TEST - $($StretchText[1])") }
        Show-Walker $k $txt[0] $txt[1] -OnDone { } -OnSnooze { }
    })
    $testTimer.Start()
}

[System.Windows.Threading.Dispatcher]::Run()
$mutex.ReleaseMutex()
