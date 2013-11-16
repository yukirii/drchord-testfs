# encoding: utf-8

class FileData
  attr_accessor :uuid, :value
  def initialize(value=nil)
    @uuid = UUIDTools::UUID.timestamp_create.hexdigest
    @value = value
  end
end
