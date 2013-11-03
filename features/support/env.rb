# encoding: utf-8
require 'aruba/cucumber'
require 'chukan'
include Chukan

Before do
  @features_root = File.expand_path('../../../', __FILE__)
  @dirs = [@features_root]
end

class FSManager
  def initialize
  end

  def run
    p "run"
  end

  def stop
    p "stop"
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
