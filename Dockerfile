FROM debian:bookworm as ndi-builder

SHELL ["/bin/bash", "-c"]


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    wget -qO- https://downloads.ndi.tv/SDK/NDI_SDK_Linux/Install_NDI_Advanced_SDK_v5_Linux.tar.gz | tar xvz -C /tmp \
    && chmod +x /tmp/Install_NDI_Advanced_SDK_v5_Linux.sh \
    # && wget -qO- https://wr1apq.dm.files.1drv.com/y4mA7JaHY2idN_qptWJCLehp7nqS037IqjRod_gLCp22lMFlEx5jn3mXseoDgGHZ3MNGLjUFC00fzMlVU3VdLvZfcKh8Di5OMx9H5hVZEayGIXpn0jxhTJtaTyaXKc_vH8KFkkPdEEO17DwFB_jCuMfKgQIudx6HBud2sOpz25BSysBhUlrSw7h1scf2m-D9YFrhhF6gNsyTMmVS4aiIw9bNw | tar xvz -C /tmp \
    # && chmod +x /tmp/NDIHXDriverForLinux.sh \
    && PAGER=none /tmp/Install_NDI_Advanced_SDK_v5_Linux.sh <<< "Y" \
    && mv /tmp/NDI\ Advanced\ SDK\ for\ Linux /tmp/ndisdk \
    # && PAGER=none /tmp/NDIHXDriverForLinux.sh <<< "Y" \
    # && mv /tmp/NDIHXDriverForLinux /tmp/ndihxsdk \
    && cd /tmp/ndisdk && \
    export ARCH= && export DEST= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x86_64-linux-gnu' DEST='x86_64-linux-gnu';; \
      arm64) ARCH='aarch64-newtek-linux-gnu' DEST='aarch64-linux-gnu';; \
    #   armhf) ARCH='armv7l';; \
      i386) ARCH='x86_64-linux-gnu' DEST='x86_64-linux-gnu';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && cp /tmp/ndisdk/lib/${ARCH}/* /usr/lib/${DEST}/ && \
    # cp /tmp/ndihxsdk/x86_64-linux-gnu/* /tmp/ndisdk/lib/x86_64-linux-gnu/
    echo "done with ndi"

FROM debian:bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

RUN echo "deb https://www.deb-multimedia.org bookworm main non-free" >> /etc/apt/sources.list && \
  apt-get update -oAcquire::AllowInsecureRepositories=true \
  && apt-get install -y --no-install-recommends --allow-unauthenticated deb-multimedia-keyring

RUN apt-get update --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends \
        libnuma-dev \
        libx265-dev \
        x264 \
        x265 \
        wget \
        rust-all \
        vlc \
        libva-dev \
        libva-drm2 \
        vainfo \
        mesa-va-drivers \
        intel-media-va-driver \
        libopenh264-dev \
        libopenh264-6 \
        # libx264-164 \
        # libx264-dev \
        # libx265-199 \
        # libavcodec-extra \
        gdb \
        git \
        build-essential \
        devscripts \
        pkg-config \
        sudo \
        libc6-dev \
        ffmpeg \
        libavutil-dev \
        libavcodec-dev \
        libavformat-dev \
        libavutil \
        libavcodec \
        libavformat \
        libavdevice \
        libavfilter \
        libswscale \
        libswresample \
        avahi-daemon \
        avahi-utils \
        libnss-mdns \
        libavahi-common3 \
        libavahi-client3 \
        gstreamer1.0-vaapi \
        gstreamer1.0-tools \
        gstreamer1.0-nice \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-base-apps \
        libglib2.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        libsoup2.4-dev \
        libjson-glib-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-base-apps \
        gstreamer1.0-plugins-base \
        gstreamer1.0-libav && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

COPY --from=ndi-builder /tmp/ndisdk/ /tmp/ndisdk

RUN cd /tmp/ndisdk && \
    export ARCH= && export DEST= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x86_64-linux-gnu' DEST='x86_64-linux-gnu';; \
      arm64) ARCH='aarch64-newtek-linux-gnu' DEST='aarch64-linux-gnu';; \
    #   armhf) ARCH='armv7l';; \
      i386) ARCH='x86_64-linux-gnu';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && cp /tmp/ndisdk/lib/${ARCH}/* /usr/lib/${DEST}/ && rm -rf /tmp/ndisdk

RUN cd /tmp && \
    export ARCH= && export DEST= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x86_64-linux-gnu' DEST='x86_64-linux-gnu';; \
      arm64) ARCH='aarch64-linux-gnu' DEST='aarch64-linux-gnu';; \
    #   armhf) ARCH='armv7l';; \
      i386) ARCH='x86_64-linux-gnu';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && echo $ARCH && echo $DEST && \
    wget -qO- https://github.com/teltek/gst-plugin-ndi/archive/master.tar.gz | tar xvz -C /tmp && cd gst-plugin-ndi-master && \
    cargo build --release && sudo install -o root -g root -m 644 target/release/libgstndi.so /usr/lib/${DEST}/gstreamer-1.0/libgstndi.so && \
    sudo ldconfig

WORKDIR /opt/simple-whip-client

COPY . .

RUN make

WORKDIR /opt/simple-whip-client

ENV URL=http://localhost:3000/whip/foo

ENTRYPOINT service dbus start && service avahi-daemon start && export GST_DEBUG=0 && ./whip-client -u $URL -A "n.audio ! audioconvert ! audioresample ! audiobuffersplit output-buffer-duration=2/50 ! queue ! opusenc ! rtpopuspay pt=100 ssrc=1 ! queue ! application/x-rtp,media=audio,encoding-name=OPUS,payload=100" -V "ndisrc ndi-name=\"Mevo-23NL5\" ! ndisrcdemux name=n n.video ! videoconvert ! vp8enc deadline=1 target-bitrate=500000 ! rtpvp8pay pt=96 ssrc=2 ! queue ! application/x-rtp,media=video,encoding-name=VP8,payload=96"

# ENTRYPOINT ./whip-client -u $URL -A "audiotestsrc is-live=true wave=red-noise ! audioconvert ! audioresample ! queue ! opusenc ! rtpopuspay pt=100 ssrc=1 ! queue ! application/x-rtp,media=audio,encoding-name=OPUS,payload=100" -V "videotestsrc is-live=true pattern=ball ! videoconvert ! queue ! vp8enc deadline=1 ! rtpvp8pay pt=96 ssrc=2 ! queue ! application/x-rtp,media=video,encoding-name=VP8,payload=96" -S stun://stun.l.google.com:19302
