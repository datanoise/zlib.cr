abstract class Zlib::ZStream
  enum DataType
    Binary = 0
    Text
    Unknown
  end

  enum State
    Ready
    InStream
    Finished
  end

  BUF_SIZE = 8192

  getter io
  getter state

  def initialize(@io)
    @stream = LibZ::ZStream.new
    @buf = Slice(UInt8).new(BUF_SIZE)
    reset_state
    @callback = -> (slice: Slice(UInt8)) {
      @io.write(slice)
    }
  end

  def set_callback(callback)
    @callback = callback
  end

  protected def reset_state
    @state = State::Ready
    @stream.next_out = @buf.pointer(@buf.length)
    @stream.avail_out = @buf.length.to_u32
  end

  def avail_in
    @stream.avail_in
  end

  def total_in
    @stream.total_in
  end

  def avail_out
    @stream.avail_out
  end

  def total_out
    @stream.total_out
  end

  def data_type
    DataType.new(@stream.data_type)
  end

  def adler
    @stream.adler
  end

  def finished?
    @state == State::Finished
  end

  def closed?
    finished?
  end

  def close
    return if closed?
    reset if @state.includes?(State::InStream)
    end_stream
  end

  protected def check_error(err)
    msg = @stream.msg ? String.new(@stream.msg) : nil
    ZlibError.check_error(err, msg)
  end

  def to_unsafe
    pointerof(@stream)
  end
end
