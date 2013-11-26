#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/utils.rb'))
require 'drb/drb'

module TestFS
  class HashTable
    def initialize(hashtable)
      @table = hashtable
    end

    def store(key, value)
      @table.store(key, value)
    end

    def get(key)
      return @table.get(key)
    end

    def delete(key)
      @table.delete(key)
    end
  end

  class HashTableInterface
    def store(key, value); end
    def get(key); end
    def delete(key); end
  end

  class LocalHashTable < HashTableInterface
    def initialize
      @table = {}
    end

    def store(key, value)
      @table.store(key, value)
    end

    def get(key)
      return @table[key]
    end

    def delete(key)
      @table.delete(key)
    end
  end

  class DistributedHashTable < HashTableInterface
    def initialize(uri)
      @dht = DRbObject::new_with_uri(uri + "?dhash")
    end

    def store(key, value)
      candidates_list = @dht.lookup_roots(key)
      root = candidates_list.first
      return DRbObject::new_with_uri(root).put(key, value)
    end

    def get(key)
      candidates_list = @dht.lookup_roots(key)
      root = candidates_list.first
      return DRbObject::new_with_uri(root).get(key)
    end

    def delete(key)
      @dht.delete(key)
    end
  end
end
