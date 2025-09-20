FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# sources.list を明示的に上書き（main/contrib/non-free/non-free-firmware すべて有効）
RUN set -eux; \
  printf '%s\n' \
    'deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware' \
    'deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware' \
    'deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware' \
    > /etc/apt/sources.list

# 32bit 有効化＋必要パッケージ
RUN set -eux; \
  dpkg --add-architecture i386; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg locales \
    cabextract p7zip-full unzip \
    winetricks \
    wine wine64 wine32:i386; \
  locale-gen en_US.UTF-8; \
  rm -rf /var/lib/apt/lists/*

# ランタイムユーザー
ENV WINE_USER=wine WINE_UID=1000
RUN useradd -u $WINE_UID -d /home/wine -m -s /bin/bash $WINE_USER
USER wine
WORKDIR /home/wine

# 既定は win64（初期化は実行時）
ENV WINEARCH=win64
ENV WINEPREFIX=/home/wine/.wine64
ENV WINEDEBUG=-all
RUN ln -sfn "$WINEPREFIX" /home/wine/.wine || true

# ユーティリティと MTGO セットアップ
COPY extra/host-webbrowser /usr/local/bin/xdg-open
COPY extra/live-mtgo     /usr/local/bin/live-mtgo
COPY extra/mtgo.sh       /usr/local/bin/mtgo
ADD --chown=wine:wine \
  https://mtgo.patch.daybreakgames.com/patch/mtg/live/client/setup.exe?v=8 \
  /opt/mtgo/mtgo.exe

# 初期化は run 時に行う（ビルド中は wineboot/winetricks を走らせない）
CMD ["mtgo"]
