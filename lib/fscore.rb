#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/utils.rb'))
require File.expand_path(File.join(testfs_dir, '/hash_table.rb'))
require File.expand_path(File.join(testfs_dir, '/data_structure/inode.rb'))
require File.expand_path(File.join(testfs_dir, '/data_structure/dir_entry.rb'))
require File.expand_path(File.join(testfs_dir, '/data_structure/file_data.rb'))
require 'rbfuse'
require 'zlib'

module TestFS
  class FSCore < RbFuse::FuseDir
    attr_reader :hash_method
    def initialize(config, option)
      if option[:p2p].nil?
        @table = HashTable.new(LocalHashTable.new)
      else
        @table = HashTable.new(DistributedHashTable.new(option[:p2p]))
      end
      @hash_method = Utils.get_hash_method(config["hash_func"])
      @open_entries = {}
      create_root_dir
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

    def file?(path)
      check_type(path, :file)
    end

    def directory?(path)
      check_type(path, :dir)
    end

    private
    # ハッシュテーブルに key, value を保存する
    # @param [String] key Value に対応付けるキー
    # @param [Object] value Key に対応付けられたオブジェクト
    def store_hash_table(key, value)
      @table.store(key, value)
    end

    # ハッシュテーブルからオブジェクトを取得する
    # @param [String] key Value に対応付けられたキー
    # @return [Object] Key に対応付けられたオブジェクト
    def get_hash_table(key)
      return @table.get(key)
    end

    # ハッシュテーブルからオブジェクトを削除する
    # @param [String] key Value に対応付けられたキー
    def delete_hash_table(key)
      @table.delete(key)
    end

    # ディレクトリ内のエントリ一覧を返す
    # @param [String] path 対象ディレクトリのパス
    # @return [Array] ディレクトリ内のファイル名一覧
    def dir_entries(path)
      current_dir = get_dir_entry(path, false)
      return current_dir.keys
    end

    # ファイルサイズを取得する
    # @param [String] path 対象ファイルのパス
    # @return [Fixnum] ファイルサイズ
    def size(path)
      filedata = get_file(path)
      return filedata.value.bytesize
    end

    # パスで指定したエントリが指定したタイプと同じか判定する
    # @param [String] path 対象のエントリを指すパス
    # @param [Symbol] type ファイルまたはディレクトリを現すシンボル
    # @return [boolean] 引数で指定した type と一致する場合 true, しない場合 false
    def check_type(path, type)
      dirname = File.basename(path)
      current_dir = get_dir_entry(path)
      if current_dir.has_key?(dirname)
        uuid = current_dir[dirname]
        inode = get_hash_table(uuid)
        return true if inode.type == type
      end
      return false
    end

    # ディレクトリエントリを取得する
    # @param [String] path 対象のディレクトリを指すパス
    # @param [boolean] split_path 引数で渡したパスを basename と dirname に分割する場合 true
    # @return [DirEntry] ディレクトリエントリ
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

    # 指定したディレクトリの子ディレクトリの内容を再帰的に削除する
    # @param [Inode] deldir_inode 対象のディレクトリの inode
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

    # ルートディレクトリの inode と ディレクトリエントリを作成する
    def create_root_dir
      inode = Inode.new(:dir, "2")
      dir_entry = DirEntry.new
      inode.pointer = dir_entry.uuid
      store_hash_table(inode.ino, inode)
      store_hash_table(dir_entry.uuid, dir_entry)
    end

    # ディレクトリの inode と ディレクトリエントリを作成する
    # @param [String] path 作成するディレクトリのパス
    # @param [DirEntry] dest_dir ディレクトリエントリ
    # @return [boolean]
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

    # ファイルの実体を取得する
    # @param [String] path 対象のファイルのパス
    # @return [FileData]
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

    # ファイルの inode と ファイルの実体を作成する
    # @param [String] path 対象のファイルのパス
    # @param [String] str 作成するファイルの内容を表すバイト列
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

    # ファイルを削除する
    # @param [String] path 対象のファイルのパス
    # @return [boolean]
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
  end
end
