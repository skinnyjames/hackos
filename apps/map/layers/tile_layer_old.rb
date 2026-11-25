
module HackOS::Maps
  class TileLayer < Hokusai::Block
    template <<~EOF
    [template]
      empty {
        @drag="drag"
      }
    EOF

    uses(
      empty: Hokusai::Blocks::Empty
    )

    computed! :url
    computed :tile_size, default: 256, convert: proc(&:to_i)
    computed :min_zoom, default: 0, convert: proc(&:to_i)
    computed :max_zoom, default: 18, convert: proc(&:to_i)
    computed :subdomains, default: ['a', 'b', 'c']
    computed :error_tile_url, default: ''
    computed :zoom_offset, default: 9, convert: proc(&:to_i)
    computed :tms, default: false
    computed :zoom_reverse, default: false
    computed :detect_retina, default: false
    computed :cross_origin, default: false
    computed :referrer_policy, default: false

    inject :zoom
    inject :center
    inject :container_size
    inject :tile_bounds

    attr_reader :tiles, :levels, :size, :update_interval, :dragging

    def initialize(**args)
      super

      @tiles = {}
      @dragging = false
      @drag_start = nil
    end

    def drag(event)
      unless @drag_start
        @drag_start = Point.new(event.pos.x, event.pos.y)
      end
  
      tile_bounds.drag_offset = Point.new(event.pos.x, event.drag.pos.y) - @drag_start
      @last = tile_bounds.coords_at(tile_bounds.screen_bounds.center, zoom)
      end_drag
    end

    def end_drag
      if @drag_start
        @dragging = false
        if tile_bounds.drag_offset.x > 5 || tile_bounds.drag_offset.y > 5

          collection = tile_bounds.collection(zoom)
          off = tile_bounds.drag_offset

          c = tile_bounds.screen_bounds.center

          center = tile_bounds.coords_at(c, zoom)

          tile_bounds.drag_offset = Point.new(0, 0)
          tile_bounds.center = center

          emit("update", center)
        end
        
        @drag_start = nil
      end
    end

    def downloads
      "./downloads"
    end

    def headers
      {
        "Referrer" => "skinnyjames.net", 
        "Referrer-Policy" => "strict-origin-when-cross-origin", 
        "User-Agent" => "Hokusai/1.4 (+https://hokusai.skinnyjames.net; contact: zero@skinnyjames.net)"
      }
    end

    def fetch_download(url)
      path = "#{downloads}/#{url.gsub("/", "")}"

      if File.exist?(path)
        @tiles[url] ||= Hokusai::Image.from_file(path)
        return @tiles[url]
      else
        fetch(url, { method: "GET", headers: headers}) do |res|
          File.open(path, "wb") do |io|
            res.body.on_read do |content|
              io << content
            end
          end


          @tiles[url] ||= Hokusai::Image.from_file(path)
        end
        nil
      end
    end

    def subdomain(coords)
      index = (coords.x + coords.y % subdomains.size).abs
      subdomains[index]
    end

    def zoom_for_url
      if zoom_reverse
        max_zoom - zoom
      else
        zoom + zoom_offset
      end
    end

    # https://{s}.somedomain.com/blabla/{z}/{x}/{y}{r}.png'
    def tile_url(coords)
      opts = {
        s: subdomain(coords),
        z: zoom_for_url,
        x: coords.x.to_i,
        y: coords.y.to_i,
        r: ''
      }
      
      url.gsub(/\{ *([\w_ -]+) *\}/) do |match|
        opts[match[1].to_sym].to_s
      end    
    end

    def render(canvas)
      # @canvas = canvas
      collection = tile_bounds.collection(zoom)
      offx = collection.offset.x
      offy = collection.offset.y

      draw do
        collection.each_with_index do |item, i|
          if file = fetch_download(tile_url(item.map.center))
            image(file, item.screen.center.x - offx.to_f, item.screen.center.y - offy.to_f, tile_size.to_f, tile_size.to_f) {}
          end
        end
      end

      yield canvas
    end
  end
end