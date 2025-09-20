FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
# 32bit 有効化＋最低限のユーティリティ
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg locales \
      cabextract p7zip-full unzip \
      winetricks \
      wine wine32 wine64 \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# ランタイムユーザー
ENV WINE_USER=wine WINE_UID=1000
RUN useradd -u $WINE_UID -d /home/wine -m -s /bin/bash $WINE_USER
USER wine
WORKDIR /home/wine

# 既定は win64（初期化は実行時に）
ENV WINEARCH=win64
ENV WINEPREFIX=/home/wine/.wine64
ENV WINEDEBUG=-all
RUN ln -sfn "$WINEPREFIX" /home/wine/.wine || true

# ユーティリティと MTGO セットアップ exe
COPY extra/host-webbrowser /usr/local/bin/xdg-open
COPY extra/live-mtgo /usr/local/bin/live-mtgo
COPY extra/mtgo.sh /usr/local/bin/mtgo
ADD --chown=wine:wine \
  https://mtgo.patch.daybreakgames.com/patch/mtg/live/client/setup.exe?v=8 \
  /opt/mtgo/mtgo.exe

# 実行時に初期化するので CMD だけ
CMD ["mtgo"]
