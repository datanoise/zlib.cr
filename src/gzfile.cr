class Zlib::GZFile
  include IO

  def initialize(@handle: LibZ::GZFile)
    raise ZlibError.new "invalid handle" unless @handle
    @closed = false
  end

  DEFAULT_CREATE_MODE = LibC::S_IRUSR | LibC::S_IWUSR | LibC::S_IRGRP | LibC::S_IROTH

  def initialize(filename, mode = "r")
    oflag = open_flag(mode)

    fd = LibC.open(filename, oflag, DEFAULT_CREATE_MODE)
    if fd < 0
      raise Errno.new("Error opening file '#{filename}' with mode '#{mode}'")
    end

    @path = filename
    initialize(LibZ.gzdopen(fd, mode))
  end

  def self.open(filename, mode)
    file = File.new(filename, mode)
    begin
      yield file
    ensure
      file.close
    end
  end

  protected def open_flag(mode)
    if mode.length == 0
      raise "invalid access mode #{mode}"
    end

    m = 0
    o = 0
    case mode[0]
    when 'r'
      m = LibC::O_RDONLY
    when 'w'
      m = LibC::O_WRONLY
      o = LibC::O_CREAT | LibC::O_TRUNC
    when 'a'
      m = LibC::O_WRONLY
      o = LibC::O_CREAT | LibC::O_APPEND
    else
      raise "invalid access mode #{mode}"
    end

    case mode.length
    when 1
      # Nothing
    when 2
      case mode[1]
      when '+'
        m = LibC::O_RDWR
      when 'b'
        # Nothing
      else
        raise "invalid access mode #{mode}"
      end
    else
      raise "invalid access mode #{mode}"
    end

    oflag = m | o
  end

  def close
    return if @closed
    @closed = true
    LibZ.gzclose(@handle).tap do |ret|
      check_error(ret)
    end
  end

  def finalize
    begin
      close
    rescue
    end
  end

  def buffer=(size)
    LibZ.gzbuffer(@handle, size)
  end

  def set_params(level, strategy)
    LibZ.gzsetparams(@handle, level, strategy)
  end

  def read(slice: Slice(UInt8), length)
    LibZ.gzread(@handle, slice.pointer(length), length.to_u32).tap do |ret|
      check_error(ret)
    end
  end

  def write(slice: Slice(UInt8), length)
    LibZ.gzwrite(@handle, slice.pointer(length), length.to_u32).tap do |ret|
      check_error(ret)
    end
  end

  def flush(flush = LibZ::Flush::FINISH)
    LibZ.gzflush(@handle, flush)
  end

  SEEK_SET = LibC::SEEK_SET
  SEEK_CUR = LibC::SEEK_CUR
  SEEK_END = LibC::SEEK_END

  def seek(offset: LibC::SizeT, whince = SEEK_CUR)
    LibZ.gzseek(@handle, offset, whince)
  end

  def rewind
    LibZ.gzrewind(@handle)
  end

  def tell
    LibZ.gztell(@handle)
  end

  def offset
    LibZ.gzoffset(@handle)
  end

  def eof?
    LibZ.gzeof(@handle) == 1
  end

  def direct?
    LibZ.gzdirect(@handle) == 1
  end

  private def check_error(ret)
    return unless ret == -1
    msg = LibZ.gzerror(@handle, out err)
    msg = String.new msg unless msg
    ZlibError.check_error(err, msg)
  end

  def to_unsafe
    @handle
  end
end
