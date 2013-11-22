# encoding: utf-8

require 'digest/sha1'
require 'digest/md5'
require 'zlib'

module TestFS
  class Utils
    def self.get_hash_method(method)
      case (method)
      when :crc32
        return lambda {|key| Zlib.crc32(key) }
      when :md5
        return lambda {|key| Digest::MD5.hexdigest(key).hex }
      when :sha1
        return lambda {|key| Digest::SHA1.hexdigest(key).hex }
      end
    end
  end
end
