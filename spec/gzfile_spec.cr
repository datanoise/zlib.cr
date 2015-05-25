require "spec"
require "../src/zlib"

describe Zlib::GZFile do
  it "it should be able to read and write gzfile" do
    file = Zlib::GZFile.new("output.gz", "w")
    file.puts "hello world!"
    file.close

    file = Zlib::GZFile.new("output.gz", "r")

    file.read_line.should eq("hello world!\n")
    file.close

    File.delete("output.gz")
  end
end
