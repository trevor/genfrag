# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? GENFRAG_SPEC_HELPER
GENFRAG_SPEC_HELPER = true

require 'stringio'
require 'tmpdir'
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib genfrag]))

GENFRAG_SPEC_DATA_DIR = File.join(File.dirname(__FILE__), %w[data])

GENFRAG_SPEC_TMP_DIR = File.join(Dir.tmpdir, %w[genfrag])
puts "tmp dir is #{GENFRAG_SPEC_TMP_DIR}"

def compare(filename, ext)
  generated = File.join(@working_output_dir, filename + ext)
  frozen = File.join(@frozen_output_dir, filename + ext)
  FileUtils.compare_file(generated, frozen)
end

Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

class StringIO
  alias :_readline :readline
  def readline
    @_pos ||= 0
    seek @_pos
    begin
      _line = _readline
      @_pos = tell
      _line.rstrip
    rescue EOFError
      nil
    end
  end

  def clear
    truncate 0
    seek 0
    @_pos = 0
  end
end

end  # unless defined?

# EOF
