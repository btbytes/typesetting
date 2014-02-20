#!/usr/bin/env ruby

require "optparse"
require_relative 'lib/otfinstall'


o=OTFInstall.new
o.basedir=Dir.pwd + "/texmf"

dummy = `otfinfo --version`
unless $?.success? 
  puts "Are the lcdf typetools installed? I can't find the program 'otfinfo'"
  exit(-1)
end



ARGV.options do |opt|
  opt.version = "0.4"
  opt.banner = "Usage: otfinst <fontdescription.oinst>"
  opt.on('-b DIR','--basedir', 'Set basedir where texmf is located. Default', 'is the current directory') do |d|
    o.basedir=d
  end
  opt.on('-f DIR','--fontbase', 'Set basedirectory for otf-fonts. If set, it', 'will look in vendor/collection for the fontfiles') do |d|
    o.fontbase=d
  end
  opt.parse!
end

unless ARGV.size == 1
  puts "Error: otfinst needs exactly one argument. See otfinst -h for help."
  exit -1
end

oinstfile=ARGV[0].chomp('.oinst') + '.oinst'

begin
  o.read_otfinstr(ARGV[0])
rescue Errno::ENOENT => e
  puts "Error: Cannot find the file #{oinstfile}"
  exit(-1)
end

