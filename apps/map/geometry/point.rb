module HackOS::Maps
  class Point
    include Comparable

    def self.convert(str)
      case str
      when String
        coords = str.gsub(/\[|\]/, '').split(",").map(&:to_f)
        new(coords[0], coords[1])
      when Array
        new(str[0], str[1])
      end
    end

    def valid?(x, y)
      true
    end

    attr_accessor :x, :y

    def initialize(x, y, round = false)
      raise Error.new("Invalid point") unless valid?(x, y)

      @x = round ? x.round : x
      @y = round ? y.round : y
    end

    def add!(point)
      self.x += point.x
      self.y += point.y

      self
    end

    def <=>(point)
      if x < point.x && y < point.y
        -1
      elsif x >  point.x && y > point.y
        1
      else
        0
      end
    end

    def +(point)
      Point.new(x + point.x, y + point.y)
    end

    def -(point)
      Point.new(x - point.x, y - point.y)
    end

    def subtract(num)
      Point.new(x - num, y - num)
    end

    def /(num)
      Point.new(x / num.x, y / num.y)
    end

    def *(num)
      Point.new(x * num.x, y * num.y)
    end

    def scale(point)
      Point.new(x * point.x, y * point.y)
    end

    def unscale(point)
      Point.new(x / point.x, y / point.y)
    end

    def round
      Point.new(x.round, y.round)
    end

    def floor
      Point.new(x.floor, y.floor)
    end

    def ceil
      Point.new(x.ceil, y.ceil)
    end

    def distance_to(point)
      xx = point.x - x
      yy = point.y - y

      Math.sqrt(xx ** xx + yy ** yy)
    end

    def ==(point)
      point.x == x && point.y == y
    end

    def contains(point)
      Math.abs(point.x) <= Math.abs(x) &&
        Math.abs(point.y) <= Math.abs(y)
    end

    def to_s
      "Point(#{x}, #{y})"
    end
  end
end
