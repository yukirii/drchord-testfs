#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/fscore.rb'))
require 'rbfuse'
require 'optparse'

module TestFS
  class Front
    def run
      option = option_parser(default_options)
      mnt_point = ARGV[0]

      STDOUT.sync = true
      if option[:debug] == true
        RbFuse.debug = true
        STDERR.sync = true
      end

      config = {:fuse_opts => []}
      fuse_opts = config[:fuse_opts]

      RbFuse.set_root(TestFS::FSCore.new)
      RbFuse.mount_under(mnt_point, *fuse_opts)
      begin
        puts "TestFS Start"
        RbFuse.run
      rescue Interrupt
        RbFuse.unmount
      end
    end

    private
    def default_options
      return {:debug => false, :p2p => nil}
    end

    def check_argv
      return false if ARGV.count == 0
      if ARGV[0] == '-h' || ARGV[0] == '--help'
        return true
      else
        return false if File.exist?(ARGV[0]) == false || (File.exist?(ARGV[0]) && File::ftype(ARGV[0]) != "directory")
      end
      return true
    end

    def option_parser(options)
      usage = "Usage: ruby #{File.basename($0)} mount_point [options]"

      if check_argv == false
        puts "Error: Mount point not specified."
        puts usage
        exit
      end

      OptionParser.new do |opt|
        opt.banner = usage
        opt.on('-d', '--debug', 'enable show debug massage') { options[:debug] = true }
        opt.on('-p IP_ADDR:PORT', '--p2p IP_ADDR:PORT', 'use P2P network') {|v| options[:p2p] = "druby://#{v}" }
        opt.on_tail('-h', '--help', 'show this message') { puts opt; exit }
        begin
          opt.parse!
        rescue OptionParser::InvalidOption
          puts "Error: Invalid option. \n#{opt}"; exit
        rescue OptionParser::MissingArgument
          puts "Error: MissingArgument. \n#{opt}"; exit
        end
      end
      return options
    end
  end
end
