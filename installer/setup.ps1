# SPDX-License-Identifier: GPL-3.0-only
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[System.Windows.Media.RenderOptions]::ProcessRenderMode = 'SoftwareOnly'

[xml]$markup = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Title="Prism GitHub Mods" Width="860" Height="540" MinWidth="650" MinHeight="510"
 WindowStartupLocation="CenterScreen" Background="#10121B"
 Foreground="#F4F3FF" FontFamily="Segoe UI">
 <Window.Resources>
  <Style x:Key="Pill" TargetType="Button">
   <Setter Property="Background" Value="#292941"/>
   <Setter Property="Foreground" Value="#F4F3FF"/>
   <Setter Property="Padding" Value="16,8"/>
   <Setter Property="Margin" Value="0,0,8,0"/>
   <Setter Property="FontWeight" Value="SemiBold"/>
   <Setter Property="Cursor" Value="Hand"/>
   <Setter Property="Template">
    <Setter.Value>
     <ControlTemplate TargetType="Button">
      <Border x:Name="Shape" Background="{TemplateBinding Background}" CornerRadius="12"
       BorderBrush="#4A476B" BorderThickness="1" Padding="{TemplateBinding Padding}">
       <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Border>
      <ControlTemplate.Triggers>
       <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Shape" Property="BorderBrush" Value="#C5AFFF"/></Trigger>
       <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Shape" Property="BorderBrush" Value="#FFFFFF"/></Trigger>
       <Trigger Property="IsPressed" Value="True"><Setter TargetName="Shape" Property="Opacity" Value="0.68"/></Trigger>
       <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Shape" Property="Opacity" Value="0.38"/></Trigger>
      </ControlTemplate.Triggers>
     </ControlTemplate>
    </Setter.Value>
   </Setter>
  </Style>
  <Style TargetType="TextBox">
   <Setter Property="Background" Value="#1D2031"/>
   <Setter Property="Foreground" Value="#F4F3FF"/>
   <Setter Property="BorderBrush" Value="#444663"/>
   <Setter Property="Padding" Value="8,5"/>
   <Setter Property="VerticalContentAlignment" Value="Center"/>
  </Style>
 </Window.Resources>
 <Grid Margin="20">
  <Grid.ColumnDefinitions><ColumnDefinition Width="1.04*"/><ColumnDefinition Width="1.65*"/></Grid.ColumnDefinitions>
  <Border CornerRadius="23" Margin="0,0,16,0" ClipToBounds="True">
   <Border.Background>
    <LinearGradientBrush StartPoint="0,0" EndPoint="0.95,1">
     <GradientStop Color="#462D94" Offset="0"/><GradientStop Color="#252C68" Offset="0.6"/><GradientStop Color="#1E2154" Offset="1"/>
    </LinearGradientBrush>
   </Border.Background>
   <Grid ClipToBounds="True">
    <Ellipse Width="243" Height="243" HorizontalAlignment="Center" VerticalAlignment="Center" Stroke="#89C8FF" StrokeThickness="1" Opacity=".14"/>
    <Ellipse Width="194" Height="194" HorizontalAlignment="Center" VerticalAlignment="Center" Stroke="#DAD0FF" StrokeThickness="1" Opacity=".22"/>
    <Ellipse x:Name="Bubble1" Width="60" Height="60" Fill="#8361FF" Opacity=".45" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="30,40,0,0"><Ellipse.RenderTransform><TranslateTransform/></Ellipse.RenderTransform></Ellipse>
    <Ellipse x:Name="Bubble2" Width="34" Height="34" Fill="#5DD9FA" Opacity=".45" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,29,90"><Ellipse.RenderTransform><TranslateTransform/></Ellipse.RenderTransform></Ellipse>
    <Ellipse x:Name="Bubble3" Width="20" Height="20" Fill="#F0B3FF" Opacity=".49" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,120,63,0"><Ellipse.RenderTransform><TranslateTransform/></Ellipse.RenderTransform></Ellipse>
    <Viewbox Width="136" Height="142" HorizontalAlignment="Center" VerticalAlignment="Center">
     <Canvas Width="160" Height="160">
      <Path Data="M 80,4 L 150,44 L 150,117 L 80,157 L 10,117 L 10,44 Z" Fill="#28255F" Stroke="#BDB0FC" StrokeThickness="2"/>
      <Path Data="M 80,27 L 128,107 L 32,107 Z" Fill="#8867FF" Stroke="#E0D3FF" StrokeThickness="2"/>
      <Path Data="M 80,27 L 80,87 L 32,107 Z" Fill="#74C9F5"/>
      <Path Data="M 80,87 L 128,107 L 32,107 Z" Fill="#B18AF4"/>
      <Path x:Name="Star" Data="M 117,5 L 123,23 L 142,29 L 123,35 L 117,54 L 111,35 L 92,29 L 111,23 Z" Fill="#FFF3C0" Opacity=".23"/>
     </Canvas>
    </Viewbox>
    <StackPanel Margin="19,17,17,0" VerticalAlignment="Top">
     <TextBlock Text="DETEMKUR STUDIOS" FontSize="12" FontWeight="Bold" Foreground="#E1D5FF"/>
     <TextBlock Text="Prism&#x0a;GitHub Mods" FontSize="29" FontWeight="Bold" Margin="0,12,0,0"/>
    </StackPanel>
    <TextBlock Text="Каталог GitHub Releases" Margin="19,0,15,19" VerticalAlignment="Bottom" Foreground="#E1D5FF"/>
   </Grid>
  </Border>
  <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
   <StackPanel Margin="5,5,7,0">
    <TextBlock Text="Установка патча" FontSize="29" FontWeight="Bold"/>
    <TextBlock Text="Добавляет GitHub в окно скачивания модов Prism Launcher." TextWrapping="Wrap" Foreground="#C4C3DA" Margin="0,5,0,16"/>
    <TextBlock Text="Файл Prism Launcher" FontWeight="SemiBold" Margin="0,0,0,6"/>
    <DockPanel LastChildFill="True">
     <Button x:Name="Browse" Content="Обзор" Style="{StaticResource Pill}" DockPanel.Dock="Right" Margin="8,0,0,0"/>
     <TextBox x:Name="Prism" MinHeight="35"/>
    </DockPanel>
    <TextBlock Text="Папка данных Prism" FontWeight="SemiBold" Margin="0,13,0,6"/>
    <DockPanel LastChildFill="True">
     <Button x:Name="BrowseData" Content="Обзор" Style="{StaticResource Pill}" DockPanel.Dock="Right" Margin="8,0,0,0"/>
     <TextBox x:Name="Data" MinHeight="35"/>
    </DockPanel>
    <TextBlock Text="Патч ставится отдельно. Ярлык откроет его с твоими сборками." Foreground="#BCBDDA" TextWrapping="Wrap" Margin="0,7,0,15"/>
    <WrapPanel>
     <Button x:Name="Music" Content="Выбрать музыку" Style="{StaticResource Pill}"/>
     <Button x:Name="Pause" Content="Пауза" Style="{StaticResource Pill}" IsEnabled="False"/>
     <Button x:Name="Stop" Content="Стоп" Style="{StaticResource Pill}" IsEnabled="False"/>
    </WrapPanel>
    <DockPanel Margin="0,7,0,0">
     <TextBox x:Name="Cue" Width="60" Text="12" DockPanel.Dock="Left" Margin="0,0,8,0"/>
     <TextBlock Text="Вспышка звезды, секунда трека" TextWrapping="Wrap" VerticalAlignment="Center" Foreground="#C4C3DA" FontSize="12"/>
    </DockPanel>
    <CheckBox x:Name="Motion" IsChecked="True" Content="Анимация пузырей и звезды" Margin="0,11,0,0" Foreground="#DCDDF1"/>
    <TextBlock x:Name="Status" TextWrapping="Wrap" Text="Укажи путь к prismlauncher.exe." Foreground="#DDD5FF" Margin="0,12,0,9"/>
    <WrapPanel>
     <Button x:Name="Install" Content="Установить патч  →" Style="{StaticResource Pill}" Background="#7751E9"/>
     <Button x:Name="Open" Content="Открыть Prism" Style="{StaticResource Pill}" IsEnabled="False"/>
    </WrapPanel>
   </StackPanel>
  </ScrollViewer>
 </Grid>
</Window>
'@
$reader = New-Object System.Xml.XmlNodeReader $markup
$window = [Windows.Markup.XamlReader]::Load($reader)
$elements = @{}
foreach ($name in 'Browse','BrowseData','Prism','Data','Music','Pause','Stop','Cue','Motion','Status','Install','Open','Bubble1','Bubble2','Bubble3','Star') {
    $elements[$name] = $window.FindName($name)
}
$e = $elements
$clock = [Diagnostics.Stopwatch]::StartNew()
$audio = New-Object Windows.Media.MediaPlayer
$audio.Volume = 0.45
$script:audioState = 'none'
$script:installed = $null
$script:worker = $null

function Set-DataGuess {
    $file = $e.Prism.Text.Trim()
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return }
    $folder = Split-Path -LiteralPath $file
    $userData = Join-Path $folder 'UserData'
    if (Test-Path -LiteralPath $userData -PathType Container) { $e.Data.Text = $userData }
    elseif (Test-Path -LiteralPath (Join-Path $folder 'portable.txt') -PathType Leaf) { $e.Data.Text = $folder }
    elseif ($env:PRISMLAUNCHER_DATA_DIR) { $e.Data.Text = $env:PRISMLAUNCHER_DATA_DIR }
    else { $e.Data.Text = Join-Path $env:APPDATA 'PrismLauncher' }
}

$e.Data.Text = Join-Path $env:APPDATA 'PrismLauncher'
foreach ($base in $env:ProgramFiles,(Join-Path $env:LOCALAPPDATA 'Programs'),$env:LOCALAPPDATA) {
    $candidate = Join-Path $base 'PrismLauncher\prismlauncher.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $e.Prism.Text = $candidate
        Set-DataGuess
        break
    }
}
$e.Prism.Add_TextChanged({ Set-DataGuess })
$e.Browse.Add_Click({
    $picker = New-Object Microsoft.Win32.OpenFileDialog
    $picker.Title = 'Выбери исполняемый файл Prism Launcher'
    $picker.Filter = 'Prism Launcher|prismlauncher.exe'
    if ($picker.ShowDialog()) { $e.Prism.Text = $picker.FileName }
})
$e.BrowseData.Add_Click({
    Add-Type -AssemblyName System.Windows.Forms
    $picker = New-Object System.Windows.Forms.FolderBrowserDialog
    $picker.Description = 'Папка с prismlauncher.cfg и сборками Prism'
    $picker.ShowNewFolderButton = $false
    try {
        if ($picker.ShowDialog() -eq 'OK') { $e.Data.Text = $picker.SelectedPath }
    } finally { $picker.Dispose() }
})
$e.Music.Add_Click({
    $picker = New-Object Microsoft.Win32.OpenFileDialog
    $picker.Filter = 'Аудиофайлы|*.mp3;*.wav;*.wma;*.m4a|Все файлы|*.*'
    if (-not $picker.ShowDialog()) { return }
    $audio.Close()
    $audio.Open([Uri]$picker.FileName)
    $audio.Play()
    $script:audioState = 'playing'
    $e.Pause.Content = 'Пауза'
    $e.Pause.IsEnabled = $true
    $e.Stop.IsEnabled = $true
    $e.Music.Content = 'Сменить трек'
})
$e.Pause.Add_Click({
    if ($script:audioState -eq 'playing') {
        $audio.Pause()
        $script:audioState = 'paused'
        $e.Pause.Content = 'Продолжить'
    } else {
        $audio.Play()
        $script:audioState = 'playing'
        $e.Pause.Content = 'Пауза'
    }
})
$e.Stop.Add_Click({
    $audio.Stop()
    $script:audioState = 'stopped'
    $e.Pause.Content = 'Продолжить'
    $e.Star.Opacity = .23
})
$audio.Add_MediaEnded({
    $audio.Stop()
    $script:audioState = 'stopped'
    $e.Pause.Content = 'Продолжить'
})
$audio.Add_MediaFailed({
    $script:audioState = 'none'
    $e.Pause.IsEnabled = $false
    $e.Stop.IsEnabled = $false
    $e.Status.Text = 'Windows не смогла открыть этот звук. Попробуй MP3 или WAV.'
})

function Set-Working($state) {
    foreach ($name in 'Browse','BrowseData','Prism','Data','Install') { $e[$name].IsEnabled = -not $state }
}
$e.Install.Add_Click({
    if (-not (Test-Path -LiteralPath $e.Prism.Text.Trim() -PathType Leaf)) {
        $e.Status.Text = 'Укажи существующий файл prismlauncher.exe.'
        return
    }
    if (-not (Test-Path -LiteralPath $e.Data.Text.Trim() -PathType Container)) {
        $e.Status.Text = 'Укажи папку данных Prism, обычно там есть prismlauncher.cfg и instances.'
        return
    }
    $folder = $env:PRISM_SETUP_TEMP
    $request = @{ Original = $e.Prism.Text.Trim(); Data = $e.Data.Text.Trim() }
    Remove-Item -LiteralPath (Join-Path $folder 'result.json') -ErrorAction SilentlyContinue
    [IO.File]::WriteAllText((Join-Path $folder 'request.json'), ($request | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))
    $e.Status.Text = 'Готовлю установку…'
    Set-Working $true
    try {
        $script:worker = Start-Process -FilePath $env:PRISM_SETUP_EXE -ArgumentList ('--install "' + $folder + '"') -PassThru
    } catch {
        $e.Status.Text = $_.Exception.Message
        Set-Working $false
    }
})

$e.Open.Add_Click({
    if (-not $script:installed) { return }
    if (Get-Process -Name prismlauncher -ErrorAction SilentlyContinue) {
        $e.Status.Text = 'Закрой обычный Prism и снова нажми «Открыть Prism».'
        return
    }
    try {
        Start-Process -FilePath $script:installed.Exe -ArgumentList ('--dir "' + $script:installed.Data.TrimEnd('\') + '"')
    } catch { $e.Status.Text = $_.Exception.Message }
})

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(62)
$timer.Add_Tick({
    if ($e.Motion.IsChecked) {
        $time = $clock.Elapsed.TotalSeconds
        $e.Bubble1.RenderTransform.Y = [Math]::Sin($time*1.25)*11
        $e.Bubble2.RenderTransform.Y = [Math]::Sin($time*.91+1.5)*15
        $e.Bubble3.RenderTransform.Y = [Math]::Sin($time*1.45+2.2)*8
        [double]$cue = 0
        $valid = [double]::TryParse($e.Cue.Text.Replace(',','.'), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$cue)
        $since = $audio.Position.TotalSeconds - $cue
        if ($valid -and $cue -ge 0 -and $script:audioState -eq 'playing' -and $since -ge 0 -and $since -lt 0.65) {
            $e.Star.Opacity = .23 + .77*[Math]::Sin($since/0.65*[Math]::PI)
        } else { $e.Star.Opacity = .23 }
    } else { $e.Star.Opacity = .23 }
    if (-not $script:worker) { return }
    $resultPath = Join-Path $env:PRISM_SETUP_TEMP 'result.json'
    $result = $null
    if (Test-Path -LiteralPath $resultPath) {
        try { $result = [IO.File]::ReadAllText($resultPath) | ConvertFrom-Json } catch {}
    }
    if ($result.Status) { $e.Status.Text = $result.Status }
    if ($result.Done) {
        Set-Working $false
        $script:worker = $null
        if ($result.Error) { $e.Status.Text = $result.Error; return }
        $script:installed = $result
        $e.Open.IsEnabled = $true
        try {
            $shell = New-Object -ComObject WScript.Shell
            $link = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Prism GitHub Mods.lnk'))
            $link.TargetPath = $result.Exe
            $link.WorkingDirectory = Split-Path -LiteralPath $result.Exe
            $link.Arguments = '--dir "' + $result.Data.TrimEnd('\') + '"'
            $link.Description = 'Prism Launcher с вкладкой GitHub'
            $link.Save()
        } catch { $e.Status.Text = 'Патч установлен. Ярлык создать не удалось, используй «Открыть Prism».' }
    } elseif ($script:worker.HasExited) {
        $script:worker = $null
        Set-Working $false
        $e.Status.Text = 'Установка прервана. Можно повторить.'
    }
})
$window.Add_Closing({ param($sender, $eventArgs)
    if ($script:worker -and -not $script:worker.HasExited) {
        $eventArgs.Cancel = $true
        $e.Status.Text = 'Дождись завершения установки перед закрытием.'
    } else { $timer.Stop(); $audio.Close() }
})
$timer.Start()
$null = $window.ShowDialog()
