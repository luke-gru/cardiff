require File.expand_path('../../cardiff_gnu_diff', __FILE__)
require 'tempfile'

module Cardiff
  module GNUDiff

    def self.diff(input1, input2, options = {})
      if input_files = (input1.respond_to?(:path) && input2.respond_to?(:path))
        capture_stdout?(options[:output_str]) do
          diff_raw(input1.path, input2.path, options)
        end
      else
        capture_stdout?(options[:output_str]) do
          diff_strings(input1, input2, options)
        end
      end
    ensure
      if input_files
        input1.close
        input2.close
      end
    end

    private

    def self.diff_strings(str1, str2, options = {})
      tmp1 = Tempfile.new('file1')
      tmp2 = Tempfile.new('file2')
      tmp1.write(str1.to_s)
      tmp2.write(str2.to_s)
      tmp1.close
      tmp2.close
      diff_raw(tmp1.path, tmp2.path, options)
    ensure
      tmp1.unlink
      tmp2.unlink
    end

    def self.capture_stdout?(output_str = nil, &block)
      if output_str
        capture_stdout(output_str, &block)
      else
        block.call
      end
    end

    def self.capture_stdout(output_str, &block)
      stdout_log = Tempfile.new('stdout_log')
      old = $stdout.dup
      $stdout.reopen(File.new(stdout_log, 'w'))
      ret = block.call

      # clear string
      if output_str.respond_to?(:string)
        output_str.string.clear
      else
        output_str.clear
      end

      output_str << stdout_log.read
      ret
    ensure
      stdout_log.close
      stdout_log.unlink
      $stdout.reopen(old)
    end

  end
end
