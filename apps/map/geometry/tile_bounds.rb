module HackOS::Maps
  class TileBounds
    TILE_SIZE = 256

    attr_reader :center, :screen_bounds, :crs
    attr_accessor :drag_offset, :screen_bounds, :center

    def initialize(crs, latlng, screen_bounds)
      @crs = crs
      @center = latlng
      @screen_bounds = screen_bounds
      @tiles = {}
      @drag_offset = Point.new(0, 0)
    end

    def geo_bounds(bounds, zoom)
      bounds.to_lat_lng_bounds(crs, zoom)  
    end

    def offset(zoom)
      collection(zoom).offset
    end

    def coords_at(point, zoom)
      collection = collection(zoom)
      tile = collection.contains(point)
      offset = collection.offset

      point.x = point.x - tile.screen.center.x + offset.x
      point.y = point.y - tile.screen.center.y + offset.y

      # click point x / screen width = ratio
      nx = (point.x) / (tile.screen.max.x - tile.screen.min.x)
      # click poidnt y / screen_height = ratio
      ny = (point.y) / (tile.screen.max.y - tile.screen.min.y)

      mbx = (tile.map.max.x - tile.map.min.x) * nx
      mby = (tile.map.max.y - tile.map.min.y) * ny

      ax = (tile.map.min.x + mbx)
      ay = (tile.map.min.y + mby)

      x = Point.new(ax, ay)
      crs.point_to_lat_lng(x, zoom)
    end


    def collection(zoom)
      collection = BoundsProxyCollection.new
      tile_center = crs.lat_lng_to_point(center, zoom)
      screen_center = screen_bounds.center + drag_offset

      offx = tile_center.x.modulo(1)
      offy = tile_center.y.modulo(1)

      collection.offset = Point.new(offx * TILE_SIZE, offy * TILE_SIZE)

      sx = screen_center.x
      sy = screen_center.y

      tile_center = tile_center.floor
      mx = tile_center.x
      my = tile_center.y

      tp = Point.new(TILE_SIZE, TILE_SIZE)
      mp = Point.new(1, 1)

      # find top left...
      tl = Point.new(screen_center.x - (TILE_SIZE / 2), screen_center.y - (TILE_SIZE / 2))
      mtl = Point.new(tile_center.x, tile_center.y)

      while tl.x >= screen_bounds.min.x || tl.y >= screen_bounds.min.y
        tl = tl - tp
        mtl = mtl - mp
      end
      
      sx = tl.x
      sy = tl.y
      mx = mtl.x
      my = mtl.y

      # populate tiles
      while sx <= screen_bounds.max.x + TILE_SIZE
        sy = tl.y
        my = mtl.y

        while sy <= screen_bounds.max.y + TILE_SIZE
          sb = Bounds.new(
            Point.new(sx, sy),
            Point.new(sx + tp.x, sy + tp.y)
          )

          mb = Bounds.new(
            Point.new(mx, my),
            Point.new(mx + mp.x, my + mp.y)
          )

          collection << BoundsProxy.new(sb, mb)
          my += 1
          sy += TILE_SIZE
        end

        mx += 1
        sx += TILE_SIZE
      end

      collection
    end
  end
end
