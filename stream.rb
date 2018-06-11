#!/usr/bin/env ruby
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

COMMON = {
	audio: %w[
		-c:a aac
	],
	video: %w[
		-c:v libx264 -crf 23 -preset superfast
		-sc_threshold 0 -g 250 -keyint_min 250
		-pix_fmt yuv420p
	],
	hls: %w[
		-hls_time 10 -hls_list_size 5 -hls_flags delete_segments
		-use_localtime 1
		-movflags +faststart
		-threads 8
	]
}
HLS = {
	audio: COMMON[:hls] + COMMON[:audio],
	video: COMMON[:hls] + COMMON[:audio] + COMMON[:video]
}

VIDEO = {
	'audio' => HLS[:audio] + %w[
		-b:a 192k
		-vn
	],
	'360p' => HLS[:video] + %w[
		-vf scale=-1:360 -b:v 800k -maxrate 856k -bufsize 1200k
		-b:a 96k
	],
	'480p' => HLS[:video] + %w[
		-vf scale=854:480 -b:v 1400k -maxrate 1498k -bufsize 2100k
		-b:a 128k
	],
	'720p' => HLS[:video] + %w[
		-vf scale=-1:720 -b:v 2800k -maxrate 2996k -bufsize 4200k
		-b:a 128k
	],
	'1080p' => HLS[:video] + %w[
		-vf scale=-1:1080 -b:v 5000k -maxrate 5350k -bufsize 7500k
		-b:a 192k
	],
}.map do |k, v|
	v += [
		'-hls_base_url', "#{k}/",
		'-hls_segment_filename', "stream/#{k}/%s.ts",
		"stream/#{k}.m3u8"
	]
	[k, v]
end.to_h

VIDEO.keys.each do |type|
	output = File.join 'stream', type

	Dir.mkdir output unless Dir.exist? output

	ts = File.join output, '*.ts'
	ts = Dir[ts]
	ts.each { |f| File.unlink f }
end

timestamp = Time.now().strftime "%Y-%m-%dT%H:%M:%S"
VIDEO['video'] = COMMON[:audio] + COMMON[:video] + [
					# File.join('video', "#{timestamp}.ts")
					'video/output.ts'
				]

# INPUT=( -re -i "${1}" )
# INPUT=( -i ~/Workspace/pses/video/2017/output/zenzla-vie-privee-petits-sacrifices.webm )
# INPUT=( -i udp://@localhost:9999 )
# INPUT = %w[-f libndi_newtek -i ENDOR\ (OBS)]
INPUT = %w[-f libndi_newtek -i COW\ (OBS)]

# FFMPEG = 'ffmpeg'
FFMPEG = './ffmpeg.sh'

OUTPUT = VIDEO.keys
# OUTPUT = %w[video]

cmd = [ FFMPEG, '-y' ] + INPUT + OUTPUT.collect { |c| VIDEO[c] }.flatten
puts cmd.join ' '
exec *cmd
