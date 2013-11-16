#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/inode.rb'))
require 'uuidtools'
require 'rbfuse'
require 'zlib'
require 'json'
require 'kconv'
require 'pp'

class TestFS < RbFuse::FuseDir
  attr_reader :hash_method
  def initialize
    @hash_method = lambda {|key| Zlib.crc32(key) }

    @table = {}
    entries = dir_entries('/')
    set_dir('/', []) if !entries
    @open_entries = {}
  end

  def set_dir(path, ary)
    if path == '/'
      inode = Inode.new("2", :dir)
    else
      inode = Inode.new(UUIDTools::UUID.timestamp_create.hexdigest, :dir)
    end

    dir_entry_uuid = UUIDTools::UUID.timestamp_create.hexdigest
    inode.pointer = dir_entry_uuid

    # store inode
    @table.store(hash_method.call(inode.ino), inode)
    # store directory entry
    @table.store(hash_method.call(dir_entry_uuid), JSON.dump(ary))

    pp @table
  end

  def dir_entries(path)
    val = @table[to_dirkey(path)]
    val ? JSON.load(val) : nil
  end

  def to_dirkey(path)
    if path == '/'
      key = "2"
    else
    end

    #return 'dir:' + path
    return Zlib.crc32(key)
  end

  def to_filekey(path)
    return "file:"+path
  end

  def get_dir(path)
    @table[to_dirkey(path)]
  end

  def get_file(path)
    @table[to_filekey(path)]
  end

  def file?(path)
    !!get_file(path)
  end

  def size(path)
    file = get_file(path)
    return file ? file.bytesize : 0
  end

  def directory?(path)
    !!get_dir(path)
  end

  def set_file(path, str)
    @table[to_filekey(path)] = str
  end

  def delete_file(path)
    if get_file(path)
      @table.delete(to_filekey(path))
      dirname = File.dirname(path)
      set_dir(dirname, dir_entries(dirname) - [File.basename(path)])
    end
  end

  public
  def stat(path)
    getattr(path)
  end

  def delete(path)
    delete_file(path)
  end

  def readdir(path)
    ents = JSON.load(get_dir(path))
    ents||[]
  end

  def getattr(path)
    if file?(path)
      stat = RbFuse::Stat.file
      stat.size = size(path)
      return stat
    elsif(directory?(path))
      return RbFuse::Stat.dir
    else
      return nil
    end
  end

  def open(path, mode, handle)
    buf = nil
    buf = get_file(path) if mode=~/r/
    buf||=""
    buf.encode("ASCII-8bit")

    @open_entries[handle] = [mode,buf]
    return true
  end

  def read(path, off, size, handle)
    @open_entries[handle][1][off, size]
  end

  def write(path, off, buf, handle)
    @open_entries[handle][1][off,buf.bytesize] = buf
  end

  def close(path, handle)
    return nil unless @open_entries[handle]
    set_file(path, @open_entries[handle][1])

    @open_entries.delete(handle)
    dir = File.dirname(path)
    files = JSON.load(get_dir(dir))
    set_dir(dir,files|[File.basename(path)])
  end

  def unlink(path)
    delete_file(path)
    true
  end

  def mkdir(path, mode)
    @table[to_dirkey(path)]=JSON.dump([])
    filename=File.basename(path.toutf8)
    parent_dir=File.dirname(path)
    files=JSON.load(get_dir(parent_dir))|[filename]
    @table[to_dirkey(File.dirname(path))]=JSON.dump(files)
    true
  end

  def rmdir(path)
   dirname = File.dirname(path.toutf8)
   basename = File.basename(path)
   set_dir(dirname,JSON.load(get_dir(dirname)) - [basename.toutf8])
   @table.delete(to_dirkey(path))
  end

  def rename(path, destpath)
    if directory?(path)
      @table[to_dirkey(destpath)] = @table[to_dirkey(path)]
      filename = File.basename(destpath.toutf8)
      parent_dir = File.dirname(destpath)
      files = JSON.load(get_dir(parent_dir)) | [filename]
      @table[to_dirkey(File.dirname(destpath))] = JSON.dump(files)

      tmp = {}
      @table.each do |key, value|
        if key =~ /^file:.*/
          path_only = key[5..key.length]
          new_key = "file:"
        elsif key =~ /^dir:.*/
          path_only = key[4..key.length]
          new_key = "dir:"
        end

        if path_only[0..path.length-1] == path
          rest = path_only[path.length..path_only.length]
          new_key += destpath + rest

          tmp.store(new_key, value)
          @table.reject!{|k, v| k == key }
        end
      end
      @table.merge!(tmp)

      rmdir(path)
      return true
    else
      super(path, destpath)
    end
  end
end
