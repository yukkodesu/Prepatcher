# Requires Git and the .NET 10 SDK. Run manually when regenerating the bundled DLL.
$ErrorActionPreference = 'Stop'
$harmonyCommit = 'a264a1bf1ce689e4589e8dcc54b1e2818602a90a'
$monoModVersion = '1.3.6'
$checkout = Join-Path $PSScriptRoot ('obj/Harmony-' + [Guid]::NewGuid().ToString('N'))

function Assert-NativeSuccess {
    if ($LASTEXITCODE -ne 0) { throw "Native command failed with exit code $LASTEXITCODE" }
}

New-Item -ItemType Directory -Path $checkout -Force | Out-Null
Push-Location $checkout
try {
    git init --quiet
    Assert-NativeSuccess
    git remote add origin https://github.com/pardeike/Harmony.git
    Assert-NativeSuccess
    git fetch --depth 1 origin $harmonyCommit
    Assert-NativeSuccess
    git checkout --detach FETCH_HEAD
    Assert-NativeSuccess

    # The release pins SDK 10.0.100 to its patch band. Allow installed 10.0 SDKs.
    $sdk = Get-Content global.json -Raw | ConvertFrom-Json
    $sdk.sdk.rollForward = 'latestFeature'
    $sdk | ConvertTo-Json -Depth 4 | Set-Content global.json -Encoding UTF8

    # Keep Harmony's released sources and upstream fat-assembly merge procedure.
    dotnet build Lib.Harmony/Lib.Harmony.csproj -c Release `
        -p:TargetFrameworks=net472 -p:GeneratePackageOnBuild=false `
        "-p:MonoModCoreVersion=$monoModVersion"
    Assert-NativeSuccess

    Copy-Item Lib.Harmony/bin/Release/net472/0Harmony.dll `
        (Join-Path $PSScriptRoot '../Assemblies/0Harmony.dll') -Force
} finally {
    Pop-Location
}
Write-Host 'Rebuilt Harmony 2.4.2 with MonoMod.Core 1.3.6. Run dotnet build Source/Prepatcher.sln -c Release.'
Write-Host "Build checkout retained for inspection: $checkout"
