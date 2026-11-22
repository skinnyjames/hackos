module HackOS::Maps
  class Bounds
    attr_accessor :min, :max

    def initialize(tl, br)
      min_x = tl.is_a?(Array) ? tl[0] : tl.x
      max_x = br.is_a?(Array) ? br[0] : br.x
      min_y = tl.is_a?(Array) ? tl[1] : tl.y
      max_y = br.is_a?(Array) ? br[1] : br.y

      @min = Point.new(min_x, min_y)
      @max = Point.new(max_x, max_y)
    end

    def extend(point_or_bounds)
      case point_or_bounds
      when Point
        self.min.x = [point_or_bounds.x, min.x].min
        self.min.y = [point_or_bounds.y, min.y].min
        self.max.x = [point_or_bounds.x, max.x].max
        self.max.y = [point_or_bounds.y, max.y].max
      when Bounds
        self.min.x = [point_or_bounds.min.x, min.x].min
        self.min.y = [point_or_bounds.min.y, min.y].min
        self.max.x = [point_or_bounds.max.x, max.x].max
        self.max.y = [point_or_bounds.max.y, max.y].max  
      else
        raise Error.new("Extends requires a Point or Bounds")
      end
    end

    def to_lat_lng_bounds(crs, zoom)
      p[crs.point_to_lat_lng(min, zoom), min]

      tl = crs.point_to_lat_lng(min, zoom)
      br = crs.point_to_lat_lng(max, zoom)

      sw = LatLng.new(tl.lat, br.lng)
      ne = LatLng.new(br.lat, tl.lng)
      LatLngBounds.new(sw, ne)
    end

    def center(round = false)
      Point.new(
        (min.x + max.x) / 2,
        (min.y + max.y )/ 2,
        round
      )
    end

    def bottom_left
      Point.new(min.x, max.y)
    end

    def top_right
      Point.new(max.x, min.y)
    end

    def top_left
      min
    end

    def bottom_right
      max
    end

    def size
      max - min
    end

    def contains(point_or_bounds)
      case point_or_bounds
      when Point
        (point_or_bounds.x >= min.x) &&
        (point_or_bounds.x <= max.x) && 
        (point_or_bounds.y >= min.y) &&
        (point_or_bounds.y <= max.y) 
      when Bounds
        (point_or_bounds.min.x >= min.x) &&
        (point_or_bounds.max.x <= max.x) && 
        (point_or_bounds.min.y >= min.y) &&
        (point_or_bounds.max.y <= max.y) 
      else
        raise Error.new("contains requires a Point or Bounds")
      end
    end

    def intersects(bounds)
    end

    def overlaps(bounds)
    end

    def pad(buffer)
    end

    def ==(bounds)
      min == bounds.top_left && max == bounds.bottom_right
    end
  end
end
