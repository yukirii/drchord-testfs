#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
begin
  ENV['BUNDLE_GEMFILE'] = File.expand_path(File.join(testfs_dir, 'Gemfile'))
  require 'bundler/setup'
rescue LoadError
  puts "Error: 'bundler' not found. Please install it with `gem install bundler`."
  exit
end

require File.expand_path(File.join(testfs_dir, '/lib/testfs.rb'))
require 'rbfuse'
require 'json'

if ARGV.count <= 0
  puts "Error: Mount point not specified."
  puts "Usage: ruby testfs.rb mnt"
  exit
end

STDOUT.sync = true
STDERR.sync = true
RbFuse.debug = true
RbFuse.set_root(TestFS.new)
RbFuse.mount_under(ARGV.shift)
begin
  puts "TestFS Start"
  RbFuse.run
rescue Interrupt
  RbFuse.unmount
end
