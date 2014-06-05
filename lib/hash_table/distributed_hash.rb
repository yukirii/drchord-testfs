#encoding:utf-8

testfs_dir = File.expand_path(File.dirname(__FILE__))
require File.expand_path(File.join(testfs_dir, '/../config.rb'))
require File.expand_path(File.join(testfs_dir, '/hash_table.rb'))
require 'drb/drb'

module TestFS
  class DistributedHashTable < HashTableInterface
    def initialize(uri)
      @dht = DRbObject::new_with_uri(uri + "?dhash")
      alive_monitoring
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

    private
    def alive_monitoring
      Thread.new do
        loop do
          begin
            @dht.chord.active?
          rescue DRb::DRbConnError
            puts "Error: Connection failed - #{@dht.__drburi}"; exit
          end
          sleep TestFS::DHT_PING_INTERVAL
        end
      end
    end
  end
end
