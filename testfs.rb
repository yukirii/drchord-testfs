#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
begin
  ENV['BUNDLE_GEMFILE'] = File.expand_path(File.join(testfs_dir, 'Gemfile'))
  require 'bundler/setup'
rescue LoadError
  puts "Error: 'bundler' not found. Please install it with `gem install bundler`."
  exit
end

if ARGV.count <= 0
  puts "Error: Mount point not specified."
  puts "Usage: ruby testfs.rb -d mnt"
  exit
end

require File.expand_path(File.join(testfs_dir, '/lib/testfs.rb'))
require 'rbfuse'

STDOUT.sync = true
if ARGV.count >= 2 && ARGV.shift == "-d"
  RbFuse.debug = true
  STDERR.sync = true
end

RbFuse.set_root(TestFS.new)
RbFuse.mount_under(ARGV.shift, "volname=TestFS")
begin
  puts "TestFS Start"
  RbFuse.run
rescue Interrupt
  RbFuse.unmount
end
