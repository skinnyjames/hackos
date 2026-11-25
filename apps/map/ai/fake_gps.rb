module HackOS::Maps
  class FakeGPS
    EARTH_R = 6_371_000.0

    attr_reader :lat, :lng, :heading, :speed

    # coords: decoded route LatLngs
    # speed: m/s (13 ≈ 30 mph), interval: seconds between fixes, jitter: meters
    def initialize(coords, speed: 53.0, interval: 1.0, jitter: 5.0)
      @coords = coords
      @speed = speed
      @interval = interval
      @jitter = jitter
      @i = 0
      @t = 0.0                 # 0..1 along the current segment
      @last = Hokusai.monotonic
      @lat = coords[0].lat
      @lng = coords[0].lng
      @heading = 0.0
    end

    def done?
      @i >= @coords.size - 1
    end

    # Call every frame; returns true when a new fix is available.
    def tick
      now = Hokusai.monotonic
      return false if now - @last < @interval || done?

      advance(@speed * (now - @last))
      @last = now
      true
    end

    # same shape as the GeoClue wrapper
    def coordinates
      [@lat, @lng]
    end

    private

    def advance(meters)
      while meters > 0 && !done?
        a = @coords[@i]
        b = @coords[@i + 1]
        seg = dist(a, b)
        left = seg * (1.0 - @t)

        if seg.zero? || meters >= left
          meters -= left
          @i += 1
          @t = 0.0
        else
          @t += meters / seg
          meters = 0
        end
      end

      a = @coords[@i]
      b = @coords[[@i + 1, @coords.size - 1].min]
      @heading = bearing(a, b)

      # interpolate, then add noise
      lat = a.lat + (b.lat - a.lat) * @t
      lng = a.lng + (b.lng - a.lng) * @t
      dn = (rand * 2 - 1) * @jitter
      de = (rand * 2 - 1) * @jitter
      @lat = lat + (dn / EARTH_R) * 180.0 / Math::PI
      @lng = lng + (de / (EARTH_R * Math.cos(lat * Math::PI / 180.0))) * 180.0 / Math::PI
    end

    def dist(a, b)
      rad = Math::PI / 180.0
      dlat = (b.lat - a.lat) * rad
      dlng = (b.lng - a.lng) * rad
      h = Math.sin(dlat / 2)**2 + Math.cos(a.lat * rad) * Math.cos(b.lat * rad) * Math.sin(dlng / 2)**2
      2 * EARTH_R * Math.asin(Math.sqrt(h))
    end

    def bearing(a, b)
      rad = Math::PI / 180.0
      dlng = (b.lng - a.lng) * rad
      y = Math.sin(dlng) * Math.cos(b.lat * rad)
      x = Math.cos(a.lat * rad) * Math.sin(b.lat * rad) -
          Math.sin(a.lat * rad) * Math.cos(b.lat * rad) * Math.cos(dlng)
      (Math.atan2(y, x) / rad + 360.0) % 360.0
    end
  end
end