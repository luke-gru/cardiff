module Cardiff
  class DiffUtil

    # Does character by character diff, prints to STDOUT
    # NOTE: not very optimized
    def self.print_diff(adata, bdata)
      table = build_lcs_table(adata, bdata, adata.length, bdata.length)
      do_print_diff(table, adata, bdata, adata.length, bdata.length)
    end

    # Does character by character diff, returns String
    # NOTE: not very optimized
    def self.diff(adata, bdata)
      table = build_lcs_table(adata, bdata, adata.length, bdata.length)
      create_diff(table, adata, bdata, adata.length, bdata.length)
    end

    def self.create_diff(lcs_table, adata, bdata, alen, blen)
      ret = ""

      while alen > 0 || blen > 0
        # work backwords through the 2 strings' equal chars
        while alen > 0 && blen > 0 && adata[alen - 1] == bdata[blen - 1]
          ret << adata[alen - 1] + " "
          alen -= 1; blen -= 1
        end
        # work backwards through added characters in bdata (additions to b)
        while blen > 0 && (alen == 0 || lcs_table[alen][blen - 1] >= lcs_table[alen - 1][blen])
          ret <<  bdata[blen - 1] + "+ "
          blen -= 1
          if blen > 0 && alen > 0 && adata[alen - 1] == bdata[blen - 1]
            break
          end
        end
        # work backwords through characters in adata that aren't in bdata (deletions to a)
        while alen > 0 && (blen == 0 || lcs_table[alen][blen - 1] < lcs_table[alen - 1][blen])
          ret << adata[alen - 1] + "- "
          alen -= 1
          if blen > 0 && alen > 0 && adata[alen - 1] == bdata[blen - 1]
            break
          end
        end
      end

      ret = ret.reverse
      ret.sub!(/\A /, '')
      ret
    end

    def self.do_print_diff(lcs_table, adata, bdata, alen, blen)
      if alen > 0 && blen > 0 && adata[alen - 1] == bdata[blen - 1]
        do_print_diff(lcs_table, adata, bdata, alen - 1, blen - 1)
        print " " + adata[alen - 1]
      else
        if blen > 0 && (alen == 0 || lcs_table[alen][blen - 1] >= lcs_table[alen - 1][blen])
          do_print_diff(lcs_table, adata, bdata, alen, blen - 1)
          print " +" + bdata[blen - 1]
        elsif alen > 0 && (blen == 0 || lcs_table[alen][blen - 1] < lcs_table[alen - 1][blen])
          do_print_diff(lcs_table, adata, bdata, alen - 1, blen)
          print " -" + adata[alen - 1]
        end
      end
    end

    # longest common subsequence: naive recursive
    def self.lcs_len_naive(x, y, m, n)
      if m == 0 || n == 0
        return 0
      end
      if x[m - 1] == y[n - 1]
        return 1 + lcs(x, y, m-1, n-1)
      else
        max(lcs(x, y, m, n-1), lcs(x, y, m-1, n))
      end
    end

    # longest common subsequence: dynamic programming (bottom up, using memoization)
    # builds LCS table from 2 strings
    def self.build_lcs_table(x, y, m, n)
      cols = Array.new(m+1) { Array.new(n+1) }


      # lower idx for x
      i = 0

      # [0..m] for x
      while i <= m
        # lower idx for y
        j = 0
        # [0..n] for y
        while j <= n
          if i == 0 || j == 0
            cols[i][j] = 0
          elsif x[i-1] == y[j-1]
            cols[i][j] = cols[i-1][j-1] + 1
          else
            cols[i][j] = max(cols[i-1][j], cols[i][j-1])
          end
          j+=1
        end
        i+=1
      end
      cols
    end

    # backtrack the lcs_table `c` to find the longest common subsequence
    def self.backtrack_recursive(c, x, y, m, n)
      if m == 0 || n == 0
        return ""
      elsif x[m-1] == y[n-1]
        return backtrack_recursive(c, x, y, m-1, n-1) + x[m-1]
      else
        if c[m][n-1] > c[m-1][n]
          return backtrack_recursive(c, x, y, m, n-1)
        else
          return backtrack_recursive(c, x, y, m-1, n)
        end
      end
    end

    def self.max(a, b)
      a > b ? a : b
    end

  end
end
