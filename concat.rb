#!/usr/bin/env ruby
require 'tempfile'
require 'open3'

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
	args = %w(ffmpeg -y) + args
	p args
#  	Open3.popen3(*args) do |stdin, stdout, stderr, thread|
# 		$stdout.print stdout.read
# 		$stderr.print stderr.read
# 		{ out: [stdout, $stdout], err: [stderr, $stderr] }.each do |key, stream|
# 			input, output = stream
# 			Thread.new do
# 				p "starting #{key}"
# 				until (line = stream.gets).nil? do
# 					p "reading #{key}"
# 					output.puts line
# 				end
# 				p "end #{key}"
# 			end
# 		end
#
# 		thread.join
#  	end
	system *args
end

def concat(args)
	from = args[1..-1]
	to = args[0]
	Tempfile.open('concat') do |t|
		from.each { |f| t.puts "file '#{File.join Dir.pwd, f}'" }
		t.flush
		system 'cat', t.path
		ffmpeg Args.new << ['-f', 'concat', '-safe', 0, '-i', t.path, '-c', 'copy', to]
	end
	p from
	p to
end

concat ARGV
