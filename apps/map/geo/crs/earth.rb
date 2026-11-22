module HackOS::Maps
  class Earth < CRS
    WRAP_LNG = [-180, 180]
    R = 6371000

    class << self
      def distance(a, b)
        rad = Math::PI / 180
        lat1 = a.lat * rad
        lat2 = b.lat * rad

        sin_d_lat = Math.sin((b.lat - a.lat) * rad / 2)
        sin_d_lon = Math.sin((b.lng - a.lng) * rad / 2)

        a = sin_d_lat * sin_d_lat + Math.cos(lat1) * Math.cos(lat2) * sin_d_lon * sin_d_lon
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

        Earth::R * c
      end

      def wrap_lat_lng(latlng)
      end
    end
  end
end