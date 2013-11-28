#encoding:utf-8

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
end
