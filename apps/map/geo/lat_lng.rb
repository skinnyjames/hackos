module HackOS::Maps
  class LatLng
    def self.from(array)
      new(array[0], array[1])
    end

    attr_accessor :lat, :lng, :alt
    
    def initialize(lat, lng, altitude = nil)
      @lat = lat
      @lng = lng
      @alt = altitude
    end

    def ==(latlng, max_margin = nil)
      margin = [(lat - latlng.lat).abs, (lng - latlng.lng).abs].max

      margin <= (max_margin || 1.0E-9)
    end

    def reverse_geo
      p["latlng", lat, lng]
      
      # body = JSON.parse(RestClient.get("https://geoffrey.skinnyjames.net/api/v1/us/reverse-geocode?lat=#{lat}&lng=#{lng}").body, symbolize_names: true)
      # body[0]
    end

    def to_point(crs, zoom)
      crs.lat_lng_to_point(self, zoom)
    end

    def to_s(precision = 4)
      "LatLng(#{lat.round(precision)}, #{lng.round(precision)})"
    end

    def distance_to(other)
      Earth.distance(self, other)
    end

    def wrap
      Earth.wrap_lat_lng(self)
    end

    def to_bounds(meters)
      lat_accuracy = 100 * meters / 40075017
      lng_accuracy = lat_accuracy / Math.cos((Math::PI / 180) * lat)

      LatLngBounds.new(
        lat - lat_accuracy, 
        lng - lng_accuracy,
        lat + lat_accuracy,
        lng + lng_accuracy
      )
    end
  end
end
