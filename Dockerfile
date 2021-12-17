FROM debian:bookworm as ndi-builder

SHELL ["/bin/bash", "-c"]


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
    && export ARCH= && export DEST= && export HX_SCRIPT=NDIHXDriverForLinux dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x86_64-linux-gnu' DEST='x86_64-linux-gnu';; \
      arm64) ARCH='aarch64-newtek-linux-gnu' DEST='aarch64-linux-gnu' HX_SCRIPT='NDIHXDriverForLinuxARM';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && wget -qO- https://aib2da.dm.files.1drv.com/y4mNMVLPR6kiLPDThN01e4X8ZuVI1to6SVC1QpfcYZ9QeJOQPiicE7YUOl9ElmzCt5mU4Fs3zEu5Ewvievtdio2TpES8DRX2dMJOu-jjd8FRL3LX_N_Z_zL3_0n660YVBUGqlR7LhmKXEO8yecu74BJWaH56V2XHr21udUcRyZQyCw2QzkDJ8qcINRUhrhUYdSXDqi6-6QOo_7bokITQmRrUw | tar xvz -C /tmp \
    && wget -qO- https://wr1apq.dm.files.1drv.com/y4mA7JaHY2idN_qptWJCLehp7nqS037IqjRod_gLCp22lMFlEx5jn3mXseoDgGHZ3MNGLjUFC00fzMlVU3VdLvZfcKh8Di5OMx9H5hVZEayGIXpn0jxhTJtaTyaXKc_vH8KFkkPdEEO17DwFB_jCuMfKgQIudx6HBud2sOpz25BSysBhUlrSw7h1scf2m-D9YFrhhF6gNsyTMmVS4aiIw9bNw | tar xvz -C /tmp \
    && wget -qO- https://wh1apq.dm.files.1drv.com/y4mjjuDRKi9d7y6tEbIUC8PTi8gKaIRQCPCj4i-ORAKPWrSpnUWQgWp_yjl_fU9bfuGNo8qeSQ6EAJQOOqo3wml-l_ltQk2A9xEXG7cEBC93xjMuz-to4rqKcq-WLhUrn2dlA4giTW-4bTfQ5OJ44A2Xs1hy-x4pDEeeYnbqGgkmu5wIS70MDV10zHhxiAh6Yzf3Zzr1l0JOKrZ6n69xOUwuA | tar xvz -C /tmp \
    && chmod +x /tmp/Install_NDI_Advanced_SDK_v5_Linux.sh \
    && chmod +x /tmp/${HX_SCRIPT}.sh \
    && PAGER=none /tmp/Install_NDI_Advanced_SDK_v5_Linux.sh <<< "Y" \
    && mv  /tmp/NDI\ Advanced\ SDK\ for\ Linux /tmp/ndisdk \
    && PAGER=none /tmp/${HX_SCRIPT}.sh <<< "Y" \
    && mv /tmp/${HX_SCRIPT} /tmp/ndihxsdk \
    && cd /tmp/ndisdk \
    && cp /tmp/ndihxsdk/${ARCH}/* /tmp/ndisdk/lib/${ARCH}/ \
    && cp /tmp/ndisdk/lib/${ARCH}/* /usr/lib/${DEST}/ && \
    echo "done with ndi"

FROM debian:bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

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
        strace \
        # intel-media-va-driver \
        # libopenh264-dev \
        # libopenh264-6 \
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
        libavutil-dev \
        libavdevice-dev \
        libavfilter-dev \
        libswscale-dev \
        libswresample-dev \
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
      i386) ARCH='x86_64-linux-gnu';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && cp /tmp/ndisdk/lib/${ARCH}/* /usr/lib/${DEST}/ \
    && ldconfig && rm -rf /tmp/ndisdk && echo "done moving ndi"

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
    # cargo build --release && sudo install -o root -g root -m 644 target/release/libgstndi.so /usr/lib/${DEST}/gstreamer-1.0/libgstndi.so && \
    cargo build --release && sudo install -o root -g root -m 644 target/release/libgstndi.so /tmp/libgstndi.so && \
    sudo ldconfig

WORKDIR /opt/simple-whip-client

COPY . .

RUN make

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates

RUN apt-get update --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends \
        libnuma-dev \
        libx265-dev \
        x264 \
        x265 \
        wget \
        # rust-all \
        vlc \
        libva-dev \
        libva-drm2 \
        vainfo \
        mesa-va-drivers \
        strace \
        # intel-media-va-driver \
        # libopenh264-dev \
        # libopenh264-6 \
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
        libavutil-dev \
        libavdevice-dev \
        libavfilter-dev \
        libswscale-dev \
        libswresample-dev \
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
COPY --from=builder /tmp/libgstndi.so /tmp/libgstndi.so

RUN cd /tmp/ndisdk && \
    export ARCH= && export DEST= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x86_64-linux-gnu' DEST='x86_64-linux-gnu';; \
      arm64) ARCH='aarch64-newtek-linux-gnu' DEST='aarch64-linux-gnu';; \
      i386) ARCH='x86_64-linux-gnu';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && cp /tmp/ndisdk/lib/${ARCH}/* /usr/lib/${DEST}/ \
    && cp /tmp/libgstndi.so /usr/lib/${DEST}/gstreamer-1.0/libgstndi.so \
    && ldconfig \
    && cp /tmp/ndisdk/Version.txt /tmp/ndisdk/NDIVersion.txt \
    && rm -rf /tmp/ndisdk \
    && echo "done moving ndi"

WORKDIR /opt/simple-whip-client

COPY --from=builder /opt/simple-whip-client/whip-client  /opt/simple-whip-client/whip-client

COPY entrypoint.sh entrypoint.sh

RUN chmod +x entrypoint.sh

ENV URL=http://localhost:3000/whip/foo

ENTRYPOINT ./entrypoint.sh