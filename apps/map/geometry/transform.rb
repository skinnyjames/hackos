module HackOS::Maps
  class Transformation
    attr_reader :a, :b, :c, :d

    def initialize(a, b, c, d)
      @a = a
      @b = b
      @c = c
      @d = d
    end

    def transform(point, scale = 1)
      Point.new(
        scale * (a * point.x + b),
        scale * (c * point.y + d)
      )
    end

    def untransform(point, scale = 1)
      Point.new(
        (point.x / scale - b) / a,
        (point.y / scale - d) / c
      )
    end
  end
end
