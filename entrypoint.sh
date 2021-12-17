service dbus start
service avahi-daemon start

export GST_DEBUG=0

# ./whip-client -u $URL -A "n.audio ! audioconvert ! audioresample ! audiobuffersplit output-buffer-duration=2/50 ! queue ! opusenc ! rtpopuspay pt=100 ssrc=1 ! queue ! application/x-rtp,media=audio,encoding-name=OPUS,payload=100" -V "ndisrc ndi-name=\"MEVO-23NNP\ \(Mevo-23NNP\)\" ! ndisrcdemux name=n n.video ! videoconvert ! vp8enc deadline=1 target-bitrate=500000 ! rtpvp8pay  mtu=1200 pt=96 ssrc=2 ! queue ! application/x-rtp,media=video,encoding-name=VP8,payload=96"

./whip-client -u $URL -V "ndisrc ndi-name=\"MEVO-23NNP\ \(Mevo-23NNP\)\" ! ndisrcdemux name=n n.audio ! queue ! audioconvert ! fakesink n.video ! videoconvert ! vp8enc deadline=1 target-bitrate=500000 ! rtpvp8pay  mtu=1200 pt=96 ssrc=2 ! queue ! application/x-rtp,media=video,encoding-name=VP8,payload=96"
