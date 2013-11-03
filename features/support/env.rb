# encoding: utf-8
require 'aruba/cucumber'
require 'chukan'

Before do
  @features_root = File.expand_path('../../../', __FILE__)
  @dirs = [@features_root]
end

class FSManager
  include Chukan

  def run
    @fs = spawn("ruby testfs.rb mnt")
    @fs.stdout_join("TestFS Start")
  end

  def stop
    @fs.kill
    `umount mnt`
  end
end

fs_manager = FSManager.new
fs_manager.run
World do
  fs_manager
end

at_exit do
  fs_manager.stop
end
