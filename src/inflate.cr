module Zlib
  class Inflate < ZStream
    def initialize(io, wbits = LibZ::MAX_BITS)
      super(io)
      ret = LibZ.inflateInit2(self, wbits, LibZ.zlibVersion(), sizeof(LibZ::ZStream))
      check_error(ret)
    end

    def inflate(data, flush = LibZ::Flush::NO_FLUSH)
      case @state
      when State::Ready
        @state = State::InStream
      when State::InStream
      else
        raise ZlibError.new "Invalid state #{@state}"
      end
      data = data.to_slice
      @stream.avail_in = data.size.to_u32
      @stream.next_in = data.pointer(data.size)

      loop do
        @stream.avail_out = @buf.size.to_u32
        @stream.next_out = @buf.pointer(@buf.size)
        ret = LibZ.inflate(self, flush)
        if ret == LibZ::STREAM_END
          @state = State::Finished
        else
          check_error(ret)
        end
        @callback.call(@buf[0, @buf.size - @stream.avail_out])
        break unless @stream.avail_out == 0
        break if @state == State::Finished
      end
    end

    def <<(data)
      inflate(data)
      self
    end

    def finalize
      LibZ.inflateEnd(self)
    end

    def reset
      LibZ.inflateReset(self)
      reset_state
    end

    def dictionary=(dict)
      dict = dict.to_slice
      ret = LibZ.inflateSetDictionary(self, dict, dict.size.to_u32)
      check_error(ret)
    end
  end
end
