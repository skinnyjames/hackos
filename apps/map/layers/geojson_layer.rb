module HackOS::Maps
  class TileBounds
    # LatLng -> screen pixel. lat_lng_to_point returns tile units at the
    # URL zoom (zoom + zoom_offset), and the view center sits at
    # screen_bounds.center + drag_offset, so it's just a shift and a scale.
    def lat_lng_to_screen(latlng, zoom)
      p = crs.lat_lng_to_point(latlng, zoom)
      tile_point_to_screen(p, zoom)
    end

    def tile_point_to_screen(p, zoom)
      c = crs.lat_lng_to_point(center, zoom)
      sc = screen_bounds.center + drag_offset
      Point.new(sc.x + (p.x - c.x) * TILE_SIZE, sc.y + (p.y - c.y) * TILE_SIZE)
    end
  end

  # Draws GeoJSON (FeatureCollection, Feature, or bare geometry).
  # Supports Point, MultiPoint, LineString, MultiLineString, Polygon (outline).
  # Coordinates are [lng, lat] per the GeoJSON spec.
  #
  # Per-feature style comes from properties (simplestyle-ish), falling back
  # to the layer defaults:
  #   "stroke"        => [r, g, b] or "#rrggbb"   line color
  #   "stroke-width"  => Float                    line width
  #   "marker-color"  => [r, g, b] or "#rrggbb"   point color
  #   "marker-radius" => Float                    point radius
  #   "kind" => "car", "heading" => degrees       draws the car marker
  class GeoJSONLayer < Hokusai::Block
    template <<~EOF
    [template]
      virtual
    EOF

    computed :data, default: nil
    computed :line_color, default: [44, 68, 224], convert: Hokusai::Color
    computed :line_width, default: 6.0, convert: proc(&:to_f)
    computed :point_radius, default: 6.0, convert: proc(&:to_f)

    inject :mcontrol

    def tile_bounds
      mcontrol.bounds
    end

    def zoom
      mcontrol.zoom
    end

    def on_mounted
      node.meta.set_prop(:z, "2")
      node.meta.set_prop(:ztarget, "parent")
    end

    # Project every coordinate once per (data, zoom) into tile units.
    # Per frame we only shift + scale, which is cheap.
    def projected
      if @projected_for != [data.object_id, zoom]
        crs = tile_bounds.crs
        @projected = features(data).map do |props, geom|
          [geom["type"], project_coords(geom["type"], geom["coordinates"], crs), props || {}]
        end
        @projected_for = [data.object_id, zoom]
      end

      @projected
    end

    def render(canvas)
      return yield(canvas) if data.nil? || tile_bounds.nil?
      sb = tile_bounds.screen_bounds
      pad = line_width * 2
      bounds = [sb.min.x - pad, sb.min.y - pad, sb.max.x + pad, sb.max.y + pad]

      draw do
        # lines first so points (destination, car) sit on top
        projected.each do |type, coords, props|
          case type
          when "LineString"
            draw_line(coords, props, bounds)
          when "MultiLineString", "Polygon"
            coords.each { |ring| draw_line(ring, props, bounds) }
          end
        end

        projected.each do |type, coords, props|
          case type
          when "Point"
            props["kind"] == "car" ? draw_car(coords, props) : draw_point(coords, props)
          when "MultiPoint"
            coords.each { |p| draw_point(p, props) }
          end
        end
      end

      yield canvas
    end

    private

    def draw_point(tp, props)
      s = tile_bounds.tile_point_to_screen(tp, zoom)
      circle(s.x, s.y, (props["marker-radius"] || point_radius).to_f) do |c|
        c.color = color_for(props["marker-color"], line_color)
      end
    end

    # white ring, blue dot, short heading tick
    def draw_car(tp, props)
      s = tile_bounds.tile_point_to_screen(tp, zoom)
      r = (props["marker-radius"] || 11.0).to_f
      color = color_for(props["marker-color"], line_color)

      circle(s.x, s.y, r + 3.0) do |c|
        c.color = [255, 255, 255]
      end
      circle(s.x, s.y, r) do |c|
        c.color = color
      end

      if (h = props["heading"])
        rad = h.to_f * Math::PI / 180.0
        # screen y grows downward, so north is -y
        ex = s.x + Math.sin(rad) * (r + 12.0)
        ey = s.y - Math.cos(rad) * (r + 12.0)
        line(s.x, s.y, ex, ey) do |c|
          c.color = color
          c.width = 5.0
        end
      end
    end

    # One polyline per visible run, so leaving and re-entering the screen
    # doesn't draw a chord across the gap.
    def draw_line(tps, props, bounds)
      color = color_for(props["stroke"], line_color)
      width = (props["stroke-width"] || line_width).to_f
      min_x, min_y, max_x, max_y = bounds

      run = []
      prev = nil

      tps.each do |tp|
        s = tile_bounds.tile_point_to_screen(tp, zoom)

        if prev
          off = (prev.x < min_x && s.x < min_x) || (prev.x > max_x && s.x > max_x) ||
                (prev.y < min_y && s.y < min_y) || (prev.y > max_y && s.y > max_y)

          if off
            flush_run(run, color, width)
            run = []
          else
            run << [prev.x, prev.y] if run.empty?
            run << [s.x, s.y]
          end
        end

        prev = s
      end

      flush_run(run, color, width)
    end

    def flush_run(run, color, width)
      return if run.size < 2

      polyline(run) do |c|
        c.type = :linear
        c.width = width
        c.color = color
      end
    end

    def color_for(value, fallback)
      case value
      when Array
        value
      when String
        hex = value.sub("#", "")
        [hex[0, 2].to_i(16), hex[2, 2].to_i(16), hex[4, 2].to_i(16)]
      else
        fallback
      end
    end

    # [[properties, geometry], ...]
    def features(obj, props = nil)
      case obj["type"]
      when "FeatureCollection"
        obj["features"].flat_map { |f| features(f) }
      when "Feature"
        obj["geometry"] ? features(obj["geometry"], obj["properties"]) : []
      when "GeometryCollection"
        obj["geometries"].flat_map { |g| features(g, props) }
      else
        [[props, obj]]
      end
    end

    def project_coords(type, coords, crs)
      case type
      when "Point"
        project(coords, crs)
      when "MultiPoint", "LineString"
        coords.map { |c| project(c, crs) }
      when "MultiLineString", "Polygon"
        coords.map { |line| line.map { |c| project(c, crs) } }
      else
        []
      end
    end

    def project(pos, crs)
      crs.lat_lng_to_point(HackOS::Maps::LatLng.new(pos[1], pos[0]), zoom)
    end
  end
end