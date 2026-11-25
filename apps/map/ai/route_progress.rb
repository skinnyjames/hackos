module HackOS::Maps
  # Where a position sits along the current route.
  class RouteProgress
    EARTH_R = 6_371_000.0
    OFF_ROUTE_M = 40.0

    attr_reader :coords, :maneuvers, :cumulative

    # coords: decoded LatLngs; maneuvers: Valhalla maneuvers with shape indexes
    # matching coords (shift them per leg if there's more than one leg)
    def initialize(coords, maneuvers)
      @coords = coords
      @maneuvers = maneuvers
      @cumulative = [0.0]
      (1...coords.size).each do |i|
        @cumulative << @cumulative[-1] + dist(coords[i - 1], coords[i])
      end
      @last_index = 0
    end

    def total_m
      cumulative[-1]
    end

    def locate(pos)
      from = [@last_index - 5, 0].max
      to = [@last_index + 50, coords.size - 2].min
      best = nearest(pos, from, to)
      best = nearest(pos, 0, coords.size - 2) if best[:off_m] > OFF_ROUTE_M

      off_route = best[:off_m] > OFF_ROUTE_M

      # never slide backward unless we've actually left the route
      if best[:index] < @last_index && !off_route
        best = nearest(pos, @last_index, @last_index)
      end
      @last_index = best[:index]

      i = best[:index]
      along = cumulative[i] + best[:t] * (cumulative[i + 1] - cumulative[i])
      step = maneuver_at(i)
      step_i = step ? maneuvers.index(step) : nil

      {
        index: i,
        t: best[:t],
        snapped: best[:point],
        off_route: off_route,
        off_m: best[:off_m],
        along_m: along,
        remaining_m: total_m - along,
        heading: bearing(coords[i], coords[i + 1]),
        maneuver: step,
        next_maneuver: step_i ? maneuvers[step_i + 1] : nil,
        to_next_m: step ? cumulative[step["end_shape_index"]] - along : nil
      }
    end

    private

    def nearest(pos, from, to)
      best = nil
      (from..to).each do |i|
        t, pt = project(pos, coords[i], coords[i + 1])
        d = dist(pos, pt)
        best = { index: i, t: t, point: pt, off_m: d } if best.nil? || d < best[:off_m]
      end
      best
    end

    def project(p, a, b)
      k = Math.cos(a.lat * Math::PI / 180.0)
      ax = a.lng * k
      ay = a.lat
      dx = b.lng * k - ax
      dy = b.lat - ay
      len2 = dx * dx + dy * dy
      t = len2.zero? ? 0.0 : ((p.lng * k - ax) * dx + (p.lat - ay) * dy) / len2
      t = 0.0 if t < 0
      t = 1.0 if t > 1
      [t, LatLng.new(a.lat + (b.lat - a.lat) * t, a.lng + (b.lng - a.lng) * t)]
    end

    def maneuver_at(index)
      maneuvers.find { |m| index >= m["begin_shape_index"] && index < m["end_shape_index"] } || maneuvers.last
    end

    def dist(a, b)
      rad = Math::PI / 180.0
      dlat = (b.lat - a.lat) * rad
      dlng = (b.lng - a.lng) * rad
      h = Math.sin(dlat / 2)**2 +
          Math.cos(a.lat * rad) * Math.cos(b.lat * rad) * Math.sin(dlng / 2)**2
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