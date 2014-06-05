#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/cache_manager.rb'))

module TestFS
  class InodeCacheManager < CacheManager
    def store(inode)
      if @cache.count == @max_cache_size
        @cache.shift
      end
      @cache.store(inode.ino, inode)
    end
  end
end
