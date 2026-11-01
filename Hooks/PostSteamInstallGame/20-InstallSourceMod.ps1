#Requires -Modules Logging
#Requires -Modules Hooks

if ($Env:INSTALL_SOURCEMOD -notin @("true", "1", "yes")) {
    Write-Log "INSTALL_SOURCEMOD is not enabled. Skipping SourceMod installation."
    return
}

Invoke-Hook "PreInstallSourceMod"

Write-Log "Installing SourceMod..."

$metaModUrl = $Env:METAMOD_URL
$sourceModUrl = $Env:SOURCEMOD_URL

if (-not $metaModUrl) {
    $metaModUrl = "https://mms.alliedmods.net/mmsdrop/${Env:METAMOD_MAJOR_VERSION}/mmsource-${Env:METAMOD_VERSION}-linux.tar.gz"
}

if (-not $sourceModUrl) {
    $sourceModUrl = "https://sm.alliedmods.net/smdrop/${Env:SOURCEMOD_MAJOR_VERSION}/sourcemod-${Env:SOURCEMOD_VERSION}-linux.tar.gz"
}

$gameDir = "${Env:OVERLAY_DIR}/${Env:GAME_MOD}"

if (-not (Test-Path -Path $gameDir)) {
    Write-Log "Game directory $gameDir does not exist. Creating it."
    New-Item -ItemType Directory -Path $gameDir | Out-Null
}

if (-not (Test-Path -Path "$gameDir/addons/metamod.vdf")) {
    Write-Log "Downloading MetaMod from $metaModUrl"
    curl -fsSL --retry 3 --output /tmp/mmsource.tar.gz "$metaModUrl"
    if ($LASTEXITCODE -ne 0) { throw "Failed to download MetaMod from $metaModUrl" }

    Write-Log "Extracting MetaMod to $gameDir"
    tar -xzf /tmp/mmsource.tar.gz -C $gameDir
    if ($LASTEXITCODE -ne 0) { throw "Failed to extract MetaMod" }
} else {
    Write-Log "MetaMod is already installed. Skipping MetaMod installation."
}

if (-not (Test-Path -Path "$gameDir/addons/sourcemod")) {
    Write-Log "Downloading SourceMod from $sourceModUrl"
    curl -fsSL --retry 3 --output /tmp/sourcemod.tar.gz "$sourceModUrl"
    if ($LASTEXITCODE -ne 0) { throw "Failed to download SourceMod from $sourceModUrl" }

    Write-Log "Extracting SourceMod to $gameDir"
    tar -xzf /tmp/sourcemod.tar.gz -C $gameDir
    if ($LASTEXITCODE -ne 0) { throw "Failed to extract SourceMod" }
} else {
    Write-Log "SourceMod is already installed. Skipping SourceMod installation."
}

# The Left 4 Dead engine branch can resolve server plugin paths relative to bin/
# instead of the game directory. "../<game>/addons/..." resolves to the same file
# from either location.
$metaModVdf = "$gameDir/addons/metamod.vdf"
$metaModLoader = "../${Env:GAME_MOD}/addons/metamod/bin/server"

if ((Test-Path -Path $metaModVdf) -and -not (Select-String -Path $metaModVdf -SimpleMatch $metaModLoader -Quiet)) {
    Write-Log "Pointing metamod.vdf at $metaModLoader"
    (Get-Content -Path $metaModVdf -Raw) -replace '"file"\s+"[^"]*"', "`"file`"`t`"$metaModLoader`"" |
        Set-Content -Path $metaModVdf -NoNewline
}

# Left 4 Dead 2 has no 64-bit server; the x64 loader entry only produces a load error.
Remove-Item -Path "$gameDir/addons/metamod_x64.vdf" -Force -ErrorAction SilentlyContinue

# nextmap.smx refuses to load on Left 4 Dead 2 ("Nextmap is incompatible with this game").
$pluginsDir = "$gameDir/addons/sourcemod/plugins"
if (Test-Path -Path "$pluginsDir/nextmap.smx") {
    Write-Log "Disabling nextmap.smx (not supported by Left 4 Dead 2)"
    New-Item -ItemType Directory -Path "$pluginsDir/disabled" -Force | Out-Null
    Move-Item -Path "$pluginsDir/nextmap.smx" -Destination "$pluginsDir/disabled/nextmap.smx" -Force
}

chown -R "${Env:UID}:${Env:GID}" "$gameDir/addons"
if ($LASTEXITCODE -ne 0) { throw "Failed to set ownership of $gameDir/addons" }

Invoke-Hook "PostInstallSourceMod"