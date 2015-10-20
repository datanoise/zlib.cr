require "./zstream"

module Zlib
  class Deflate < ZStream
    def initialize(io, level = LibZ::DEFAULT_COMPRESSION, wbits = LibZ::MAX_BITS,
                   mem_level = LibZ::DEF_MEM_LEVEL, strategy = LibZ::Strategy::DEFAULT_STRATEGY)
      super(io)
      ret = LibZ.deflateInit2(self, level, LibZ::Z_DEFLATED, wbits, mem_level,
                              strategy, LibZ.zlibVersion(), sizeof(LibZ::ZStream))
      check_error(ret)
    end

    def deflate(data, flush = LibZ::Flush::NO_FLUSH : LibZ::Flush)
      if !data || flush == LibZ::Flush::FINISH
        finish(data)
        return
      end

      data = data.to_slice
      case @state
      when State::Ready
        @state = State::InStream
      when State::InStream
      else
        raise ZlibError.new "Invalid state #{@state}"
      end
      @state = State::InStream
      run(data, flush)
    end

    def <<(data)
      deflate(data)
      self
    end

    def finish(data = nil)
      unless @state == State::InStream || @state == State::Ready
        raise ZlibError.new "Invalid state #{@state}"
      end
      if data
        data = data.to_slice
        run(data, LibZ::Flush::FINISH)
      else
        run(nil, LibZ::Flush::FINISH)
      end
      @state = State::Finished
    end

    private def run(data, flush)
      if data
        @stream.avail_in = data.size.to_u32
        @stream.next_in = data.pointer(data.size)
      end
      loop do
        @stream.avail_out = @buf.size.to_u32
        @stream.next_out = @buf.pointer(@buf.size)
        ret = LibZ.deflate(self, flush)
        check_error(ret)
        @callback.call(@buf[0, @buf.size - @stream.avail_out])
        break unless @stream.avail_out == 0
      end
    ensure
      @stream.avail_in = 0_u32
      @stream.next_in = Pointer(UInt8).null
    end
  end

  def dictionary=(dict)
    dict = dict.to_slice
    ret = LibZ.deflateSetDictionary(self, dict, dict.size.to_u32)
    check_error(ret)
  end

  def reset
    LibZ.deflateReset(self)
    reset_state
  end

  def finalize
    LibZ.deflateEnd(self)
  end
end
