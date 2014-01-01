module Cardiff
  class DiffItem < Struct.new(:start_a, :start_b, :deleted_a, :inserted_b)
    def ==(other)
      unless DiffItem === other
        raise TypeError, "other must be DiffItem, is: #{other.class}"
      end
      start_a == other.start_a && start_b == other.start_b &&
        deleted_a == other.deleted_a && inserted_b == other.inserted_b
    end

    def hash
      (deleted_a - inserted_b + start_a - start_b).hash
    end

    def to_s
      "#{deleted_a}.#{inserted_b}.#{start_a}.#{start_b}"
    end

    def to_a
      [deleted_a, inserted_b, start_a, start_b]
    end

  end
end
