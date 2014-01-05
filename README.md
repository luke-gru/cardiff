cardiff: A Ruby Diffing Library
===============================

Cardiff is a diffing library that provides both Ruby-only diffing
and a Ruby C extension that wraps GNU's `diff` utility.

Ruby-only Diffing
=================

Ruby port of C# code found at [http://www.mathertel.de/Diff/Default.aspx]
with minimal changes. There is support for both line by line and character
by character diffing.

NOTE: more to come soon.

GNU Diffing (C Extension)
=========================

Usage
-----

    require 'cardiff/gnu_diff'
    include Cardiff
    options = {:output_unified => true}
    file1 = File.open('./file1.txt')
    file2 = File.open('./file2.txt')
    status = GNUDiff.diff(file1, file2, options) # outputs to $stdout
    # Now both files are closed, and status is 1 if there is a difference and
    # 0 if there is no difference, just like the exit status of `diff`.

If you want to diff 2 strings instead of 2 files:

    require 'cardiff/gnu_diff'
    str1 = "some string"
    str2 = "another string"
    status = Cardiff::GNUDiff.diff(str1, str2) # outputs to $stdout

To have the output be to a string:

    output_str = ''
    status = Cardiff::GNUDiff.diff(str1, str2, :output_str => output_str) # outputs to the string, not $stdout
    # Also works if `output_str` is a StringIO. NOTE: clears output_str before appending to it.

Options
-------

Coming soon.
