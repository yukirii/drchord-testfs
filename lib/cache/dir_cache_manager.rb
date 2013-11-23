#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/cache_manager.rb'))

module TestFS
  class DirCacheManager < CacheManager
    def store(direntry)
      if @cache.count == @max_cache_size
        @cache.shift
      end
      @cache.store(direntry.uuid, direntry)
    end
  end
end
