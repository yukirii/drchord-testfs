# encoding: utf-8

require './lib/testfs.rb'
require './lib/dir_entry.rb'
require './lib/inode.rb'
require 'spec_helper'
require 'uuidtools'
require 'zlib'
require 'pp'

describe TestFS do
  before do
    @testfs = TestFS.new
  end

  it "root directory の path を引数に渡すと uuid が 2 のエントリが追加される" do
      expect(@testfs.table.has_key?(Zlib.crc32("2"))).to be_true
  end

  describe "set_dir" do
  end

  describe "to_dirkey" do
    it "root directory の path を引数に渡すと directory_entry のオブジェクトが取得できる" do
      expect(@testfs.to_dirkey("/").class).to eq(DirEntry)
    end
  end
end
