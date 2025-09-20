FROM panard/wine:9.14-wow64
CMD mtgo

ENV WINE_USER wine
ENV WINE_UID 1000
ENV WINEPREFIX /home/wine/.wine
RUN useradd -u $WINE_UID -d /home/wine -m -s /bin/bash $WINE_USER
WORKDIR /home/wine

COPY extra/host-webbrowser /usr/local/bin/xdg-open
COPY extra/live-mtgo /usr/local/bin/live-mtgo

# ---- Wine 8.x stable を入れる（stagingを使っている場合の置き換え） ----
USER root
RUN dpkg --add-architecture i386 && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
      -o /etc/apt/keyrings/winehq.key && \
    printf "Types: deb\nURIs: https://dl.winehq.org/wine-builds/ubuntu/\nSuites: jammy\nComponents: main\nSigned-By: /etc/apt/keyrings/winehq.key\n" \
      > /etc/apt/sources.list.d/winehq.sources && \
    apt-get update && \
    # バージョン固定（失敗したら最新版の stable を入れるフォールバック）
    apt-get install -y --no-install-recommends \
      winehq-stable=8.0.4~jammy-1 || \
    (apt-get update && apt-get install -y --no-install-recommends winehq-stable) && \
    rm -rf /var/lib/apt/lists/*

USER wine

# 64bitプレフィックス（ダメなら win32 も試せるように）を明示
ENV WINEARCH=win64
ENV WINEPREFIX=/home/wine/.wine64
ENV WINEDEBUG=-all

RUN wineboot -i \
  && for f in arial32 times32 trebuc32 verdan32; do \
     curl -fL --output-dir /home/wine/.cache/winetricks/corefonts --create-dirs \
         -O https://github.com/pauleve/docker-mtgo/releases/download/artifacts/${f}.exe; done \
  && curl -fL --output-dir /home/wine/.cache/winetricks/PowerPointViewer --create-dirs \
         -O https://github.com/pauleve/docker-mtgo/releases/download/artifacts/PowerPointViewer.exe \
  && winetricks -q corefonts calibri tahoma \
  && taskset -c 0 winetricks -f -q dotnet48 \
  && winetricks win7 sound=alsa \
  && winetricks renderer=gdi \
  && wineboot -s \
  && rm -rf /home/wine/.cache

ENV WINEDEBUG -all,err+all,warn+chain,warn+cryptnet

COPY extra/mtgo.sh /usr/local/bin/mtgo

ADD --chown=wine:wine https://mtgo.patch.daybreakgames.com/patch/mtg/live/client/setup.exe?v=8 /opt/mtgo/mtgo.exe

USER wine

# hack to allow mounting of user.reg and system.reg from host
# see https://github.com/pauleve/docker-mtgo/issues/6
RUN cd .wine && mkdir host \
    && mv user.reg system.reg host/ \
    && ln -s host/*.reg .
RUN mkdir -p \
    /home/wine/.wine/drive_c/users/wine/Documents\
    /home/wine/.wine/host/wine/Documents
