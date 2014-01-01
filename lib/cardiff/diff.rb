require_relative 'diff_data'
require_relative 'diff_item'

module Cardiff
  # Ruby port of C# code found at http://www.mathertel.de/Diff/Default.aspx
  # with minimal changes.
  #
  # Can diff by line (entire lines marked as deleted or inserted) or by char
  # (characters marked as deleted or inserted).
  class Diff
    attr_reader :lines_a, :lines_b, :diff_items

    def self.diff_lines(a, b, format = true)
      new.diff_lines(a, b, format)
    end

    def self.diff_chars(a, b, format = true)
      new.diff_chars(a, b, format)
    end

    # global options
    class << self
      attr_accessor :diff_char_deletion_begin, :diff_char_deletion_end
      attr_accessor :diff_char_insertion_begin, :diff_char_insertion_end
      attr_accessor :diff_char_unchanged_begin, :diff_char_unchanged_end

      attr_accessor :diff_line_deletion_begin, :diff_line_deletion_end
      attr_accessor :diff_line_insertion_begin, :diff_line_insertion_end
      attr_accessor :diff_line_unchanged_begin, :diff_line_unchanged_end
    end


    # global option defaults

    # defaults for diffing by char
    self.diff_char_deletion_begin = %Q(<span class="diff-deletion">)
    self.diff_char_deletion_end = %Q(</span>)
    self.diff_char_insertion_begin = %Q(<span class="diff-insertion">)
    self.diff_char_insertion_end = %Q(</span>)
    self.diff_char_unchanged_begin = ''
    self.diff_char_unchanged_end = ''

    # defaults for diffing by line
    self.diff_line_deletion_begin  = '- '
    self.diff_line_deletion_end = ''
    self.diff_line_insertion_begin = '+ '
    self.diff_line_insertion_end = ''
    self.diff_line_unchanged_begin = ''
    self.diff_line_unchanged_end = ''


    def diff_lines(text_a, text_b, format = true)
      lines_hash = {}
      diff_data_a = DiffData.new(diff_codes(text_a, lines_hash, :a))
      diff_data_b = DiffData.new(diff_codes(text_b, lines_hash, :b))

      max = diff_data_a.length + diff_data_b.length + 1

      down_vec = Array.new(2 * max + 2)
      up_vec = Array.new(2 * max + 2)

      LCS(diff_data_a, 0, diff_data_a.length, diff_data_b, 0, diff_data_b.length, down_vec, up_vec)

      optimize(diff_data_a)
      optimize(diff_data_b)
      create_diff_items(diff_data_a, diff_data_b)
      if format
        format_diff_by_lines
      else
        @diff_items
      end
    end

    def diff_chars(text_a, text_b, format = true)
      codes_a = char_codes(text_a)
      codes_b = char_codes(text_b)
      diff_data_a = DiffData.new(codes_a)
      diff_data_b = DiffData.new(codes_b)

      max = diff_data_a.length + diff_data_b.length + 1

      down_vec = Array.new(2 * max + 2)
      up_vec = Array.new(2 * max + 2)

      LCS(diff_data_a, 0, diff_data_a.length, diff_data_b, 0, diff_data_b.length, down_vec, up_vec)
      create_diff_items(diff_data_a, diff_data_b)
      if format
        format_diff_by_chars(text_a, text_b)
      else
        @diff_items
      end
    end

    # not returning actual character codes as that would only work with
    # specific character sets, even though it is faster
    def char_codes(text)
      text.each_char.to_a
    end

    def format_diff_by_chars(text_a, text_b)
      ret = ""
      pos = 0
      aline = text_a
      bline = text_b
      alen = aline.length
      blen = bline.length

      deletion_begin = self.class.diff_char_deletion_begin
      deletion_end = self.class.diff_char_deletion_end

      insertion_begin = self.class.diff_char_insertion_begin
      insertion_end = self.class.diff_char_insertion_end

      unchanged_begin = self.class.diff_char_unchanged_begin
      unchanged_end = self.class.diff_char_unchanged_end

      @diff_items.each do |item|
        # unchanged chars
        if pos < item.start_b && pos < blen
          ret << unchanged_begin
          while pos < item.start_b && pos < blen
            ret << bline[pos]
            pos += 1
          end
          ret << unchanged_end
        end

        # deleted chars
        if item.deleted_a > 0
          ret << deletion_begin
          m = 0
          while m < item.deleted_a
            ret << aline[item.start_a + m]
            m += 1
          end
          ret << deletion_end
        end

        # inserted chars
        if pos < item.start_b + item.inserted_b
          ret << insertion_begin
          while pos < item.start_b + item.inserted_b
            ret << bline[pos]
            pos += 1
          end
          ret << insertion_end
        end
      end # while

      # unchanged chars
      if pos < blen
        ret << unchanged_begin
        while pos < blen
          ret << bline[pos]
          pos += 1
        end
        ret << unchanged_end
      end

      ret
    end

    def format_diff_by_lines
      n = 0
      ret = ""
      blen = @lines_b.length

      @diff_items.each do |item|
        # unchanged lines
        if n < item.start_b && n < blen
          ret << self.class.diff_line_unchanged_begin
          while n < item.start_b && n < blen
            ret << @lines_b[n] + "\n"
            n += 1
          end
          ret << self.class.diff_line_unchanged_end
        end

        # write deleted lines
        m = 0
        while m < item.deleted_a
          ret << self.class.diff_line_deletion_begin + @lines_a[item.start_a + m] + "\n" << self.class.diff_line_deletion_end
          m += 1
        end

        # write inserted lines
        while n < item.start_b + item.inserted_b
          ret << self.class.diff_line_insertion_begin + @lines_b[n] + "\n" << self.class.diff_line_insertion_end
          n += 1
        end
      end

      # rest of unchanged lines
      if n < blen
        ret << self.class.diff_line_unchanged_begin
        while n < blen
          ret << @lines_b[n] + "\n"
          n += 1
        end
        ret << self.class.diff_line_unchanged_end
      end

      ret
    end

    def diff_codes(text, lines_hash, a_or_b)
      lines = text.split("\n")
      if a_or_b == :a
        @lines_a = lines
      else
        @lines_b = lines
      end

      codes = Array.new(lines.length)
      last_used_code = lines_hash.size

      lines.each_with_index do |line, i|
        code = lines_hash[line]
        if code
          codes[i] = code
        else
          last_used_code += 1
          lines_hash[line] = last_used_code
          codes[i] = last_used_code
        end
      end

      codes
    end

    def LCS(diff_data_a, lower_a, upper_a, diff_data_b, lower_b, upper_b, down_vec, up_vec)
      while (lower_a < upper_a && lower_b < upper_b && diff_data_a.data[lower_a] == diff_data_b.data[lower_b])
        lower_a += 1; lower_b += 1
      end

      while (lower_a < upper_a && lower_b < upper_b && diff_data_a.data[upper_a - 1] == diff_data_b.data[upper_b - 1])
        upper_a -= 1; upper_b -= 1
      end

      if lower_a == upper_a
        while lower_b < upper_b
          diff_data_b.modified[lower_b] = true
          lower_b += 1
        end
      elsif lower_b == upper_b
        while lower_a < upper_a
          diff_data_a.modified[lower_a] = true
          lower_a += 1
        end
      else
        smsrd = SMS(diff_data_a, lower_a, upper_a, diff_data_b, lower_b, upper_b, down_vec, up_vec)

        LCS(diff_data_a, lower_a, smsrd.x, diff_data_b, lower_b, smsrd.y, down_vec, up_vec)
        LCS(diff_data_a, smsrd.x, upper_a, diff_data_b, smsrd.y, upper_b, down_vec, up_vec)
      end
    end

    # find the shortest middle snake throught the LCS matrix
    # See: https://neil.fraser.name/software/diff_match_patch/myers.pdf
    def SMS(diff_data_a, lower_a, upper_a, diff_data_b, lower_b, upper_b, down_vec, up_vec)
      ret = SMSRD.new(nil,nil)

      max = diff_data_a.length + diff_data_b.length + 1

      down_k = lower_a - lower_b
      up_k = upper_a - upper_b

      delta = (upper_a - lower_a) - (upper_b - lower_b)
      odd_delta = delta.odd?

      down_offset = max - down_k
      up_offset = max - up_k

      max_d = ((upper_a - lower_a + upper_b - lower_b) / 2) + 1

      down_vec[down_offset + down_k + 1] = lower_a
      up_vec[up_offset + up_k - 1] = upper_a

      d = 0
      while d <= max_d

        k = down_k - d
        while k <= down_k + d
          if k == down_k - d
            x = down_vec[down_offset + k + 1]
          else
            x = down_vec[down_offset + k - 1] + 1
            if (k < (down_k + d)) && (down_vec[down_offset + k + 1] >= x)
              x = down_vec[down_offset + k + 1]
            end
          end
          y = x - k

          while ((x < upper_a) && (y < upper_b) && (diff_data_a.data[x] == diff_data_b.data[y]))
            x += 1; y += 1;
          end
          down_vec[down_offset + k] = x

          if odd_delta && ((up_k - d) < k) && (k < (up_k + d))
            if (up_vec[up_offset + k] <= down_vec[down_offset + k])
              ret.x = down_vec[down_offset + k]
              ret.y = down_vec[down_offset + k] - k
              return ret
            end
          end

          k += 2
        end

        k = up_k - d
        while (k <= up_k + d)
          if (k == up_k + d)
            x = up_vec[up_offset + k - 1]
          else
            x = up_vec[up_offset + k + 1] - 1
            if ((k > up_k - d) && up_vec[up_offset + k - 1] < x)
              x = up_vec[up_offset + k - 1]
            end
          end
          y = x - k

          while ((x > lower_a) && (y > lower_b) && (diff_data_a.data[x - 1] == diff_data_b.data[y - 1]))
            x -= 1; y -= 1;
          end
          up_vec[up_offset + k] = x

          if (!odd_delta && (down_k - d <= k) && (k <= down_k + d))
            if (up_vec[up_offset + k] <= down_vec[down_offset + k])
              ret.x = down_vec[down_offset + k]
              ret.y = down_vec[down_offset + k] - k
              return ret
            end
          end

          k += 2
        end
        d += 1
      end
      raise "shouldn't get here!"
    end

    def create_diff_items(diff_data_a, diff_data_b)
      result = []

      line_a = 0
      line_b = 0

      while (line_a < diff_data_a.length || line_b < diff_data_b.length)
        if (line_a < diff_data_a.length) && (!diff_data_a.modified[line_a]) &&
          (line_b < diff_data_b.length) && (!diff_data_b.modified[line_b])
          line_a += 1; line_b += 1;
        else
          start_a = line_a
          start_b = line_b

          while (line_a < diff_data_a.length && (line_b >= diff_data_b.length || diff_data_a.modified[line_a]))
            line_a += 1
          end

          while (line_b < diff_data_b.length && (line_a >= diff_data_a.length || diff_data_b.modified[line_b]))
            line_b += 1
          end

          if (start_a < line_a) || (start_b < line_b)
            diff_item = DiffItem.new(start_a, start_b, line_a - start_a, line_b - start_b)
            result << diff_item
          end
        end
      end

      @diff_items = result
    end

    def optimize(diff_data)
      start_pos = 0
      end_pos = nil

      while (start_pos < diff_data.length)
        while (start_pos < diff_data.length) && (diff_data.modified[start_pos] == false)
          start_pos += 1
        end
        end_pos = start_pos
        while (end_pos < diff_data.length) && (diff_data.modified[end_pos] == true)
          end_pos += 1
        end

        if (end_pos < diff_data.length) && (diff_data.data[start_pos] == diff_data.data[end_pos])
          diff_data.modified[start_pos] = false
          diff_data.modified[end_pos] = true
        else
          start_pos = end_pos
        end
      end
    end

    class SMSRD < Struct.new(:x, :y)
    end
  end

end
