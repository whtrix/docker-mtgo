FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 基本ツール＋32bit対応＋winetricks
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg2 locales \
      cabextract p7zip-full unzip winetricks \
 && locale-gen en_US.UTF-8

# --- Wine 8.x (stable) を「その時点で存在する最新版」でインストール ---
# 重要: winehq の APT レポは追加しない（追加すると 10.x に上がる）
WORKDIR /tmp/wine8
RUN set -eux; \
  SUITE=jammy; \
  BASE="https://dl.winehq.org/wine-builds/ubuntu/pool/main/w/wine-stable"; \
  # 一覧から '8.' を含む最新版のバージョン名を拾う（例: 8.0.6~jammy-1）
  WVER="$(curl -fsSL "$BASE/" \
          | grep -oE "winehq-stable_8[^\"]+_${SUITE}-1_amd64\.deb" \
          | sed "s/^winehq-stable_//; s/_${SUITE}-1_amd64\.deb$//" \
          | sort -V | tail -1)~${SUITE}-1"; \
  echo "Picked Wine stable version: $WVER"; \
  for pkg in wine-stable-amd64 wine-stable-i386 wine-stable winehq-stable; do \
    arch=amd64; [ "$pkg" = "wine-stable-i386" ] && arch=i386; \
    curl -fLO "$BASE/${pkg}_${WVER}_${arch}.deb"; \
  done; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ./wine-stable-amd64_${WVER}_amd64.deb \
    ./wine-stable-i386_${WVER}_i386.deb \
    ./wine-stable_${WVER}_amd64.deb \
    ./winehq-stable_${WVER}_amd64.deb; \
  apt-mark hold winehq-stable wine-stable wine-stable-amd64 wine-stable-i386; \
  rm -rf /var/lib/apt/lists/* /tmp/wine8

# ランタイムユーザー
ENV WINE_USER=wine WINE_UID=1000
RUN useradd -u $WINE_UID -d /home/wine -m -s /bin/bash $WINE_USER
USER wine
WORKDIR /home/wine

# 既定は win64（初期化は実行時に行う）
ENV WINEARCH=win64
ENV WINEPREFIX=/home/wine/.wine64
ENV WINEDEBUG=-all
RUN ln -sfn "$WINEPREFIX" /home/wine/.wine || true

# あなたのファイル類
COPY extra/host-webbrowser /usr/local/bin/xdg-open
COPY extra/live-mtgo /usr/local/bin/live-mtgo
COPY extra/mtgo.sh /usr/local/bin/mtgo
ADD --chown=wine:wine https://mtgo.patch.daybreakgames.com/patch/mtg/live/client/setup.exe?v=8 /opt/mtgo/mtgo.exe

# 実行時初期化に任せる（ビルド中は wineboot / winetricks を走らせない）
CMD ["mtgo"]
