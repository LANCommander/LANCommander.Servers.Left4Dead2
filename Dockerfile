# syntax=docker/dockerfile:1.7

# Override to build against a locally built base, e.g. lancommander/steamcmd:local
ARG BASE_IMAGE=lancommander/steamcmd:latest
FROM ${BASE_IMAGE}

# SteamCMD settings
ENV STEAM_APP_ID="222860"
ENV START_EXE="srcds_run"
ENV START_ARGS="-game left4dead2 -console +map c1m1_hotel +sv_allow_lobby_connect_only 0"
ENV INSTALL_SOURCEMOD="true"
ENV SOURCEMOD_MAJOR_VERSION="1.12"
ENV SOURCEMOD_VERSION="1.12.0-git7221"
ENV GAME_MOD="left4dead2"
ENV METAMOD_MAJOR_VERSION="1.12"
ENV METAMOD_VERSION="1.12.0-git1219"
ENV HTTP_FILESERVER_ENABLED="true"
ENV HTTP_FILESERVER_WEB_ROOT="/config/Merged/left4dead2"
ENV HTTP_FILESERVER_FILE_PATTERN="^/(maps|materials|models|sound)/.*\.(bz2|ztmp|bsp|nav|res|mdl|vvd|vtx|phy|ani|vmt|vtf|wav|mp3)$"

# ----------------------------
# Dependencies
# ----------------------------
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bzip2 \
    tar \
    unzip \
    xz-utils \
    p7zip-full \
    gosu \
  && rm -rf /var/lib/apt/lists/*

# Game traffic and server queries
EXPOSE 27015/udp
# RCON
EXPOSE 27015/tcp
# SourceTV
EXPOSE 27020/udp
# HTTP file server (FastDL)
EXPOSE 80/tcp

# COPY Modules/ "${BASE_MODULES}/"
COPY Hooks/ "${BASE_HOOKS}/"

USER lancommander

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]