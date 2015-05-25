# zlib.cr

This library provides binding for ZLib library.

# Status

*Alpha*

# Requirements

- Crystal language version 0.7.1 and higher.
- zlib version 1.2.5 or higher

# Goal

Provide a simple API to handle Zlib Deflate/Inflate stream and GZFile API.

# Usage

An example of using GZFile API:

```crystal
Zlib::GZFile.new("output.gz", "w") do |f|
f.puts "hello world!"
end
```

An example of deflating of a stream of data:

```crystal
File.open("data.txt", "r") do |src|
  File.open("data.txt.z", "w") do |dst|
    deflate = Zlib::Deflate.new(dst)

    buffer :: UInt8[1024]
    while (len = src.read(buffer.to_slice)) > 0
      deflate << buffer.to_slice[0,len.to_i32]
    end

    deflate.finish
  end
end
```

and inflating it back:

```crystal
File.open("data.txt.z", "w") do |src|
  inflate = Zlib::Inflate.new(STDOUT)

  buffer :: UInt8[1024]
  while (len = src.read(buffer.to_slice)) > 0
    inflate << buffer.to_slice[0,len.to_i32]
  end
end
```

# License

MIT clause - see LICENSE for more details.

