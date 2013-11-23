#encoding:utf-8

module TestFS
  class InodeCacheManager
    def initialize(max_size)
      @max_cache_size = max_size
      @cache = {}
    end


    def has_cache?(ino)
      return @cache.has_key?(ino)
    end

    def store(inode)
      if @cache.count == @max_cache_size
        @cache.shift
      end
      @cache.store(inode.ino, inode)
    end

    def get(ino)
      return @cache[ino]
    end

    def delete(ino)
      @cache.delete(ino)
    end
  end
end
