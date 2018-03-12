#!/bin/bash

# Preset:
#    ultrafast
#    superfast
#    veryfast
#    faster
#    fast
#    medium – default preset
#    slow
#    slower
#    veryslow
# Tune:
#    film – use for high quality movie content; lowers deblocking
#    animation – good for cartoons; uses higher deblocking and more reference frames
#    grain – preserves the grain structure in old, grainy film material
#    stillimage – good for slideshow-like content
#    fastdecode – allows faster decoding by disabling certain filters
#    zerolatency – good for fast encoding and low-latency streaming
#    psnr – ignore this as it is only used for codec development
#    ssim – ignore this as it is only used for codec development

# -profile:v baseline -level 3.0
# -c:a aac -ar 48000

COMMON=( -c:a aac
		-c:v libx264 -crf 23 -preset superfast
		-sc_threshold 0 -g 250 -keyint_min 250 -hls_time 10 -hls_list_size 5 -hls_flags delete_segments
		-use_localtime 1 -threads 8
		-movflags +faststart
		-pix_fmt yuv420p )

P360=( "${COMMON[@]}" -vf scale=-1:360 -b:v 800k -maxrate 856k -bufsize 1200k -b:a 96k )
P480=( "${COMMON[@]}" -vf scale=854:480 -b:v 1400k -maxrate 1498k -bufsize 2100k -b:a 128k )
P720=( "${COMMON[@]}" -vf scale=-1:720 -b:v 2800k -maxrate 2996k -bufsize 4200k -b:a 128k )
P1080=( "${COMMON[@]}" -vf scale=-1:1080 -b:v 5000k -maxrate 5350k -bufsize 7500k -b:a 192k )


INPUT=( -re -i "${1}" )
# INPUT=( -i ~/Workspace/pses/video/2017/output/zenzla-vie-privee-petits-sacrifices.webm )
# INPUT=( -i udp://@localhost:9999 )
# INPUT=( -f libndi_newtek -i "HOME (OBS)" )

FFMPEG=ffmpeg
# FFMPEG_DIR="$(readlink -e ~/Workspace/external/ffmpeg)"
# FFMPEG="${FFMPEG_DIR}/ffmpeg"
# for lib in libavutil libpostproc libswresample libavformat libavdevice libswscale libavresample libavfilter libavcodec; do LD_LIBRARY_PATH="${FFMPEG_DIR}/${lib}:${LD_LIBRARY_PATH}"; done
# export LD_LIBRARY_PATH

mkdir -p video stream/360p stream/480p stream/720p stream/1080p

"${FFMPEG}" "${INPUT[@]}" \
	"${P1080[@]}" "video/$(date +%Y%m%d-%H%M%S).ts" \
	"${P360[@]}"  -hls_base_url 360p/  -hls_segment_filename stream/360p/%s.ts stream/360p.m3u8 \
	"${P480[@]}"  -hls_base_url 480p/  -hls_segment_filename stream/480p/%s.ts stream/480p.m3u8 \
	"${P720[@]}"  -hls_base_url 720p/  -hls_segment_filename stream/720p/%s.ts stream/720p.m3u8 \
	"${P1080[@]}" -hls_base_url 1080p/ -hls_segment_filename stream/1080p/%s.ts stream/1080p.m3u8 \
