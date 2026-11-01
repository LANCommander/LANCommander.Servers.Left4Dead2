# Left 4 Dead 2 Server (Docker)

This repository provides a Dockerized **Left 4 Dead 2** game server suitable for running a L4D2 server in a clean, reproducible way.  
The image is designed for **headless operation**, automatically downloads and updates the game server via SteamCMD, supports file overlaying using OverlayFS, and includes optional SourceMod/MetaMod support.

---

## Features

- Left 4 Dead 2 game server support (coop, realism, versus, survival and scavenge)
- Direct `connect <ip>` joins enabled by default (no Steam lobby required)
- Automatically downloads and updates the game server via SteamCMD
- Optional SourceMod/MetaMod installation and management
- Supports file overlaying using OverlayFS (no file copying required)
- Configurable automatic updates

## Docker Compose Example

```yaml
services:
  l4d2-server:
    image: lancommander/left4dead2:latest
    container_name: my-l4d2-server

    # Expose game server ports
    ports:
      - "27015:27015/udp"  # Game server port
      - "27020:27020/udp"  # SourceTV port (optional)

    # Bind mounts
    volumes:
      - ./config:/config      # Game server configuration and overlay directory

    environment:
      STEAM_APP_UPDATE: "true"               # Enable automatic updates
      START_ARGS: "-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"
      INSTALL_SOURCEMOD: "true"              # SourceMod/MetaMod (default: true)

    # For overlayfs support, add one of these:
    # Option 1: Full privileges (less secure)
    privileged: true
    # Option 2: Minimal privileges (recommended)
    # cap_add:
    #   - SYS_ADMIN

    restart: unless-stopped
```

---

## Directory Layout (Host)

```text
.
└── config/
    ├── Server/            # Game files downloaded by SteamCMD (auto-created)
    │   └── left4dead2/      # Left 4 Dead 2 game directory
    ├── Overlay/           # Files to overlay on game directory (optional)
    │   └── left4dead2/      # Left 4 Dead 2 overlay directory
    │       ├── addons/    # SourceMod/MetaMod installation location
    │       │   ├── sourcemod/
    │       │   │   ├── plugins/     # Place your .smx plugin files here
    │       │   │   ├── configs/     # SourceMod configuration files
    │       │   │   └── ...
    │       │   └── metamod/
    │       ├── maps/      # Custom maps
    │       ├── cfg/       # Server configuration files (server.cfg, etc.)
    │       └── ...        # Any other files you want to overlay
    ├── Merged/            # Overlayfs merged view (auto-created, if overlayfs enabled)
    ├── .overlay-work/     # Overlayfs work directory (auto-created)
    ├── Scripts/
    │   └── Hooks/         # Script files in this directory get automatically executed if registered to a hook
    └── ...                # Your game server configuration files
```

The `config` directory **must be writable** by Docker. The `Server` directory is automatically created and populated by SteamCMD on first startup.

---

## Configuration

### Custom Scripts

You can create custom scripts in the `/config/Scripts/Hooks/{HookName}` directory to execute at various points in the container's startup. This is useful for:
- Installing additional dependencies
- Setting up environment variables
- Downloading additional files
- Modifying configuration before the game server starts

All scripts should be PowerShell scripts.

### File Overlaying

The overlay directory (`/config/Overlay`) allows you to overlay files on top of the game directory without copying files. This is useful for:
- Replacing game files (maps, scripts, assets)
- Adding custom content
- Modifying game files without touching the base installation

**How it works:**
- Files in `/config/Overlay` will appear in the merged view at `/config/Merged`
- If a file exists in both `/config/Server` and `/config/Overlay`, the version in `/config/Overlay` takes precedence
- The game server runs from the merged directory

**Requirements:**
- Container must run with `--cap-add SYS_ADMIN` or `--privileged` flag

**Example overlay structure:**
```text
/config/Overlay/
├── maps/
│   └── custom_map.bsp
├── scripts/
│   └── server.cfg
└── addons/
    └── custom_addon.vdf
```

---

## SourceMod Installation

This image includes support for automatically installing SourceMod and MetaMod:Source. SourceMod is a powerful administration plugin framework for Source engine games.

### Enabling SourceMod

SourceMod installation is enabled by default (`INSTALL_SOURCEMOD="true"`). Set it to `"false"` to skip it:

```yaml
environment:
  INSTALL_SOURCEMOD: "false"
```

When enabled, the container will automatically:
- Install MetaMod:Source (required dependency for SourceMod)
- Install SourceMod
- Place all files in the overlay directory (`/config/Overlay/left4dead2/addons/`)

### Installing Plugins

Once SourceMod is installed, you can add custom plugins by placing `.smx` files in:

```
/config/Overlay/left4dead2/addons/sourcemod/plugins/
```

**Example:**
```bash
# Place your plugin file
cp my_plugin.smx ./config/Overlay/left4dead2/addons/sourcemod/plugins/

# Restart the container to load the plugin
docker restart my-l4d2-server
```

Plugins are automatically loaded when the server starts. You can manage plugins via the SourceMod admin console or by adding/removing `.smx` files from the plugins directory.


### SourceMod Configuration

SourceMod configuration files should be placed in:

```
/config/Overlay/left4dead2/addons/sourcemod/configs/
```

Common configuration files:
- `admins_simple.ini` - Admin user configuration
- `core.cfg` - Core SourceMod settings
- `database.cfg` - Database configuration (if using database features)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `STEAM_APP_ID` | Steam app id of the dedicated server | `222860` |
| `STEAM_APP_UPDATE` | Enable automatic game updates on startup (`true`/`false`) | `true` |
| `START_EXE` | Server executable (relative to the game directory) | `srcds_run` |
| `START_ARGS` | Arguments used to start the game server | `"-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"` |
| `GAME_MOD` | Game directory that SourceMod/MetaMod are installed into | `left4dead2` |
| `INSTALL_SOURCEMOD` | Enable SourceMod/MetaMod installation (`true`/`false`) | `true` |
| `SOURCEMOD_MAJOR_VERSION` | SourceMod release branch | `1.12` |
| `SOURCEMOD_VERSION` | SourceMod version to install | `1.12.0-git7221` |
| `SOURCEMOD_URL` | Override the SourceMod download URL | *(unset)* |
| `METAMOD_MAJOR_VERSION` | MetaMod:Source release branch | `1.12` |
| `METAMOD_VERSION` | MetaMod version to install | `1.12.0-git1219` |
| `METAMOD_URL` | Override the MetaMod download URL | *(unset)* |
| `HTTP_FILESERVER_ENABLED` | Serve custom content over HTTP (FastDL) on port 80 | `true` |
| `HTTP_FILESERVER_WEB_ROOT` | Directory served by the HTTP file server | `/config/Merged/left4dead2` |
| `HTTP_FILESERVER_FILE_PATTERN` | Regex of request paths the file server allows | maps, materials, models and sound files |

### `STEAM_APP_UPDATE`

Set to `false` or `0` to disable automatic updates. When disabled, SteamCMD will not run on container startup.

### `START_ARGS`

Arguments passed to the game server executable at startup. Default example:

```bash
START_ARGS="-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"
```

You can customize this with additional server parameters:

```bash
START_ARGS="-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0 +sv_lan 0"
```

---

## Running the Server

### Basic run (with automatic updates)

```bash
mkdir -p config

docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "./config:/config" \
  -e START_ARGS="-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0" \
  lancommander/left4dead2:latest
```

### With SourceMod enabled

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  -e STEAM_APP_UPDATE="true" \
  -e START_ARGS="-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0 +mp_gamemode versus" \
  -e INSTALL_SOURCEMOD="true" \
  lancommander/left4dead2:latest
```

### With custom configuration and overlay

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  -e STEAM_APP_UPDATE="true" \
  -e START_ARGS="-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0 +mp_gamemode versus" \
  -e INSTALL_SOURCEMOD="true" \
  lancommander/left4dead2:latest
```

### Disable automatic updates

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  -e STEAM_APP_UPDATE="false" \
  -e START_ARGS="-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0" \
  lancommander/left4dead2:latest
```

### Using command arguments instead of START_ARGS

You can also pass the server arguments directly to the container:

```bash
docker run --rm -it \
  --cap-add SYS_ADMIN \
  -p 27015:27015/udp \
  -v "$(pwd)/config:/config" \
  lancommander/left4dead2:latest \
  ./srcds_run -game left4dead2 -console +map c1m1_hotel
```

---

## OverlayFS Details

The container uses Linux OverlayFS to merge the server directory (`/config/Server`) with the overlay directory (`/config/Overlay`) into a merged view (`/config/Merged`). This allows you to:

1. **Replace files** without modifying the base game installation
2. **Add files** that don't exist in the base game
3. **Avoid copying** large files - OverlayFS is a union filesystem

**Technical details:**
- **Lower layer**: `/config/Server` (base game files from SteamCMD)
- **Upper layer**: `/config/Overlay` (your custom files)
- **Merged view**: `/config/Merged` (where the game server runs from)
- **Work directory**: `/config/.overlay-work` (required by OverlayFS)

If OverlayFS cannot be mounted (e.g., missing privileges), the container will fall back to using `/config/Server` directly and log a warning.

---

## Troubleshooting

### OverlayFS not working

If you see warnings about OverlayFS, ensure your container has the required privileges:

```bash
# Option 1: Add SYS_ADMIN capability (recommended)
docker run --cap-add SYS_ADMIN ...

# Option 2: Use privileged mode (less secure)
docker run --privileged ...
```

### Game server not starting

1. Verify `START_ARGS` contains the correct arguments for Left 4 Dead 2
2. Check container logs: `docker logs <container-name>`
3. Ensure the server directory was downloaded: check `/config/Server/left4dead2` in the container
4. Verify the server configuration files are correct (e.g., `server.cfg`)

### SourceMod not loading

1. Ensure `INSTALL_SOURCEMOD` is set to `"true"` (not just `true` without quotes in YAML)
2. Check that SourceMod was installed: verify `/config/Overlay/left4dead2/addons/sourcemod` exists
3. Check server console logs for SourceMod loading messages
4. Verify MetaMod is installed: check for `/config/Overlay/left4dead2/addons/metamod.vdf`
5. Ensure plugins are compiled `.smx` files (not `.sp` source files)

### `ERROR! Failed to install app '222860' (Missing configuration)`

The Left 4 Dead 2 Dedicated Server app only defines a Windows launch configuration on Steam, so a fresh Linux install fails with this error. The image handles this in the `PreSteamInstallGame/10-BootstrapInstall.ps1` hook: when `Server/steamapps/appmanifest_222860.acf` doesn't exist yet, it refreshes the app info (`app_info_update 1`) and installs once with the Windows platform, and the normal Linux install then adds the Linux binaries. Later updates work as usual. If the first install was interrupted, delete `Server/steamapps/appmanifest_222860.acf` and restart the container to run the bootstrap again.

### `Overlay/` fills up with copies of the game files

The entrypoint runs `chown -R /config` after mounting the overlay, and changing the owner of a file through `Merged/` makes OverlayFS copy it up into `Overlay/`. SteamCMD runs as root, so the `PostSteamInstallGame/10-ChownServer.ps1` hook hands `Server/` back to the run user after every install or update. If an older container already copied files up, stop it, keep only your own files in `Overlay/` (configs, `addons/`) and delete the rest.

### Players can't join with `connect <ip>`

Left 4 Dead 2 servers only accept players coming from a Steam matchmaking lobby unless `sv_allow_lobby_connect_only` is `0`. The default `START_ARGS` sets it; if you override `START_ARGS` or set it in `server.cfg`, keep it at `0`. For a LAN-only server also add `+sv_lan 1`.

### Choosing a game mode

All game modes use the same campaign maps (`c1m1_hotel`, `c2m1_highway`, ... `c14m1_junkyard`). Pick the mode with `+mp_gamemode <coop|realism|versus|survival|scavenge>`; survival and scavenge only run on maps that have those modes set up.

### `Failed to open bin/dedicated_srv.so` on first boot

On the very first start the overlay is mounted before SteamCMD has created `Server/bin`, so `srcds_run` can't find the engine. The automatic restart (`restart: unless-stopped`) picks it up on the next start; no action is needed.

### Permission errors

The container runs as a non-root user (`lancommander`, UID 1337). If you encounter permission errors:

1. Ensure mounted volumes are writable
2. Check file ownership in the container
3. Review logs for specific permission error messages

---

## License

SteamCMD and game servers are distributed under their respective licenses.
This repository contains only Docker build logic and helper scripts licensed under MIT.
