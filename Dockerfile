FROM debian:bullseye AS builder

RUN apt-get update --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        devscripts \
        pkg-config \
        sudo \
        libc6-dev \
        gstreamer1.0-tools \
        gstreamer1.0-nice \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-plugins-good \
        libglib2.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        libsoup2.4-dev \
        libjson-glib-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-libav && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN mkdir simple-whip-client

# RUN git clone https://github.com/lminiero/simple-whip-client.git && cd simple-whip-client && make

COPY . simple-whip-client/

WORKDIR /opt/simple-whip-client

RUN make

ENV URL=http://docker.for.mac.host.internal:3000/ingest/whip/u5T7jByx1bm1f79Co0vI/2aK8Xjgri6UARuAmMNKp/foo

ENTRYPOINT ./whip-client --follow-link -u $URL -A "audiotestsrc is-live=true wave=red-noise ! audioconvert ! audioresample ! queue ! opusenc ! rtpopuspay pt=100 ssrc=1 ! queue ! application/x-rtp,media=audio,encoding-name=OPUS,payload=100" -V "videotestsrc is-live=true pattern=ball ! videoconvert ! queue ! vp8enc deadline=1 ! rtpvp8pay pt=96 ssrc=2 ! queue ! application/x-rtp,media=video,encoding-name=VP8,payload=96" -l 7 -p relay

# ENTRYPOINT gdb -ex=r --args ./whip-client --follow-link -u $URL -A "audiotestsrc is-live=true wave=red-noise ! audioconvert ! audioresample ! queue ! opusenc ! rtpopuspay pt=100 ssrc=1 ! queue ! application/x-rtp,media=audio,encoding-name=OPUS,payload=100" -V "videotestsrc is-live=true pattern=ball ! videoconvert ! queue ! vp8enc deadline=1 ! rtpvp8pay pt=96 ssrc=2 ! queue ! application/x-rtp,media=video,encoding-name=VP8,payload=96" -l 7

