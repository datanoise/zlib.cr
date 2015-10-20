require "spec"
require "../src/zlib"

include Zlib

struct Slice
  def to_hex
    String.build do |o|
      each_with_index do |b, idx|
        o << b.to_s(16)
        o << " " unless idx == size - 1
      end
    end
  end

  def self.from_hex(string)
    ary = string.split(' ').map{|s| s.to_u8(16)}
    Slice.new(ary.to_unsafe, ary.size)
  end
end

describe ZStream do
  it "should be able to deflate" do
    deflate = Deflate.new(MemoryIO.new)
    deflate.state.should eq(ZStream::State::Ready)

    deflate.deflate("this is a test string !!!!\n")
    deflate.state.should eq(ZStream::State::InStream)
    deflate.finish
    deflate.state.should eq(ZStream::State::Finished)

    slice = Slice.new(deflate.io.buffer, deflate.io.bytesize)
    slice.to_hex.should eq("78 9c 2b c9 c8 2c 56 0 a2 44 85 92 d4 e2 12 85 e2 92 a2 cc bc 74 5 45 20 e0 2 0 85 4f 8 7b")
  end

  it "should be able to inflate" do
    inflate = Inflate.new(MemoryIO.new)
    inflate.state.should eq(ZStream::State::Ready)

    slice = Slice.from_hex("78 9c 2b c9 c8 2c 56 0 a2 44 85 92 d4 e2 12 85 e2 92 a2 cc bc 74 5 45 20 e0 2 0 85 4f 8 7b")
    inflate.inflate(slice[0, slice.size/2])
    inflate.state.should eq(ZStream::State::InStream)
    inflate << slice[slice.size/2, slice.size - slice.size/2]
    inflate.state.should eq(ZStream::State::Finished)
    inflate.io.to_s.should eq("this is a test string !!!!\n")
  end
end

