# encoding: utf-8

class DirEntry < Hash
  attr_accessor :uuid
  def initialize
    @uuid = UUIDTools::UUID.timestamp_create.hexdigest
  end
end
