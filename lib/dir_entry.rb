# encoding: utf-8

module TestFS
  class DirEntry < Hash
    attr_accessor :uuid
    def initialize
      @uuid = UUIDTools::UUID.timestamp_create.hexdigest
    end
  end
end
