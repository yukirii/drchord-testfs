# encoding: utf-8

require 'Date'

class Inode
  attr_accessor :ino, :type, :size,
                :ctime, :mtime, :atime, :pointer
  def initialize(ino, type, size=nil, pointer=nil)
    @ino = ino;
    @type = type;
    @size = size;
    @ctime = DateTime.now;
    @mtime = DateTime.now;
    @atime = DateTime.now;
    @pointer = pointer;
  end
end
