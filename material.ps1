# Material 3 look for the WPF windows (copied from Work Tracker). Dot-sourced by HealthReminders.ps1.
# Colours are Material 3 tonal roles generated from the tracker's blue; light/dark follows Windows.
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$MaterialLight = @{
    Primary = '#2B5EA7'; OnPrimary = '#FFFFFF'; PrimaryContainer = '#D6E3FF'; OnPrimaryContainer = '#001B3D'
    SecondaryContainer = '#DAE2F9'; OnSecondaryContainer = '#131C2B'
    Surface = '#F9F9FF'; SurfaceContainer = '#EDEDF4'; SurfaceContainerHigh = '#E7E8EE'
    OnSurface = '#1A1C20'; OnSurfaceVariant = '#44474E'; Outline = '#74777F'; OutlineVariant = '#C4C6D0'
    Error = '#BA1A1A'
}
$MaterialDark = @{
    Primary = '#A9C7FF'; OnPrimary = '#003062'; PrimaryContainer = '#0B4689'; OnPrimaryContainer = '#D6E3FF'
    SecondaryContainer = '#3E4759'; OnSecondaryContainer = '#DAE2F9'
    Surface = '#111318'; SurfaceContainer = '#1E2025'; SurfaceContainerHigh = '#282A2F'
    OnSurface = '#E2E2E9'; OnSurfaceVariant = '#C4C6D0'; Outline = '#8E9099'; OutlineVariant = '#44474E'
    Error = '#FFB4AB'
}

$IconFont = 'Segoe Fluent Icons, Segoe MDL2 Assets'

function Test-DarkTheme {
    try {
        (Get-ItemPropertyValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme') -eq 0
    } catch { $false }
}

function New-Brush($hex) {
    $b = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($hex))
    $b.Freeze(); $b
}

# Put the colour roles into a window's resources. XAML refers to them with DynamicResource,
# so calling this again (e.g. after Windows switches theme) recolours an open window.
function Set-MaterialTheme($win, $cardRole = 'SurfaceContainerHigh') {
    $t = if (Test-DarkTheme) { $MaterialDark } else { $MaterialLight }
    # .BaseObject: the resource dictionary is untyped, so it would otherwise store PowerShell's wrapper object.
    foreach ($k in $t.Keys) { $win.Resources[$k] = (New-Brush $t[$k]).PSObject.BaseObject }
    $win.Resources['CardBg'] = (New-Brush $t[$cardRole]).PSObject.BaseObject
    $win.Tag = if (Test-DarkTheme) { 'dark' } else { 'light' }
}

$MaterialStyles = @"
<Style x:Key="Headline" TargetType="TextBlock">
  <Setter Property="FontSize" Value="24"/><Setter Property="Foreground" Value="{DynamicResource OnSurface}"/>
</Style>
<Style x:Key="Title" TargetType="TextBlock">
  <Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/>
  <Setter Property="Foreground" Value="{DynamicResource OnSurface}"/>
</Style>
<Style x:Key="Supporting" TargetType="TextBlock">
  <Setter Property="FontSize" Value="14"/><Setter Property="Foreground" Value="{DynamicResource OnSurfaceVariant}"/>
  <Setter Property="TextWrapping" Value="Wrap"/>
</Style>
<Style x:Key="Label" TargetType="TextBlock">
  <Setter Property="FontSize" Value="12"/><Setter Property="FontWeight" Value="SemiBold"/>
  <Setter Property="Foreground" Value="{DynamicResource OnSurfaceVariant}"/><Setter Property="Margin" Value="0,16,0,8"/>
</Style>
<Style x:Key="FieldLabel" TargetType="TextBlock">
  <Setter Property="FontSize" Value="12"/><Setter Property="Foreground" Value="{DynamicResource OnSurfaceVariant}"/>
  <Setter Property="Background" Value="{DynamicResource CardBg}"/><Setter Property="Padding" Value="4,0"/>
  <Setter Property="Margin" Value="8,-8,0,0"/><Setter Property="HorizontalAlignment" Value="Left"/>
  <Setter Property="VerticalAlignment" Value="Top"/><Setter Property="IsHitTestVisible" Value="False"/>
</Style>
<Style x:Key="Error" TargetType="TextBlock">
  <Setter Property="FontSize" Value="12"/><Setter Property="Foreground" Value="{DynamicResource Error}"/>
</Style>

<Style x:Key="Field" TargetType="TextBox">
  <Setter Property="FontSize" Value="15"/><Setter Property="Height" Value="48"/>
  <Setter Property="Foreground" Value="{DynamicResource OnSurface}"/><Setter Property="CaretBrush" Value="{DynamicResource OnSurface}"/>
  <Setter Property="SelectionBrush" Value="{DynamicResource Primary}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="TextBox">
    <Border x:Name="bd" CornerRadius="4" BorderThickness="1" BorderBrush="{DynamicResource Outline}" Background="Transparent">
      <ScrollViewer x:Name="PART_ContentHost" VerticalAlignment="Center" Margin="12,0"/>
    </Border>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource OnSurface}"/></Trigger>
      <Trigger Property="IsKeyboardFocused" Value="True">
        <Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource Primary}"/>
        <Setter TargetName="bd" Property="BorderThickness" Value="2"/>
      </Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="Chip" TargetType="ToggleButton">
  <Setter Property="Foreground" Value="{DynamicResource OnSurfaceVariant}"/><Setter Property="FontSize" Value="14"/>
  <Setter Property="Margin" Value="0,0,8,8"/><Setter Property="Cursor" Value="Hand"/>
  <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ToggleButton">
    <Grid Height="32">
      <Border x:Name="bd" CornerRadius="8" BorderThickness="1" BorderBrush="{DynamicResource Outline}" Background="Transparent"/>
      <Border x:Name="layer" CornerRadius="8" Background="{DynamicResource OnSurface}" Opacity="0"/>
      <StackPanel Orientation="Horizontal" Margin="12,0,16,0" VerticalAlignment="Center">
        <TextBlock x:Name="check" Text="&#xE73E;" FontFamily="$IconFont" FontSize="13" Margin="0,1,8,0"
                   VerticalAlignment="Center" Visibility="Collapsed"/>
        <ContentPresenter VerticalAlignment="Center"/>
      </StackPanel>
    </Grid>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.08"/></Trigger>
      <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.12"/></Trigger>
      <Trigger Property="IsChecked" Value="True">
        <Setter TargetName="bd" Property="Background" Value="{DynamicResource SecondaryContainer}"/>
        <Setter TargetName="bd" Property="BorderBrush" Value="Transparent"/>
        <Setter TargetName="check" Property="Visibility" Value="Visible"/>
        <Setter Property="Foreground" Value="{DynamicResource OnSecondaryContainer}"/>
      </Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="BaseButton" TargetType="Button">
  <Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/>
  <Setter Property="Height" Value="40"/><Setter Property="Padding" Value="24,0"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Grid>
      <Border x:Name="bd" CornerRadius="20" Background="{TemplateBinding Background}"/>
      <Border x:Name="layer" CornerRadius="20" Background="{TemplateBinding Foreground}" Opacity="0"/>
      <ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Grid>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.08"/></Trigger>
      <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.12"/></Trigger>
      <Trigger Property="IsPressed" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.12"/></Trigger>
      <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.38"/></Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>
<Style x:Key="Filled" TargetType="Button" BasedOn="{StaticResource BaseButton}">
  <Setter Property="Background" Value="{DynamicResource Primary}"/><Setter Property="Foreground" Value="{DynamicResource OnPrimary}"/>
</Style>
<Style x:Key="Tonal" TargetType="Button" BasedOn="{StaticResource BaseButton}">
  <Setter Property="Background" Value="{DynamicResource SecondaryContainer}"/><Setter Property="Foreground" Value="{DynamicResource OnSecondaryContainer}"/>
</Style>
<Style x:Key="Text" TargetType="Button" BasedOn="{StaticResource BaseButton}">
  <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{DynamicResource Primary}"/>
  <Setter Property="Padding" Value="12,0"/>
</Style>
<Style x:Key="Icon" TargetType="Button" BasedOn="{StaticResource BaseButton}">
  <Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{DynamicResource OnSurfaceVariant}"/>
  <Setter Property="Width" Value="40"/><Setter Property="Padding" Value="0"/>
  <Setter Property="FontFamily" Value="$IconFont"/><Setter Property="FontWeight" Value="Normal"/><Setter Property="FontSize" Value="16"/>
</Style>

<Style x:Key="MenuItem" TargetType="Button">
  <Setter Property="Height" Value="44"/><Setter Property="FontSize" Value="14"/>
  <Setter Property="Foreground" Value="{DynamicResource OnSurface}"/><Setter Property="Background" Value="Transparent"/>
  <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Grid Background="Transparent">
      <Border x:Name="layer" Background="{DynamicResource OnSurface}" Opacity="0"/>
      <ContentPresenter Margin="12,0" VerticalAlignment="Center" HorizontalAlignment="Stretch"/>
    </Grid>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.08"/></Trigger>
      <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.12"/></Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="SelectItem" TargetType="ComboBoxItem">
  <Setter Property="Foreground" Value="{DynamicResource OnSurface}"/><Setter Property="FontSize" Value="14"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ComboBoxItem">
    <Grid Height="40" Background="Transparent">
      <Border x:Name="layer" Background="{DynamicResource OnSurface}" Opacity="0"/>
      <ContentPresenter Margin="12,0" VerticalAlignment="Center"/>
    </Grid>
    <ControlTemplate.Triggers>
      <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="layer" Property="Opacity" Value="0.08"/></Trigger>
      <Trigger Property="IsSelected" Value="True">
        <Setter TargetName="layer" Property="Background" Value="{DynamicResource SecondaryContainer}"/>
        <Setter TargetName="layer" Property="Opacity" Value="1"/>
        <Setter Property="Foreground" Value="{DynamicResource OnSecondaryContainer}"/>
      </Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>
<Style x:Key="Select" TargetType="ComboBox">
  <Setter Property="FontSize" Value="14"/><Setter Property="Height" Value="40"/>
  <Setter Property="Foreground" Value="{DynamicResource OnSurface}"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="ItemContainerStyle" Value="{StaticResource SelectItem}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ComboBox">
    <Grid>
      <Border x:Name="bd" CornerRadius="4" BorderThickness="1" BorderBrush="{DynamicResource Outline}" Background="Transparent"/>
      <ToggleButton Focusable="False" ClickMode="Press"
                    IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
        <ToggleButton.Template><ControlTemplate TargetType="ToggleButton"><Border Background="Transparent"/></ControlTemplate></ToggleButton.Template>
      </ToggleButton>
      <ContentPresenter Content="{TemplateBinding SelectionBoxItem}" Margin="12,0,36,0" VerticalAlignment="Center" IsHitTestVisible="False"/>
      <TextBlock Text="&#xE70D;" FontFamily="$IconFont" FontSize="12" Foreground="{DynamicResource OnSurfaceVariant}"
                 HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,12,0" IsHitTestVisible="False"/>
      <Popup x:Name="PART_Popup" Placement="Bottom" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade"
             IsOpen="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
        <Border Margin="0,4,10,10" Padding="0,8" CornerRadius="4" Background="{DynamicResource SurfaceContainer}" MaxHeight="300"
                MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}">
          <Border.Effect><DropShadowEffect BlurRadius="10" ShadowDepth="2" Direction="270" Opacity="0.3" Color="Black"/></Border.Effect>
          <ScrollViewer VerticalScrollBarVisibility="Auto"><ItemsPresenter/></ScrollViewer>
        </Border>
      </Popup>
    </Grid>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource OnSurface}"/></Trigger>
      <Trigger Property="IsKeyboardFocusWithin" Value="True">
        <Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource Primary}"/>
        <Setter TargetName="bd" Property="BorderThickness" Value="2"/>
      </Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style TargetType="ScrollBar">
  <Setter Property="Width" Value="8"/><Setter Property="MinWidth" Value="8"/><Setter Property="Margin" Value="4,0,0,0"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
    <Track x:Name="PART_Track" IsDirectionReversed="True">
      <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
        <Border CornerRadius="4" Background="{DynamicResource OutlineVariant}"/>
      </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
    </Track>
  </ControlTemplate></Setter.Value></Setter>
  <Style.Triggers>
    <Trigger Property="Orientation" Value="Horizontal">
      <Setter Property="Width" Value="Auto"/><Setter Property="MinWidth" Value="0"/>
      <Setter Property="Height" Value="8"/><Setter Property="Margin" Value="0,4,0,0"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
        <Track x:Name="PART_Track">
          <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
            <Border CornerRadius="4" Background="{DynamicResource OutlineVariant}"/>
          </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
        </Track>
      </ControlTemplate></Setter.Value></Setter>
    </Trigger>
  </Style.Triggers>
</Style>
"@

# A borderless, shadowed Material surface. $body is XAML placed inside the card.
function New-MaterialWindow {
    param([string]$Body, [int]$Radius = 28, [string]$Padding = '24', [string]$Width = 'Auto',
          [string]$CardRole = 'SurfaceContainerHigh', [bool]$InTaskbar = $true, [string]$Title = 'Health reminders')
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$Title" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ResizeMode="NoResize" SizeToContent="WidthAndHeight" Topmost="True" ShowInTaskbar="$InTaskbar"
        WindowStartupLocation="CenterScreen" UseLayoutRounding="True"
        FontFamily="Roboto, Segoe UI Variable Text, Segoe UI" TextOptions.TextFormattingMode="Display">
  <Window.Resources>$MaterialStyles</Window.Resources>
  <Grid Margin="20">
    <Border CornerRadius="$Radius" Background="{DynamicResource CardBg}">
      <Border.Effect><DropShadowEffect BlurRadius="20" ShadowDepth="3" Direction="270" Opacity="0.3" Color="Black"/></Border.Effect>
    </Border>
    <Border x:Name="Card" CornerRadius="$Radius" Padding="$Padding" Width="$Width" Background="Transparent">
$Body
    </Border>
  </Grid>
</Window>
"@
    $win = [System.Windows.Markup.XamlReader]::Parse($xaml)
    Set-MaterialTheme $win $CardRole
    $win
}

function Get-Control($win, $name) { $win.FindName($name) }

# A filter chip; $color adds a project-coloured dot in front of the text.
# One chip per $group can be on; with -Multi each chip toggles on its own (a CheckBox).
function New-Chip($win, $text, $group, $tag, $color, [switch]$Multi) {
    if ($Multi) { $chip = New-Object System.Windows.Controls.CheckBox }
    else { $chip = New-Object System.Windows.Controls.RadioButton; $chip.GroupName = $group }
    $chip.Style = $win.FindResource('Chip')
    $chip.Tag = if ($null -ne $tag) { $tag } else { $text }
    if ($color) {
        $sp = New-Object System.Windows.Controls.StackPanel
        $sp.Orientation = 'Horizontal'
        $dot = New-Object System.Windows.Shapes.Ellipse
        $dot.Width = 10; $dot.Height = 10; $dot.Margin = '0,0,8,0'; $dot.Fill = New-Brush $color
        $dot.VerticalAlignment = 'Center'
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = $text; $tb.VerticalAlignment = 'Center'
        [void]$sp.Children.Add($dot); [void]$sp.Children.Add($tb)
        $chip.Content = $sp
    } else {
        $chip.Content = $text
    }
    $chip
}

# Render a window to a PNG without showing it on screen (used to check the look headlessly).
function Save-WindowPreview($win, $path) {
    $win.WindowStartupLocation = 'Manual'; $win.Left = -20000; $win.Top = -20000
    $win.ShowActivated = $false
    $win.Show(); $win.UpdateLayout()
    $root = $win.Content
    $bmp = New-Object System.Windows.Media.Imaging.RenderTargetBitmap ([int]$root.ActualWidth + 40), ([int]$root.ActualHeight + 40), 96, 96, ([System.Windows.Media.PixelFormats]::Pbgra32)
    $bmp.Render($root)
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
    $fs = [IO.File]::Create($path); $enc.Save($fs); $fs.Close()
    $win.Close()
}
