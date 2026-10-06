param([ValidateRange(1,32)][int]$Jobs = 4)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$toolBin = Join-Path $projectRoot '.tools/msys64/ucrt64/bin'
$cmake = Join-Path $toolBin 'cmake.exe'
if (!(Test-Path -LiteralPath $cmake)) { throw 'Toolchain missing. See DEVELOPMENT.zh-CN.md.' }
$oldPath = $env:PATH
try {
    $env:PATH = "$toolBin;$oldPath"
    & $cmake -S $projectRoot -B (Join-Path $projectRoot 'build/windows-release') -G Ninja '-DCMAKE_BUILD_TYPE=Release' '-DBUILD_STATIC=ON' '-DPVZ_DEBUG=OFF' '-DDO_FIX_BUGS=OFF' '-DCONSOLE=OFF'
    if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed.' }
    & $cmake --build (Join-Path $projectRoot 'build/windows-release') --parallel $Jobs
    if ($LASTEXITCODE -ne 0) { throw 'Compilation failed.' }
    $dist = Join-Path $projectRoot 'dist/windows-x64'
    New-Item -ItemType Directory -Force -Path $dist | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot 'build/windows-release/pvz-portable.exe') -Destination (Join-Path $dist 'pvz-wanzi.exe')
    foreach ($name in @('LICENSE','COPYING','README.md','DEVELOPMENT.zh-CN.md')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $dist
    }
    $revision = (& git -C $projectRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Cannot record source revision.' }
    [ordered]@{
        sourceRevision = $revision
        upstreamBaseline = '848b1dddbe82a5976ee6005992b51bb8fa79b00c'
        configuration = 'Release'
        platform = 'Windows x64 UCRT64'
        debugCheats = $false
        communityBugFixes = $false
        binarySha256 = (Get-FileHash (Join-Path $dist 'pvz-wanzi.exe') -Algorithm SHA256).Hash
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dist 'build-info.json') -Encoding UTF8
    Write-Output "Built: $dist"
} finally { $env:PATH = $oldPath }
