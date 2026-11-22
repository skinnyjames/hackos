module HackOS::Maps
  class SphericalMercator
    R = 6378137
    MAX_LATITUDE = 85.0511287798

    class << self
      def project(latlng)
        d = Math::PI / 180
        lat = [[MAX_LATITUDE, latlng.lat].min, -MAX_LATITUDE].max
        sin = Math.sin(lat * d)

        Point.new(
          SphericalMercator::R * latlng.lng * d,
          SphericalMercator::R * Math.log((1 + sin) / (1 - sin)) / 2)
      end

      def unproject(point)
        d = 180 / Math::PI

        LatLng.new(
          (2 * Math.atan(Math.exp(point.y / SphericalMercator::R)) - (Math::PI / 2)) * d,
          point.x * d / R
        )
      end

      def bounds
        d = MAX_LATITUDE * Math::PI
        Bounds.new([-d,-d], [d, d])
      end
    end
  end
end
