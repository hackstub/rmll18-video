#!/usr/bin/env bash
FFMPEG_DIR="$(readlink -e ~/ffmpeg)"
FFMPEG="${FFMPEG_DIR}/ffprobe"
for lib in libavutil libpostproc libswresample libavformat libavdevice libswscale libavresample libavfilter libavcodec; do LD_LIBRARY_PATH="${FFMPEG_DIR}/${lib}:${LD_LIBRARY_PATH}"; done
export LD_LIBRARY_PATH
"${FFMPEG}" "${@}"
