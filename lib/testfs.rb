#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/inode.rb'))
require File.expand_path(File.join(testfs_dir, '/dir_entry.rb'))
require File.expand_path(File.join(testfs_dir, '/file_data.rb'))
require 'rbfuse'
require 'zlib'

class TestFS < RbFuse::FuseDir
  attr_reader :hash_method
  def initialize
    @hash_method = lambda {|key| Zlib.crc32(key) }
    @table = {}
    @open_entries = {}
    create_root_dir
  end

  def store_hash_table(key, value)
    @table.store(hash_method.call(key), value)
  end

  def get_hash_table(key)
    return @table[hash_method.call(key)]
  end

  def delete_hash_table(key)
    @table.delete(hash_method.call(key))
  end

  def create_root_dir
    inode = Inode.new(:dir, "2")
    dir_entry = DirEntry.new
    inode.pointer = dir_entry.uuid
    store_hash_table(inode.ino, inode)
    store_hash_table(dir_entry.uuid, dir_entry)
  end

  def set_dir(path, dest_dir)
    dest_dir_name = File.basename(path)
    current_dir = get_dir_entry(path)
    if current_dir.has_key?(dest_dir_name)
      samename_uuid = current_dir[dest_dir_name]
      samename_inode = get_hash_table(samename_uuid)
      return false if samename_inode.type == :dir
    end

    dest_inode = Inode.new(:dir)
    dest_inode.pointer = dest_dir.uuid
    store_hash_table(dest_inode.ino, dest_inode)
    store_hash_table(dest_dir.uuid, dest_dir)

    current_dir.store(dest_dir_name, dest_inode.ino)
    store_hash_table(current_dir.uuid, current_dir)

    return true
  end

  def dir_entries(path)
    current_dir = get_dir_entry(path, false)
    return current_dir.keys
  end

  def get_file(path)
    filename = File.basename(path)
    current_dir = get_dir_entry(path)
    if current_dir.has_key?(filename)
      uuid = current_dir[filename]
      inode = get_hash_table(uuid)
      filedata = get_hash_table(inode.pointer)
      return filedata
    end
    return nil
  end

  def size(path)
    filedata = get_file(path)
    return filedata.value.bytesize
  end

  def file?(path)
    filename = File.basename(path)
    current_dir = get_dir_entry(path)
    if current_dir.has_key?(filename)
      uuid = current_dir[filename]
      inode = get_hash_table(uuid)
      return true if inode.type == :file
    end
    return false
  end

  def directory?(path)
    dirname = File.basename(path)
    current_dir = get_dir_entry(path)
    if current_dir.has_key?(dirname)
      uuid = current_dir[dirname]
      inode = get_hash_table(uuid)
      return true if inode.type == :dir
    end
    return false
  end

  def set_file(path, str)
    filename = File.basename(path)
    current_dir = get_dir_entry(path)

    if current_dir.has_key?(filename)
      inode = get_hash_table(current_dir[filename])
      file_data = get_hash_table(inode.pointer)
    else
      file_data = FileData.new
      inode = Inode.new(:file)
      inode.pointer = file_data.uuid
    end

    file_data.value = str
    inode.size = str.bytesize

    store_hash_table(inode.ino, inode)
    store_hash_table(file_data.uuid, file_data)

    current_dir.store(filename, inode.ino)
    store_hash_table(current_dir.uuid, current_dir)

    return true
  end

  def delete_file(path)
    filename = File.basename(path)
    current_dir = get_dir_entry(path)
    if current_dir.has_key?(filename)
      uuid = current_dir[filename]
      inode = get_hash_table(uuid)
      current_dir.delete(filename)
      delete_hash_table(uuid)
      delete_hash_table(inode.pointer)
      return true
    end
    return false
  end

  public
  def stat(path)
    getattr(path)
  end

  def delete(path)
    delete_file(path)
  end

  def readdir(path)
    entry = dir_entries(path)
    return entry.nil? ? [] : entry
  end

  def getattr(path)
    if file?(path)
      stat = RbFuse::Stat.file
      stat.size = size(path)
      return stat
    elsif directory?(path)
      return RbFuse::Stat.dir
    else
      return nil
    end
  end

  def open(path, mode, handle)
    buf = nil
    buf = get_file(path).value if mode =~ /r/
    buf ||= ""
    buf.encode("ASCII-8bit")

    @open_entries[handle] = [mode, buf]
    return true
  end

  def read(path, off, size, handle)
    @open_entries[handle][1][off, size]
  end

  def write(path, off, buf, handle)
    @open_entries[handle][1][off, buf.bytesize] = buf
  end

  def close(path, handle)
    return nil unless @open_entries[handle]
    set_file(path, @open_entries[handle][1])
    @open_entries.delete(handle)
  end

  def unlink(path)
    delete_file(path)
    true
  end

  def mkdir(path, mode)
    set_dir(path, DirEntry.new)
    return true
  end

  def rmdir(path)
    basename = File.basename(path)
    current_dir = get_dir_entry(path)
    deldir_inode = get_hash_table(current_dir[basename])
    remove_lower_dir(deldir_inode)
    current_dir.delete(basename)
    store_hash_table(current_dir.uuid, current_dir)
    return true
  end

  def remove_lower_dir(deldir_inode)
    dir_entry = get_hash_table(deldir_inode.pointer)
    dir_entry.each do |entry, uuid|
      inode = get_hash_table(uuid)
      remove_lower_dir(inode) if inode.type == :dir
      delete_hash_table(uuid)
      delete_hash_table(inode.pointer)
    end
    delete_hash_table(deldir_inode.ino)
    delete_hash_table(dir_entry.uuid)
  end


  def rename(path, destpath)
    parent_entry = get_dir_entry(path)
    target_uuid = parent_entry[File.basename(path)]

    parent_entry.delete(File.basename(path))
    store_hash_table(parent_entry.uuid, parent_entry)

    newparent_entry = get_dir_entry(destpath)
    newparent_entry.store(File.basename(destpath), target_uuid)
    store_hash_table(newparent_enrty.uuid, newparent_entry);

    return true
  end

  def get_dir_entry(path, split_path = true)
    path = File.dirname(path) if split_path == true
    root_inode = get_hash_table("2")
    current_dir = get_hash_table(root_inode.pointer)
    if path != '/'
      splited_path = path.split("/").reject{|x| x == "" }
      splited_path.each do |dir|
        return nil unless current_dir.has_key?(dir)
        current_inode = get_hash_table(current_dir[dir])
        current_dir = get_hash_table(current_inode.pointer)
      end
    end
    return current_dir
  end
end
