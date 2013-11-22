# encoding: utf-8

module TestFS
  class FileData
    attr_accessor :uuid, :value
    def initialize(value="")
      @uuid = UUIDTools::UUID.timestamp_create.hexdigest
      @value = value
    end
  end
end
