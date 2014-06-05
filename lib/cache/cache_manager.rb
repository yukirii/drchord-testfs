#encoding:utf-8

module TestFS
  class CacheManager
    def initialize(max_size)
      @max_cache_size = max_size
      @cache = {}
    end

    def store(inode); end

    def has_cache?(ino)
      return @cache.has_key?(ino)
    end

    def get(ino)
      return @cache[ino]
    end

    def delete(ino)
      @cache.delete(ino)
    end
  end
end
