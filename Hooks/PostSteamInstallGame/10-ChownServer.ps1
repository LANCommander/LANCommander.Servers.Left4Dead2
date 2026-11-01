#Requires -Modules Logging

# SteamCMD runs as root after the entrypoint's "chown -R /config", so files it adds or
# updates in Server/ stay owned by root. On the next start that chown walks Merged/
# first, and OverlayFS copies every one of those files up into Overlay/, where the
# stale copies hide later updates. Handing them to the run user now prevents that.

Write-Log "Setting ownership of $Env:SERVER_DIR to ${Env:UID}:${Env:GID}"

chown -R "${Env:UID}:${Env:GID}" $Env:SERVER_DIR
if ($LASTEXITCODE -ne 0) { throw "Failed to set ownership of $Env:SERVER_DIR" }
