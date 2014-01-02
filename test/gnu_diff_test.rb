require_relative 'test_helper'

require 'cardiff_gnu_diff'

module Cardiff
  class GNUDiffTest < Cardiff::TestCase

    test "GNUDiff class is defined" do
      assert defined?(Cardiff::GNUDiff)
    end

    test "return value of GNUDiff.diff with same files" do
      assert_equal 0, GNUDiff.diff(File.expand_path('../test_helper.rb', __FILE__), File.expand_path('../test_helper.rb', __FILE__))
    end

    test "return value of GNUDiff.diff with different files" do
      assert_equal 1, GNUDiff.diff(File.expand_path('../test_helper.rb', __FILE__), File.expand_path('../port_test.rb', __FILE__))
    end

  end
end
