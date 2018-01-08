#!/usr/bin/env ruby
require '../converter.rb'

def extract(dir, conference)
	name = conference[:file]

	primary = File.join INPUT_DIRECTORY, dir, 'primary.mov'
	secondary = File.join INPUT_DIRECTORY, dir, 'secondary.mov'

	audio = File.join PASS1_DIRECTORY, "#{name}.wav"
	video = File.join PASS1_DIRECTORY, "#{name}.webm"
	video_primary = File.join PASS1_DIRECTORY, "#{name}-primary.webm"
	video_secondary = File.join PASS1_DIRECTORY, "#{name}-secondary.webm"

	from = conference[:from]
	to = conference[:to]
	to = Time.parse(to) - Time.parse(from) if from and to

	args = Args.new
	# Input
	args << ['-ss', from] if from
	args << ['-t', to] if to
	args << ['-i', primary]
	# Output audio
	args << %w(-vn) \
	<< FFMPEG[:audio][:wav] << audio
	# Output video
	args << %W(-an -vf scale=-1:#{RESOLUTION}) \
	<< FFMPEG[:video][RESOLUTION] << video_primary
	ffmpeg args if File.exists?(primary) and !File.exists?(audio, video_primary)

	args = Args.new
	# Input
	args << ['-ss', from] if from
	args << ['-t', to] if to
	args << ['-i', secondary] \
	<< %w(-an) \
	<< %W(-vf crop=1440:1080:240:0,scale=-1:#{RESOLUTION}) \
	<< FFMPEG[:video][RESOLUTION] \
	<< video_secondary
	ffmpeg args if File.exists?(secondary) and !File.exists?(video_secondary)

	params = <<-EOF
		nullsrc=size=1920x720 [base];
		[0:v] setpts=PTS-STARTPTS, scale=-1:#{RESOLUTION} [left];
		[1:v] setpts=PTS-STARTPTS, scale=-1:#{RESOLUTION} [right];
		[base][left] overlay=shortest=1 [tmp1];
		[tmp1][right] overlay=shortest=1:x=960
	EOF

	args = Args.new
	args << ['-i', video_primary] \
	<< ['-i', video_secondary] \
	<< '-filter_complex' << params \
	<< '-an' \
	<< FFMPEG[:video][RESOLUTION] \
	<< video
	ffmpeg args if File.exists?(video_primary, video_secondary) and !File.exists?(video)
end

process if __FILE__ == $0
