require_relative 'test_helper'

require 'cardiff_gnu_diff'

module Cardiff
  class GNUDiffTest < Cardiff::TestCase

    test "GNUDiff class is defined" do
      assert defined?(Cardiff::GNUDiff)
    end

    test "return value of GNUDiff.diff" do
      assert_equal 47, GNUDiff.diff("omg", "omg")
    end

  end
end
