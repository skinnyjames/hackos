module HackOS::Maps
  module Routing
    GEOFFREY = "https://geoffrey.skinnyjames.net"
    VALHALLA = "https://routes.skinnyjames.net"

    # Valhalla request body. dest_street helps snap to the right road.
    def self.request(from, to, street: nil, costing: "auto")
      dest = { "lat" => to.lat, "lon" => to.lng, "preferred_side" => "same" }
      dest["street"] = street if street && !street.empty?

      {
        "locations" => [{ "lat" => from.lat, "lon" => from.lng }, dest],
        "costing" => costing,
        "units" => "miles"
      }.to_json
    end

    # Geoffrey geocode hit -> "N High St" style street string for Valhalla.
    def self.street_for(hit)
      %w(street_predir street_pretype street_name street_posttype street_postdir)
        .map { |k| hit[k] }
        .compact
        .map(&:to_s)
        .reject(&:empty?)
        .join(" ")
    end

    # Valhalla trip -> GeoJSON FeatureCollection:
    #   the driven route, the last stretch from the road to the address point,
    #   and the address point itself (Geoffrey's NAD location).
    def self.to_geojson(trip, dest)
      coords = trip["legs"].flat_map { |leg| decode(leg["shape"]) }
      line = coords.map { |ll| [ll.lng, ll.lat] }
      last = line.last
      target = [dest.lng, dest.lat]

      features = [
        { "type" => "Feature", "properties" => { "kind" => "route" },
          "geometry" => { "type" => "LineString", "coordinates" => line } },
        { "type" => "Feature", "properties" => { "kind" => "destination" },
          "geometry" => { "type" => "Point", "coordinates" => target } }
      ]

      if last
        features << { "type" => "Feature", "properties" => { "kind" => "last_stretch" },
                      "geometry" => { "type" => "LineString", "coordinates" => [last, target] } }
      end

      { "type" => "FeatureCollection", "features" => features }
    end

    DRIVEN = [150, 150, 160]
    AHEAD = [44, 68, 224]

    # Route split at the car: driven part greyed out, remaining part blue,
    # the car at its snapped position, and the destination.
    #   progress: RouteProgress, info: progress.locate(pos), dest: LatLng
    def self.progress_geojson(progress, info, dest, heading: nil)
      coords = progress.coords
      i = info[:index]
      snap = [info[:snapped].lng, info[:snapped].lat]

      driven = coords[0..i].map { |ll| [ll.lng, ll.lat] } + [snap]
      ahead = [snap] + coords[(i + 1)..-1].map { |ll| [ll.lng, ll.lat] }
      target = [dest.lng, dest.lat]

      features = [
        line_feature("driven", driven, DRIVEN),
        line_feature("route", ahead, AHEAD),
        line_feature("last_stretch", [ahead.last, target], AHEAD, 4.0),
        { "type" => "Feature",
          "properties" => { "kind" => "destination", "marker-color" => [224, 68, 44], "marker-radius" => 8.0 },
          "geometry" => { "type" => "Point", "coordinates" => target } },
        { "type" => "Feature",
          "properties" => { "kind" => "car", "heading" => heading || info[:heading], "marker-color" => AHEAD },
          "geometry" => { "type" => "Point", "coordinates" => snap } }
      ]

      { "type" => "FeatureCollection", "features" => features }
    end

    def self.line_feature(kind, coords, color, width = nil)
      props = { "kind" => kind, "stroke" => color }
      props["stroke-width"] = width if width
      { "type" => "Feature", "properties" => props,
        "geometry" => { "type" => "LineString", "coordinates" => coords } }
    end

    # Valhalla shapes are encoded polylines with 6 digits of precision.
    def self.decode(str, precision = 6)
      factor = 10.0 ** precision
      coords = []
      i = 0
      lat = 0
      lng = 0

      while i < str.size
        [0, 1].each do |axis|
          shift = 0
          result = 0
          while true
            b = str.getbyte(i) - 63
            i += 1
            result |= (b & 0x1f) << shift
            shift += 5
            break if b < 0x20
          end
          delta = (result & 1) == 1 ? ~(result >> 1) : (result >> 1)
          axis.zero? ? lat += delta : lng += delta
        end
        coords << HackOS::Maps::LatLng.new(lat / factor, lng / factor)
      end

      coords
    end
  end
end