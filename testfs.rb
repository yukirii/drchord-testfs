#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
begin
  ENV['BUNDLE_GEMFILE'] = File.expand_path(File.join(testfs_dir, 'Gemfile'))
  require 'bundler/setup'
rescue LoadError
  puts "Error: 'bundler' not found. Please install it with `gem install bundler`."
  exit
end

require 'rbfuse'
require 'json'

class TestFS < RbFuse::FuseDir
  def initialize
    @table = {}
    ent = dir_entries('/')
    if !ent
      set_dir('/', [])
    end
    @open_entries = {}
  end

  def set_dir(path, ary)
    @table[to_dirkey(path)] = JSON.dump(ary)
  end

  #ここおかしい
  def dir_entries(path)
    val = @table[to_dirkey(path)]
    val ? JSON.load(val) : nil
    #@table[to_dirkey(path)] ? JSON.load(val) : nil
  end

  def to_dirkey(path)
    return 'dir:' + path
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
    if file
      return file.bytesize
    else
      return 0
    end
  end

  def directory?(path)
    !!get_dir(path)
  end

  def set_file(path, str)
    @table[to_filekey(path)] = str
  end


  def delete_file(path)
    if(get_file(path))
      @table.delete(to_filekey(path))
      dirname = File.dirname(path)
      set_dir(dirname, dir_entries(dirname) - [File.basename(path)])
    end
  end

  public
  def readdir(path)
    ents = JSON.load(get_dir(path))
    ents||[]
  end

  def getattr(path)
    if(file?(path))
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
    if mode=~/r/
      buf = get_file(path)
    end
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
    @table[to_dirkey(path)] = JSON.dump([])
    filename = File.basename(path)
    parent_dir = File.dirname(path)
    
    if get_dir(filename).nil?
      files = [filename]
    else
      files = JSON.load(get_dir(filename))
    end
    @table[to_dirkey(File.dirname(path))] = JSON.dump(files)
    true
  end

  def rmdir(path)
   dirname = File.dirname(path)
   basename = File.basename(path)
   set_dir(dirname,JSON.load(get_dir(dirname)) - [basename])
   @table.delete(to_dirkey(path))
  end
end

RbFuse.debug = true
RbFuse.set_root(TestFS.new)
RbFuse.mount_under(ARGV.shift)
RbFuse.run
RbFuse.unmount
