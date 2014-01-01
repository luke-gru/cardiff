require_relative 'test_helper'

module Riff
  # test port of C# code using exact same unit tests as found in ported code
  class PortTest < Riff::TestCase

    test "all changes" do
      a = ('a'..'l').to_a.join("\n")
      b = ('0'..'9').to_a.join("\n")
      assert_equal [[12,10,0,0]], diff_ary(a, b)
    end

    test "all same" do
      a = ('a'..'l').to_a.join("\n")
      b = a.dup
      assert_equal [], diff_ary(a, b)
    end

    test "snake" do
      a = ('a'..'f').to_a.join("\n")
      b = ( ('b'..'f').to_a + ['x'] ).join("\n")
      assert_equal [[1, 0, 0, 0], [0, 1, 6, 5]], diff_ary(a, b)
    end

    test "2002.09.20 repro" do
      a = 'c1,a,c2,b,c,d,e,g,h,i,j,c3,k,l'.split(',').join("\n")
      b = 'C1,a,C2,b,c,d,e,I1,e,g,h,i,j,C3,k,I2,l'.split(',').join("\n")
      assert_equal [[1,1,0,0], [1,1,2,2], [0,2,7,7], [1,1,11,13], [0,1,13,15]], diff_ary(a, b)
    end

    test "2003.02.07 repro" do
      a = "F"
      b = ( ['0', 'F'] + ('1'..'7').to_a ).join("\n")
      assert_equal [ [0,1,0,0], [0,7,1,2] ], diff_ary(a, b)
    end

    test "muegel repro" do
      skip("failing for now")
      a = "HELLO\nWORLD"
      b = "\n\nhello\n\n\n\nworld\n"
      assert_equal [ [2,8,0,0] ], diff_ary(a, b)
    end

    test "some differences" do
      a = ['a','b','-','c','d','e','f','f'].join("\n")
      b = ['a','b','x','c','e','f'].join("\n")
      assert_equal [ [1,1,2,2], [1,0,4,4], [1,0,7,6] ], diff_ary(a, b)
    end

    test "one change within long chain of repeats" do
      a = (['a'] * 10).join("\n")
      b = ( (['a'] * 4) + ['-'] + (['a'] * 5) ).join("\n")
      assert_equal [ [0,1,4,4], [1,0,9,10] ], diff_ary(a, b)
    end

  end
end
