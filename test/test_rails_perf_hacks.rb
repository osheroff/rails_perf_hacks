require 'rubygems'
require 'bundler'
Bundler.setup

require 'active_support/test_case'
require 'test/unit/autorunner'
require 'rails_perf_hacks'

class TestRailsPerfHacks <  ActiveSupport::TestCase
  def with_kcode(code)
    if RUBY_VERSION < '1.9'
      begin
        old_kcode, $KCODE = $KCODE, code
        yield
      ensure
        $KCODE = old_kcode
      end
    else
      yield
    end
  end

  if RUBY_VERSION < '1.9'
    test "clean leaves ASCII strings intact" do
      with_encoding('None') do
        [
          'word', "\270\236\010\210\245"
        ].each do |string|
          assert_equal string, ActiveSupport::Multibyte.clean(string)
        end
      end
    end

    test "clean cleans invalid characters from UTF-8 encoded strings" do
      with_encoding('UTF8') do
        cleaned_utf8 = [8].pack('C*')
        assert_equal example('valid UTF-8'), ActiveSupport::Multibyte.clean(example('valid UTF-8'))
        assert_equal cleaned_utf8, ActiveSupport::Multibyte.clean(example('invalid UTF-8'))
      end
    end

    test "clean cleans invalid characters from Shift-JIS encoded strings" do
      with_encoding('SJIS') do
        cleaned_sjis = [184, 0, 136, 165].pack('C*')
        assert_equal example('valid Shift-JIS'), ActiveSupport::Multibyte.clean(example('valid Shift-JIS'))
        assert_equal cleaned_sjis, ActiveSupport::Multibyte.clean(example('invalid Shift-JIS'))
      end
    end

    test "a bit of fuzz shouldn't crash us" do
      with_encoding("UTF8") do
        100_000.times do
          str = 10.times.map { rand(255) }.pack("C*")
          compare_original(str)
          #ActiveSupport::Multibyte.clean(10.times.map { rand(255) }.pack("C*"))
        end
      end
    end

    test "against the original method" do
      compare_original("\x4C\x6F\x6F\x70\x73\x95\x20\x34\x30\x20\x53\x6F\x6C\x6F\x20\x56\x69\x6F\x6C\x61")
      compare_original("\xF2hello world")
      compare_original("☃ and me")
      compare_original("\xf3\xb0\x80\x8b coming back")
      compare_original("crash me \xf3")
      compare_original("crash me \xe0")
      compare_original("crash me \xe0")
    end
  else
    test "clean is a no-op" do
      with_encoding('UTF8') do
        assert_equal example('invalid Shift-JIS'), ActiveSupport::Multibyte.clean(example('invalid Shift-JIS'))
      end
    end
  end

  private

  STRINGS = {
      'valid ASCII'       => [65, 83, 67, 73, 73].pack('C*'),
      'invalid ASCII'     => [128].pack('C*'),
      'valid UTF-8'       => [227, 129, 147, 227, 129, 171, 227, 129, 161, 227, 130, 143].pack('C*'),
      'invalid UTF-8'     => [184, 158, 8, 136, 165].pack('C*'),
      'valid Shift-JIS'   => [131, 122, 129, 91, 131, 128].pack('C*'),
      'invalid Shift-JIS' => [184, 158, 8, 0, 255, 136, 165].pack('C*')
    }

  if Kernel.const_defined?(:Encoding)
    def example(key)
      STRINGS[key].force_encoding(Encoding.default_external)
    end

    def examples
      STRINGS.values.map { |s| s.force_encoding(Encoding.default_external) }
    end
  else
    def example(key)
      STRINGS[key]
    end

    def examples
      STRINGS.values
    end
  end

  if 'string'.respond_to?(:encoding)
    KCODE_TO_ENCODING = Hash.new(Encoding::BINARY).
      update('UTF8' => Encoding::UTF_8, 'SJIS' => Encoding::Shift_JIS)

    def with_encoding(enc)
      before = Encoding.default_external
      silence_warnings { Encoding.default_external = KCODE_TO_ENCODING[enc] }

      yield

      silence_warnings { Encoding.default_external = before }
    end
  else
    alias with_encoding with_kcode
  end

  UNICODE_STRING = 'こにちわ'
  ASCII_STRING = 'ohayo'
  BYTE_STRING = "\270\236\010\210\245"

  def chars(str)
    ActiveSupport::Multibyte::Chars.new(str)
  end

  def inspect_codepoints(str)
    str.to_s.unpack("U*").map{|cp| cp.to_s(16) }.join(' ')
  end

  def assert_equal_codepoints(expected, actual, message=nil)
    assert_equal(inspect_codepoints(expected), inspect_codepoints(actual), message)
  end

  def hexstr(str)
    str.unpack("C*").map { |c| "\\x%x" % c }.join
  end

  def compare_original(input)

    if ActiveSupport::Multibyte.clean_slow(input) != ActiveSupport::Multibyte.clean(input)
      original = hexstr(input)
      split = input.split(//).map { |s| hexstr(s) }.join(" ")
      puts original
      puts split
      puts "OURS: " + hexstr(ActiveSupport::Multibyte.clean(input))
      puts "!!!!: " + hexstr(ActiveSupport::Multibyte.clean_slow(input))
      assert false
      assert_equal ActiveSupport::Multibyte.clean_slow(input), ActiveSupport::Multibyte.clean(input)
    end
  end
end


