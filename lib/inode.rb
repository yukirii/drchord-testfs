# encoding: utf-8

require 'uuidtools'
require 'Date'

class Inode
  attr_accessor :ino, :type, :size,
                :ctime, :mtime, :atime, :pointer
  def initialize(type, ino=nil)
    @ino = ino || UUIDTools::UUID.timestamp_create.hexdigest;
    @type = type;
    @size = 0;
    @ctime = DateTime.now;
    @mtime = DateTime.now;
    @atime = DateTime.now;
    @pointer = nil;
  end
end
