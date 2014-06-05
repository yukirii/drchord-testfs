#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/hash_table.rb'))

module TestFS
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
end
