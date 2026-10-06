param([string]$ResourceDirectory, [switch]$Record)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$configPath = Join-Path $projectRoot 'config/local.json'
$saveDirectory = Join-Path $projectRoot 'runtime/saves'
if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if (!$ResourceDirectory) { $ResourceDirectory = $config.resourceDirectory }
    if ($config.saveDirectory) {
        $saveDirectory = if ([IO.Path]::IsPathRooted($config.saveDirectory)) { $config.saveDirectory } else { Join-Path $projectRoot $config.saveDirectory }
    }
}
if (!$ResourceDirectory) { throw 'Set resourceDirectory in config/local.json, or pass -ResourceDirectory.' }
if (![IO.Path]::IsPathRooted($ResourceDirectory)) {
    $ResourceDirectory = Join-Path $projectRoot $ResourceDirectory
}
& (Join-Path $PSScriptRoot 'Test-Resources.ps1') -ResourceDirectory $ResourceDirectory | Out-Host
$exe = Join-Path $projectRoot 'dist/windows-x64/pvz-wanzi.exe'
if (!(Test-Path -LiteralPath $exe)) { throw 'Build first using scripts/windows/Build.ps1.' }
New-Item -ItemType Directory -Force -Path $saveDirectory | Out-Null
$gameArgs = @('-resdir', [IO.Path]::GetFullPath($ResourceDirectory), '-savedir', [IO.Path]::GetFullPath($saveDirectory))
if ($Record) {
    $recordDir = Join-Path $projectRoot 'runtime/recordings'
    New-Item -ItemType Directory -Force -Path $recordDir | Out-Null
    $gameArgs += @('-record', (Join-Path $recordDir ((Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N') + '.dmo')))
}
$argumentLine = ($gameArgs | ForEach-Object { '"' + $_ + '"' }) -join ' '
$process = Start-Process -FilePath $exe -ArgumentList $argumentLine -WorkingDirectory $projectRoot -PassThru -Wait
if ($process.ExitCode -ne 0) { throw "Game exited with code $($process.ExitCode)" }
