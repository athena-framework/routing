require "./lib_pcre2"

# :nodoc:
#
# Specialized re-implementation of stdlib's regex, but with `PCRE2` using the fast track API.
class Athena::Routing::FastRegex
  struct MatchData
    getter group_size : Int32
    getter mark : String?

    # :nodoc:
    def initialize(@string : String, @ovector : LibC::SizeT*, @group_size : Int32, @mark : String?)
    end

    def size : Int32
      group_size + 1
    end

    def []?(n : Int) : String?
      return unless valid_group?(n)

      n += size if n < 0
      start = @ovector[n * 2]
      finish = @ovector[n * 2 + 1]
      return if start < 0
      @string.byte_slice(start, finish - start)
    end

    def [](n : Int) : String
      check_index_out_of_bounds n
      n += size if n < 0

      value = self[n]?
      raise_capture_group_was_not_matched n if value.nil?
      value
    end

    private def check_index_out_of_bounds(index)
      raise_invalid_group_index(index) unless valid_group?(index)
    end

    private def valid_group?(index)
      -size <= index < size
    end

    private def raise_invalid_group_index(index)
      raise IndexError.new("Invalid capture group index: #{index}")
    end

    private def raise_capture_group_was_not_matched(index)
      raise IndexError.new("Capture group #{index} was not matched")
    end
  end

  @mark : UInt8* = Pointer(UInt8).null

  def initialize(@source : String)
    unless @code = LibPCRE2.compile @source, @source.bytesize, 0, out error_code, out error_offset, nil
      bytes = Bytes.new 128
      err = LibPCRE2.get_error_message(error_code, bytes, bytes.size)
      raise ArgumentError.new "#{String.new(bytes)} at #{error_offset}"
    end

    LibPCRE2.jit_compile @code, LibPCRE2::JIT_COMPLETE
    LibPCRE2.pattern_info @code, LibPCRE2::INFO_CAPTURECOUNT, out @capture_count

    @match_data = LibPCRE2.create_match_data @code, nil
  end

  def match(str, pos = 0) : MatchData?
    if byte_index = str.char_index_to_byte_index(pos)
      match = match_at_byte_index(str, byte_index)
    else
      match = nil
    end
  end

  def match_at_byte_index(str, byte_index = 0) : MatchData?
    return if byte_index > str.bytesize
    internal_matches(str, byte_index)
    Athena::Routing::FastRegex::MatchData.new(str, LibPCRE2.get_ovector(@match_data), @capture_count, ((mark = LibPCRE2.get_mark(@match_data)) ? String.new(mark) : nil))
  end

  def inspect(io : IO) : Nil
    io << '/'
    reader = Char::Reader.new(@source)
    while reader.has_next?
      case char = reader.current_char
      when '\\'
        io << '\\'
        io << reader.next_char
      when '/'
        io << "\\/"
      else
        io << char
      end
      reader.next_char
    end
    io << '/'
  end

  private def internal_matches(str, byte_index)
    unless (match = LibPCRE2.jit_match @code, str, str.bytesize, byte_index, 0, @match_data, nil) > 0
      bytes = Bytes.new 128
      err = LibPCRE2.get_error_message(match, bytes, bytes.size)
      raise ArgumentError.new String.new bytes
    end
  end
end
