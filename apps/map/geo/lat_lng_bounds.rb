module HackOS::Maps
  class LatLngBounds
    attr_accessor :south_west, :north_east

    def initialize(bl, tr)
      sw_lat = bl.is_a?(Array) ? bl[0] : bl.lat
      sw_lng = tr.is_a?(Array) ? bl[1] : bl.lng
      ne_lat = bl.is_a?(Array) ? tr[0] : tr.lat
      ne_lng = tr.is_a?(Array) ? tr[1] : tr.lng

      @south_west = LatLng.new(sw_lat, sw_lng)
      @north_east = LatLng.new(ne_lat, ne_lng)
    end

    def pad(buffer_ratio)
      height_buffer = Math.abs(south_west.lat - north_east.lat) * buffer_ratio
      width_buffer = Math.abs(south_west.lng - north_east.lng) * buffer_ratio

      LatLngBounds.new(
        LatLng.new(south_west.lat - height_buffer, south_west.lng - width_buffer),
        LatLng.new(north_east.lat + height_buffer, north_east.lng + width_buffer)
      )
    end

    def center
      LatLng.new(
        (south_west.lat + north_east.lat) / 2,
        (south_west.lng + north_east.lng) / 2
      )
    end

    def north_west
      LatLng.new(north_east.lat, south_west.lng)
    end

    def south_east
      LatLng.new(south_west.lat, north_east.lng)
    end

    def contains(obj)
      case obj
      when LatLng
        (obj.lat >= south_west.lat) && (obj.lat <= north_east.lat) &&
        (obj.lng >= south_west.lng) && (obj.lng <= north_east.lng)
      when LatLngBounds
        (obj.south_west.lat >= south_west.lat) && (obj.north_east.lat <= north_east.lat) &&
        (obj.south_west.lng >= south_west.lng) && (obj.south_west.lng <= north_east.lng)
      else
        raise Error.new("Must pass LatLng or LatLngBounds")
      end
    end

    def intersects(bounds)
    end

    def overlaps(bounds)
    end
  end
end
