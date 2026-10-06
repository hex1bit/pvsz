param([Parameter(Mandatory)][string]$ResourceDirectory)
$ErrorActionPreference = 'Stop'
$resourceRoot = (Resolve-Path -LiteralPath $ResourceDirectory).Path
$pakPath = Join-Path $resourceRoot 'main.pak'
if (!(Test-Path -LiteralPath $pakPath -PathType Leaf)) { throw "Missing main.pak: $resourceRoot" }
$stream = [IO.File]::OpenRead($pakPath)
$reader = $null
$names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
try {
    # Only the index is decoded; no copyrighted assets are extracted or changed.
    $header = New-Object byte[] ([Math]::Min(4194304, $stream.Length))
    $count = $stream.Read($header,0,$header.Length)
    for ($i=0; $i -lt $count; $i++) { $header[$i] = $header[$i] -bxor 0xF7 }
    $reader = [IO.BinaryReader]::new([IO.MemoryStream]::new($header,0,$count))
    $magic = $reader.ReadUInt32()
    $version = $reader.ReadUInt32()
    if ($magic -ne [uint32]3133164224 -or $version -ne 0) { throw 'Unsupported PAK header.' }
    $payloadSize = [long]0
    while (($reader.ReadByte() -band 0x80) -eq 0) {
        $width = $reader.ReadByte()
        $bytes = $reader.ReadBytes($width)
        if ($bytes.Length -ne $width) { throw 'Truncated PAK index.' }
        $name = [Text.Encoding]::UTF8.GetString($bytes).Replace('\','/')
        $null = $names.Add($name)
        $size = $reader.ReadInt32()
        if ($size -lt 0) { throw 'Invalid PAK entry size.' }
        $payloadSize += $size
        $null = $reader.ReadInt64()
    }
    if ($reader.BaseStream.Position + $payloadSize -ne $stream.Length) { throw 'PAK index/payload size mismatch.' }
    foreach ($required in @('properties/resources.xml','properties/LawnStrings.txt','properties/default.xml')) {
        if (!$names.Contains($required) -and !(Test-Path -LiteralPath (Join-Path $resourceRoot $required))) {
            throw "Required resource missing: $required"
        }
    }
} finally {
    if ($reader) { $reader.Dispose() }
    $stream.Dispose()
}
$originalExe = Join-Path $resourceRoot 'PlantsVsZombies.exe'
[pscustomobject]@{
    ResourceDirectory = $resourceRoot
    PakEntries = $names.Count
    PakSha256 = (Get-FileHash -LiteralPath $pakPath -Algorithm SHA256).Hash
    OriginalFileVersion = if (Test-Path -LiteralPath $originalExe) { (Get-Item -LiteralPath $originalExe).VersionInfo.FileVersion } else { 'Not available' }
    Status = 'Index and required files verified; gameplay/content authenticity still unverified'
}
