# Left 4 Dead 2 Docker Container

This Docker container provides a fully configured Left 4 Dead 2 game server that automatically downloads and updates the game via SteamCMD, supports file overlaying using OverlayFS, and includes optional SourceMod/MetaMod support.

## Quick Start

```yaml
services:
  left4dead2-cooperative:
    image: lancommander/left4dead2:latest
    container_name: left4dead2-cooperative

    ports:
      - 27016:27015/udp
      - 27021:27020/udp
      - 27080:80 # For FastDL support

    volumes:
      - "/data/Servers/Left 4 Dead 2:/config"

    environment:
      STEAM_APP_UPDATE: "true"
      START_ARGS: "-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"
      INSTALL_SOURCEMOD: "true"

    cap_add:
      - SYS_ADMIN

    security_opt:
      - apparmor:unconfined

    restart: unless-stopped
```

## Configuration Options

### Ports

The container exposes the following ports:

- **27015/udp** - Main game server port (default). Clients connect to this port to join the server.
- **27015/tcp** - RCON (remote console).
- **27020/udp** - SourceTV port (optional). Used for game broadcasting and recording.
- **80/tcp** - HTTP file server port (optional). Used for serving game files to clients (See [FastDL](https://developer.valvesoftware.com/wiki/FastDL)).

**Port Mapping:**
In the example configuration, ports are mapped as:
- `27016:27015/udp` - Maps host port 27016 to container port 27015
- `27021:27020/udp` - Maps host port 27021 to container port 27020
- `27080:80` - Maps host port 27080 to container port 80

You can customize these mappings based on your network requirements. If you're running multiple servers, use different host ports for each instance.

### Volumes

The container requires a volume mount for the `/config` directory, which stores:

- **Server/** - Game files downloaded by SteamCMD (auto-created)
- **Overlay/** - Custom files that overlay on top of the game directory
- **Merged/** - OverlayFS merged view (auto-created)
- **Scripts/** - Custom PowerShell scripts for hooks

**Example:**
```yaml
volumes:
  - "/data/Servers/Left 4 Dead 2:/config"
```

The host path can be:
- An absolute path (Windows: `C:\data\...`, Linux: `/data/...`)
- A relative path (e.g., `./config:/config`)
- A named volume (e.g., `l4d2-server-data:/config`)

**Important:** The mounted directory must be writable by the container.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `STEAM_APP_ID` | Steam app id of the dedicated server | `222860` | No |
| `STEAM_APP_UPDATE` | Enable automatic game updates on startup (`true`/`false`) | `true` | No |
| `START_EXE` | Server executable (relative to the game directory) | `srcds_run` | No |
| `START_ARGS` | Arguments used to start the game server | `"-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"` | No |
| `GAME_MOD` | Game directory that SourceMod/MetaMod are installed into | `left4dead2` | No |
| `INSTALL_SOURCEMOD` | Enable SourceMod/MetaMod installation (`true`/`false`) | `true` | No |
| `SOURCEMOD_MAJOR_VERSION` | SourceMod release branch | `1.12` | No |
| `SOURCEMOD_VERSION` | SourceMod version to install | `1.12.0-git7221` | No |
| `SOURCEMOD_URL` | Override the SourceMod download URL | *(unset)* | No |
| `METAMOD_MAJOR_VERSION` | MetaMod:Source release branch | `1.12` | No |
| `METAMOD_VERSION` | MetaMod version to install | `1.12.0-git1219` | No |
| `METAMOD_URL` | Override the MetaMod download URL | *(unset)* | No |
| `HTTP_FILESERVER_ENABLED` | Serve custom content over HTTP (FastDL) on port 80 | `true` | No |
| `HTTP_FILESERVER_WEB_ROOT` | Directory served by the HTTP file server | `/config/Merged/left4dead2` | No |
| `HTTP_FILESERVER_FILE_PATTERN` | Regex of request paths the file server allows | maps, materials, models and sound files | No |

#### `STEAM_APP_UPDATE`

Controls whether SteamCMD updates the game server on container startup.

- `"true"` - Automatically download/update the game server
- `"false"` - Skip updates (useful for offline operation or faster startup)

**Example:**
```yaml
environment:
  STEAM_APP_UPDATE: "true"
```

#### `START_ARGS`

Arguments passed to the game server executable at startup.

**Default:**
```yaml
START_ARGS: "-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"
```

**Customization Examples:**

Basic server with custom map:
```yaml
START_ARGS: "-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"
```

Internet server bound to all interfaces:
```yaml
START_ARGS: "-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0 +sv_lan 0 +ip 0.0.0.0"
```

Server with RCON password:
```yaml
START_ARGS: "-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0 +rcon_password mypassword"
```

**Common Server Parameters:**
- `+map <mapname>` - Set the starting map (e.g., `c1m1_hotel`, `c2m1_highway`)
- `+mp_gamemode <mode>` - `coop` (default, 4 players), `realism`, `versus` (8 players), `survival` or `scavenge`
- `+sv_allow_lobby_connect_only 0` - Allow players to join with `connect <ip>` instead of through a Steam lobby (set by default)
- `+sv_lan 0` - Enable internet play (0 = internet, 1 = LAN only)
- `+ip <address>` - Server IP address (use `0.0.0.0` for all interfaces)
- `+port <port>` - Server port (default: 27015)
- `+rcon_password <password>` - RCON password for remote administration
- `+hostname "<name>"` - Server name displayed in server browser

#### `INSTALL_SOURCEMOD`

Enables automatic installation of SourceMod and MetaMod:Source, which provide plugin support and enhanced server administration.

- `"true"` - Install SourceMod and MetaMod
- `"false"` - Skip SourceMod installation

Default: `"true"`.

When enabled, the container will:
1. Download and install MetaMod:Source (required dependency)
2. Download and install SourceMod
3. Place all files in `/config/Overlay/left4dead2/addons/`

**Example:**
```yaml
environment:
  INSTALL_SOURCEMOD: "true"
```

### Security Options

The container requires elevated privileges to use OverlayFS for file overlaying.

#### `cap_add: SYS_ADMIN`

Adds the `SYS_ADMIN` capability, which is required for mounting OverlayFS. This is the recommended approach as it provides minimal necessary privileges.

```yaml
cap_add:
  - SYS_ADMIN
```

#### `security_opt: apparmor:unconfined`

On Ubuntu hosts with AppArmor enabled, you may need to disable AppArmor restrictions for the container. This is often necessary for OverlayFS to function properly.

```yaml
security_opt:
  - apparmor:unconfined
```

**Alternative Options:**

If you prefer less security but simpler configuration, you can use privileged mode:

```yaml
privileged: true
```

**Note:** Privileged mode grants the container extensive access to the host system and is less secure than using `cap_add: SYS_ADMIN`.

### Restart Policy

```yaml
restart: unless-stopped
```

This ensures the container automatically restarts if it stops unexpectedly, but won't restart if you manually stop it.

**Other options:**
- `no` - Never restart
- `always` - Always restart, even after manual stop
- `on-failure` - Restart only on failure

## Directory Structure

The `/config` directory contains the following structure:

```
/config/
├── Server/              # Game files from SteamCMD (auto-created)
│   └── left4dead2/        # Left 4 Dead 2 game directory
├── Overlay/             # Custom files overlay (your modifications)
│   └── left4dead2/
│       ├── addons/      # SourceMod/MetaMod installation location
│       │   ├── sourcemod/
│       │   │   ├── plugins/     # Place .smx plugin files here
│       │   │   ├── configs/     # SourceMod configuration files
│       │   │   └── ...
│       │   └── metamod/
│       ├── maps/        # Custom maps
│       ├── cfg/         # Server configuration files (server.cfg, etc.)
│       └── ...
├── Merged/              # OverlayFS merged view (auto-created)
├── .overlay-work/       # OverlayFS work directory (auto-created)
└── Scripts/
    └── Hooks/           # Custom PowerShell scripts for hooks
```

## SourceMod Configuration

### Installing Plugins

Once SourceMod is installed, add plugins by placing compiled `.smx` files in:

```
/config/Overlay/left4dead2/addons/sourcemod/plugins/
```

**Example:**
```bash
# Copy plugin to the overlay directory
cp my_plugin.smx "/data/Servers/Left 4 Dead 2/Cooperative/Overlay/left4dead2/addons/sourcemod/plugins/"

# Restart the container to load the plugin
docker restart left4dead2-cooperative
```

### SourceMod Configuration Files

Place SourceMod configuration files in:

```
/config/Overlay/left4dead2/addons/sourcemod/configs/
```

**Common configuration files:**
- `admins_simple.ini` - Admin user configuration
- `core.cfg` - Core SourceMod settings
- `database.cfg` - Database configuration (if using database features)

### Server Configuration

Place server configuration files in:

```
/config/Overlay/left4dead2/cfg/
```

**Example `server.cfg`:**
```
hostname "My Left 4 Dead 2 Server"
sv_lan 0
sv_allow_lobby_connect_only 0
rcon_password "your_rcon_password"
```

## OverlayFS

The container uses Linux OverlayFS to merge the base game files with your custom files:

- **Lower layer**: `/config/Server` (base game files from SteamCMD)
- **Upper layer**: `/config/Overlay` (your custom files)
- **Merged view**: `/config/Merged` (where the game server runs from)

**Benefits:**
- Replace files without modifying the base installation
- Add custom content (maps, plugins, configs)
- No file copying required - OverlayFS is a union filesystem
- Easy updates - base game files can be updated without losing customizations

If OverlayFS cannot be mounted (e.g., missing privileges), the container will fall back to using `/config/Server` directly and log a warning.

## Troubleshooting

### Container Won't Start

1. **Check logs:**
   ```bash
   docker logs left4dead2-cooperative
   ```

2. **Verify permissions:**
   Ensure the mounted volume is writable:
   ```bash
   # Linux
   chmod -R 755 "/data/Servers/Left 4 Dead 2/Cooperative"
   
   # Windows
   # Ensure the directory has proper permissions in Windows
   ```

3. **Check security options:**
   Ensure `cap_add: SYS_ADMIN` is set, or use `privileged: true`

### Game Server Not Starting

1. **Verify START_ARGS:**
   Check that `START_ARGS` contains valid server arguments:
   ```yaml
   START_ARGS: "-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"
   ```

2. **Check server directory:**
   Verify that game files were downloaded:
   ```bash
   docker exec left4dead2-cooperative ls -la /config/Server/left4dead2
   ```

3. **Review server logs:**
   Check container logs for server startup messages and errors

### SourceMod Not Loading

1. **Verify installation:**
   Ensure `INSTALL_SOURCEMOD: "true"` is set (with quotes in YAML)

2. **Check installation directory:**
   ```bash
   docker exec left4dead2-cooperative ls -la /config/Overlay/left4dead2/addons/sourcemod
   ```

3. **Verify MetaMod:**
   Check that MetaMod is installed:
   ```bash
   docker exec left4dead2-cooperative ls -la /config/Overlay/left4dead2/addons/metamod.vdf
   ```

4. **Check server console:**
   Look for SourceMod loading messages in the container logs

### OverlayFS Warnings

If you see warnings about OverlayFS:

1. **Verify capabilities:**
   Ensure `cap_add: SYS_ADMIN` is present in your docker-compose.yml

2. **Check AppArmor:**
   On Ubuntu, add `security_opt: apparmor:unconfined`

3. **Alternative:**
   Use `privileged: true` (less secure but simpler)

### `ERROR! Failed to install app '222860' (Missing configuration)`

The Left 4 Dead 2 Dedicated Server app only defines a Windows launch configuration on Steam, so a fresh Linux install fails with this error. The image handles this in the `PreSteamInstallGame/10-BootstrapInstall.ps1` hook: when `Server/steamapps/appmanifest_222860.acf` doesn't exist yet, it refreshes the app info (`app_info_update 1`) and installs once with the Windows platform, and the normal Linux install then adds the Linux binaries. Later updates work as usual. If the first install was interrupted, delete `Server/steamapps/appmanifest_222860.acf` and restart the container to run the bootstrap again.

### Players can't join with `connect <ip>`

Left 4 Dead 2 servers only accept players coming from a Steam matchmaking lobby unless `sv_allow_lobby_connect_only` is `0`. The default `START_ARGS` sets it; if you override `START_ARGS` or set it in `server.cfg`, keep it at `0`. For a LAN-only server also add `+sv_lan 1`.

### Choosing a game mode

All game modes use the same campaign maps (`c1m1_hotel`, `c2m1_highway`, ... `c14m1_junkyard`). Pick the mode with `+mp_gamemode <coop|realism|versus|survival|scavenge>`; survival and scavenge only run on maps that have those modes set up. `mp_gamemode`, `sv_allowdownload` and `sv_allowupload` are hidden cvars in Left 4 Dead 2: a `.cfg` file can't set them (the console prints `Unknown command "mp_gamemode"`), so set them in `START_ARGS`, or at runtime with SourceMod's `sm_cvar`.

### `Failed to open bin/dedicated_srv.so` on first boot

On the very first start the overlay is mounted before SteamCMD has created `Server/bin`, so `srcds_run` can't find the engine. The automatic restart (`restart: unless-stopped`) picks it up on the next start; no action is needed.

### Port Already in Use

If you get port binding errors:

1. **Check for existing containers:**
   ```bash
   docker ps -a
   ```

2. **Use different ports:**
   Change the port mapping in docker-compose.yml:
   ```yaml
   ports:
     - 27017:27015/udp  # Use a different host port
   ```

3. **Stop conflicting containers:**
   ```bash
   docker stop <container-name>
   ```

### Permission Errors

The container runs as a non-root user. If you encounter permission errors:

1. **Check file ownership:**
   ```bash
   docker exec left4dead2-cooperative ls -la /config
   ```

2. **Verify volume mount:**
   Ensure the host directory is accessible and writable

3. **Review logs:**
   Check container logs for specific permission error messages

## Advanced Usage

### Custom Hooks

You can create custom PowerShell scripts that execute at various points in the container's lifecycle. Place scripts in:

```
/config/Scripts/Hooks/{HookName}/
```

**Available hooks:**
- `PreSteamInstallGame` - Before SteamCMD runs
- `PostSteamInstallGame` - After SteamCMD completes
- `PreInstallSourceMod` - Before SourceMod installation
- `PostInstallSourceMod` - After SourceMod installation

**Example hook script** (`/config/Scripts/Hooks/PostSteamInstallGame/10-CustomSetup.ps1`):
```powershell
Write-Host "Running custom setup..."
# Your custom commands here
```

### HTTP File Server

The container includes an optional HTTP file server (port 80) for serving game files to clients. This is useful for fast downloads of custom maps and content.

The file server is configured via environment variables:
- `HTTP_FILESERVER_ENABLED` - Enable/disable the file server
- `HTTP_FILESERVER_WEB_ROOT` - Root directory for file serving
- `HTTP_FILESERVER_FILE_PATTERN` - Pattern for files to serve

### Multiple Server Instances

To run multiple Left 4 Dead 2 servers on the same host:

1. **Use different container names:**
   ```yaml
   container_name: left4dead2-server1
   ```

2. **Use different ports:**
   ```yaml
   ports:
     - 27016:27015/udp
     - 27021:27020/udp
   ```

3. **Use different volume mounts:**
   ```yaml
   volumes:
     - "/data/Servers/Left 4 Dead 2/Server1:/config"
   ```

4. **Use different maps/names:**
   ```yaml
   environment:
     START_ARGS: "-game left4dead2 -console +map c2m1_highway +sv_allow_lobby_connect_only 0 +hostname 'Server 1'"
   ```

## Additional Resources

- [Left 4 Dead 2 Server Documentation](https://developer.valvesoftware.com/wiki/Source_Dedicated_Server)
- [SourceMod Documentation](https://wiki.alliedmods.net/Category:SourceMod_Documentation)
- [MetaMod:Source Documentation](https://wiki.alliedmods.net/Metamod:Source)
