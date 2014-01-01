module Cardiff
  class DiffData < Struct.new(:data)

    attr_reader :length, :modified

    def initialize(data)
      self.data = data
      @length = data.length
      @modified = Array.new(@length + 2, false)
    end

  end
end
