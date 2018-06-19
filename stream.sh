#!/bin/bash
SOURCE="https://upstream.passageenseine.fr/1080p.m3u8"
YOUTUBE_URL="rtmp://a.rtmp.youtube.com/live2"
TWITCH_URL="rtmp://live-cdg.twitch.tv/app"

ENCODING=(
	# -c:v libx264
	# 	-crf 23 -preset superfast
	# 	-sc_threshold 0 -g 250 -keyint_min 250
	# 	-b:v 5000k -maxrate 5350k -bufsize 7500k
	# 	-pix_fmt yuv420p
	# 	-movflags +faststart
	-c:v copy
	-c:a aac -b:a 160k
)

ffmpeg \
	-re -threads 0 -i "${SOURCE}" \
	"${ENCODING[@]}" -f flv "${YOUTUBE_URL}/${YOUTUBE_KEY}" \
	"${ENCODING[@]}" -f flv "${TWITCH_URL}/${TWITCH_KEY}"
	# -f tee -map 0:v -map 0:a \
	# "output.flv|[f=flv]${YOUTUBE_URL}/${YOUTUBE_KEY}|[f=flv]${TWITCH_URL}/${TWITCH_KEY}"
