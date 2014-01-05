require_relative 'test_helper'

require 'cardiff/gnu_diff'

module Cardiff
  class GNUDiffTest < Cardiff::TestCase

    test "GNUDiff class is defined" do
      assert defined?(Cardiff::GNUDiff)
    end

    test "return value of GNUDiff.diff with same files" do
      file1 = File.open(File.expand_path('../test_helper.rb', __FILE__))

      assert_equal 0,
        GNUDiff.diff(
          file1,
          File.open(File.expand_path('../test_helper.rb', __FILE__))
        )
      assert file1.closed?
    end

    test "return value of GNUDiff.diff with different files" do
      assert_equal 1,
        GNUDiff.diff(
          File.open(File.expand_path('../test_helper.rb', __FILE__)),
          File.open(File.expand_path('../port_test.rb', __FILE__))
        )
    end

    test "output unified option" do
      assert_equal 1,
        GNUDiff.diff(
          File.open(File.expand_path('../test_helper.rb', __FILE__)),
          File.open(File.expand_path('../port_test.rb', __FILE__)),
          'output_unified' => true
        )
    end

    test "context option" do
      assert_equal 1,
        GNUDiff.diff(
          File.open(File.expand_path('../test_helper.rb', __FILE__)),
          File.open(File.expand_path('../port_test.rb', __FILE__)),
          'context' => 1
        )
    end

    test "output_str (String)" do
      str = ""
      assert_equal 1,
        GNUDiff.diff(
          File.open(File.expand_path('../test_helper.rb', __FILE__)),
          File.open(File.expand_path('../port_test.rb', __FILE__)),
          'context' => 1, :output_str => str
        )
      refute str.empty?
    end

    test "output_str (StringIO)" do
      str = StringIO.new
      assert_equal 1,
        GNUDiff.diff(
          File.open(File.expand_path('../test_helper.rb', __FILE__)),
          File.open(File.expand_path('../port_test.rb', __FILE__)),
          'context' => 1,
          :output_str => str
        )
      refute str.string.empty?
    end

    test "diff strings instead of files" do
      str = ""
      assert_equal 1,
        GNUDiff.diff(
          'omg',
          'OMG',
          :output_str => str
        )
      refute str.empty?
    end
  end
end
