FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
# 依存 & 32bit有効化
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg2 locales \
      cabextract p7zip-full unzip \
      winetricks \
 && locale-gen en_US.UTF-8

# Wine 8.x stable を導入（jammy）
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key -o /etc/apt/keyrings/winehq.key \
 && printf "Types: deb\nURIs: https://dl.winehq.org/wine-builds/ubuntu/\nSuites: jammy\nComponents: main\nSigned-By: /etc/apt/keyrings/winehq.key\n" \
      > /etc/apt/sources.list.d/winehq.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      winehq-stable=8.0.4~jammy-1 || apt-get install -y --no-install-recommends winehq-stable \
 && rm -rf /var/lib/apt/lists/*

# ランタイムユーザー
ENV WINE_USER=wine WINE_UID=1000
RUN useradd -u $WINE_UID -d /home/wine -m -s /bin/bash $WINE_USER
USER wine
WORKDIR /home/wine

# 64bitプレフィックスを既定に（実行時に初期化する）
ENV WINEARCH=win64
ENV WINEPREFIX=/home/wine/.wine64
ENV WINEDEBUG=-all

# 互換シンボリック（後段が .wine を前提にしていても動くように）
RUN ln -sfn "$WINEPREFIX" /home/wine/.wine || true

# スクリプト類
COPY extra/host-webbrowser /usr/local/bin/xdg-open
COPY extra/live-mtgo /usr/local/bin/live-mtgo
COPY extra/mtgo.sh /usr/local/bin/mtgo

# MTGO セットアップ（実行時に使う）
ADD --chown=wine:wine \
  https://mtgo.patch.daybreakgames.com/patch/mtg/live/client/setup.exe?v=8 \
  /opt/mtgo/mtgo.exe

# ホストからレジストリをマウントする時の足場（WINEPREFIX対応）
RUN mkdir -p "$WINEPREFIX/host" \
 && ln -sf "$WINEPREFIX/host" "$WINEPREFIX/drive_c/users/wine/Documents" || true

# ここで wineboot / winetricks は実行しない（実行時にやる）
CMD ["mtgo"]
