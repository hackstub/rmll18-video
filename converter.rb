#!/usr/bin/env ruby
require 'nokogiri'
require 'tempfile'
require 'time'
require 'awesome_print'

RESOLUTION = 720
AUDIO_FREQUENCY = 48000

ROOT_DIRECTORY = File.expand_path '.'
INPUT_DIRECTORY = File.join ROOT_DIRECTORY, 'input'
PASS1_DIRECTORY = File.join ROOT_DIRECTORY, 'pass1'
PASS2_DIRECTORY = File.join ROOT_DIRECTORY, 'pass2'
OUTPUT_DIRECTORY = File.join ROOT_DIRECTORY, 'output'

[PASS1_DIRECTORY, PASS2_DIRECTORY, OUTPUT_DIRECTORY].each do |dir|
	Dir.mkdir dir unless Dir.exists? dir
end

CONFIG = eval File.read File.join 'input', "#{ARGV[0]}.rb"

FFMPEG = {
		  audio: {
				vorbis: %w(-strict -2 -codec:a vorbis -b:a 128k -ac 2),
				wav: %W(-acodec pcm_s16le -ar #{AUDIO_FREQUENCY} -ac 1)
		  },
		  video: {
			  480 => %w(-codec:v libvpx -auto-alt-ref 0 -b:v 600k -maxrate 600k -bufsize 1200k -qmin 10 -qmax 42),
			  576 => %w(-codec:v libvpx -auto-alt-ref 0 -b:v 1000k -maxrate 1000k -bufsize 2000k -qmin 10 -qmax 42),
			  720 => %w(-codec:v libvpx -auto-alt-ref 0 -b:v 2000k -maxrate 2000k -bufsize 4000k -qmin 10 -qmax 42)
		  }
}

class File
	class <<self
		alias_method :exists_old?, :exists?
	end

	def self.exists?(*args)
		args.all? { |f| self.exists_old? f }
	end
end

class Args
	def initialize
		@args = []
	end

	def <<(args)
		case (args)
			when Array then
				@args += args.collect { |a| a.to_s }
			else
				@args << args.to_s
		end
		self
	end

	def to_a
		@args
	end
end

def ffmpeg(args)
	args = args.to_a
	args = %w(ffmpeg -y -hide_banner) + args
	#args = %w(avconv -y) + args
	puts args.join ' '
	unless system *args
		puts args.join ' '
		exit -1
	end
end

def generate_svg_begin(conference)
    """
    Generate the begin svg from a template
    """
	name = conference[:file]
	begin_ = File.join INPUT_DIRECTORY, 'begin.svg'
	svg = File.join PASS1_DIRECTORY, "#{name}.svg"
	return if File.exists?(svg)

	licence = conference[:licence] || 'Licence CC-BY-SA'
	location = conference[:location]
	author = conference[:author]
	title = conference[:title]

	xml = File.open(begin_) { |f| Nokogiri::XML f }
	xml.at_css('#title tspan').content = title
	xml.at_css('#location').content = location
	xml.at_css('#author tspan').content = author
	xml.at_css('#licence tspan').content = licence if licence
	File.write svg, xml.to_xml
end

def generate_video_from_image(image, video, duration=5)
	ffmpeg Args.new << %w(-loop 1 -f image2 -i) << image \
				<< %W(-acodec pcm_s16le -f s16le -ac 2 -ar #{AUDIO_FREQUENCY} -i /dev/zero) \
				<< ['-t', duration] \
				<< %w(-map 0:0 -map 1:0) \
				<< %W(-vf setdar=4/3,setsar=16/15,scale=-1:#{RESOLUTION}) \
				<< FFMPEG[:video][RESOLUTION] \
 				<< FFMPEG[:audio][:vorbis] << video
end

def generate_video_from_svg(svg, video, duration=5)
	svg = File.join PASS1_DIRECTORY, "#{name}.svg"
	png = File.join PASS2_DIRECTORY, "#{name}.png"
	title = File.join PASS2_DIRECTORY, "#{name}-title.webm"

	system('inkscape', '-e', png, svg) unless File.exists?(png)
	generate_video_from_image png, title, duration unless File.exists?(title)
end

def generate_video_begin(conference, duration=5)
	name = conference[:file]
	svg = File.join PASS1_DIRECTORY, "#{name}.svg"
	png = File.join PASS2_DIRECTORY, "#{name}.png"
	title = File.join PASS2_DIRECTORY, "#{name}-title.webm"

	system('inkscape', '-e', png, svg) unless File.exists?(png)
	generate_video_from_image png, title, duration unless File.exists?(title)
end

def generate_video_end(duration=5)
    """
    Generate a video of 5s (by default) with the image end.svg
    """
	svg = File.join INPUT_DIRECTORY, "end.svg"
	png = File.join PASS2_DIRECTORY, 'end.png'
	video = File.join PASS2_DIRECTORY, 'end.webm'
	return if File.exists?(video)
	system 'inkscape', '-e', png, svg unless File.exists? png

	generate_video_from_image png, video, duration
end

def extract(conference)
    """
    Extract audio and video separately from the input video
    """
	name = conference[:file]

	input = File.join INPUT_DIRECTORY, "#{name}.webm"
	full = File.join PASS1_DIRECTORY, "#{name}-full.webm"
	audio = File.join PASS1_DIRECTORY, "#{name}.wav"
	video = File.join PASS1_DIRECTORY, "#{name}.webm"
	#return if File.exists?(audio, video)

	from = conference[:from]
	to = conference[:to]
	to = Time.parse(to) - Time.parse(from) if from and to

	args = Args.new
	# Input
	args << ['-ss', from] if from
	args << ['-t', to] if to
	args << ['-i', input]
	args << %w[-codec:v copy -codec:a copy]
	args << full
	ffmpeg args unless File.exists? full

	args = Args.new
	# Input
	args << ['-i', full]
	# Output 1 : audio
	args << %w(-vn -ac 1)
	args << audio
	# Output 2 : video
	args << %W(-an -codec:v copy)
	args << video
	ffmpeg args unless File.exists?(audio, video)
end

def merge(conference)
    """
    Merge audio and video together
    """
	name = conference[:file]

	audio = File.join PASS1_DIRECTORY, "#{name}.wav"
	video = File.join PASS1_DIRECTORY, "#{name}.webm"
	output = File.join PASS2_DIRECTORY, "#{name}.webm"
	return if File.exists?(output)

	ffmpeg Args.new << ['-i', audio, '-i', video] \
	 << FFMPEG[:audio][:vorbis] << %w(-codec:v copy) << output
end

def concat(conference)
	name = conference[:file]

	begin_ = File.join PASS2_DIRECTORY, "#{name}-title.webm"
	video = File.join PASS2_DIRECTORY, "#{name}.webm"
	end_ = File.join PASS2_DIRECTORY, 'end.webm'
	output = File.join OUTPUT_DIRECTORY, "#{name}.webm"
	return if !File.exists?(begin_, video, end_) or File.exists?(output)

	Tempfile.create 'concat' do |f|
		f.puts [begin_, video, end_].collect  { |f| "file #{f}" }
		f.flush
		ffmpeg Args.new << ['-f', 'concat', '-safe', '0', '-i', f.path, '-c', 'copy', output]
	end
end

def process
	generate_video_end
	CONFIG.each do |conference|
		case ARGV[1].to_sym
		when :pass1
			generate_svg_begin conference
			extract conference
			# Edit SVG if necessary
			# Normalize WAV
		when :pass2
			merge conference
			generate_video_begin conference
			concat conference
		end
	end
end

process if __FILE__ == $0
#generate_video_from_image 'pass2/malicia_sexe-heure-numerique-warning.png', 'pass2/malicia_sexe-heure-numerique-warning.webm'
