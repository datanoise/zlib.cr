# zlib.cr

This library provides binding for ZLib library.

# Status

*Alpha*

# Requirements

- Crystal language version 0.9 and higher.
- zlib version 1.2.5 or higher

# Goal

Provide a simple API to handle Zlib Deflate/Inflate stream and GZFile API.

# Usage

An example of using GZFile API:

```crystal
Zlib::GZFile.open("output.gz", "w") do |f|
  f.puts "hello world!"
end
```

An example of deflating of a stream of data:

```crystal
File.open("data.txt", "r") do |src|
  File.open("data.txt.z", "w") do |dst|
    deflate = Zlib::Deflate.new(dst)

    IO.copy(src, deflate)
    deflate.finish
  end
end
```

and inflating it back:

```crystal
File.open("data.txt.z", "r") do |src|
  inflate = Zlib::Inflate.new(STDOUT)

  IO.copy(src, inflate)
end
```

# License

MIT clause - see LICENSE for more details.

