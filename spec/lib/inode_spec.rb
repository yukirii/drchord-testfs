# encoding: utf-8

require './lib/inode.rb'
require 'spec_helper'
require 'uuidtools'

describe Inode do
  describe "UUID を引数として渡さない" do
    before do
      @inode = Inode.new(:dir)
    end

    it "UUID が自動生成される" do
        expect(@inode.ino).not_to be_nil
    end
  end

  describe "UUID を引数として渡す" do
    before do
      @inode = Inode.new(:dir, "2")
    end

    it "UUID が引数と一致するれる" do
        expect(@inode.ino).not_to be_nil
        expect(@inode.ino).to eq("2")
    end
  end
end
