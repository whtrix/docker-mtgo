FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 基本ツール＋32bit対応＋winetricks
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg2 locales \
      cabextract p7zip-full unzip winetricks \
 && locale-gen en_US.UTF-8

# ---- Wine 8.0.4 を .deb で明示インストール（repoは追加しない）----
ARG WVER=8.0.4~jammy-1
WORKDIR /tmp/wine8
RUN set -eux; \
  base="https://dl.winehq.org/wine-builds/ubuntu/pool/main/w/wine-stable"; \
  curl -fLO "$base/wine-stable-amd64_${WVER}_amd64.deb"; \
  curl -fLO "$base/wine-stable-i386_${WVER}_i386.deb"; \
  curl -fLO "$base/wine-stable_${WVER}_amd64.deb"; \
  curl -fLO "$base/winehq-stable_${WVER}_amd64.deb"; \
  apt-get update; \
  # 依存は apt に解決させるが、インストール対象は 8.0.4 の .deb だけ
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
