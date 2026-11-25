module HackOS::Maps
  # GeoClue-backed drop-in for FakeGPS: same tick / coordinates / heading / speed,
  # so the map's Control doesn't change.
  #
  #   @gps = RealGPS.new(control.dbus.geo)   # instead of FakeGPS.new(coords, ...)
  class RealGPS
    def initialize(geo)
      @geo = geo
      @fresh = false
      @listener = geo.on_update { |_| @fresh = true }
    end

    # true once per new fix, like FakeGPS#tick
    def tick
      fresh = @fresh
      @fresh = false
      fresh && @geo.fix?
    end

    def coordinates
      @geo.coordinates
    end

    # nil when unknown (standing still): progress falls back to the route bearing
    def heading
      @geo.heading_known? ? @geo.heading : nil
    end

    def speed
      @geo.speed_known? ? @geo.speed : 0.0
    end

    def accuracy
      @geo.accuracy
    end

    def close
      @geo.off_update(@listener)
    end
  end
end
