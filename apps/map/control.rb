module HackOS::Maps
  class Control
    GEOFFREY_URL = "https://geoffrey.skinnyjames.net/api/v1/us"
    ROUTING_URL = "https://routes.skinnyjames.net"

    attr_accessor :center, :center_changed, :zoom, :current_location,
                  :search_dest, :search_from, :search_intermediates,
                  :search_mode, :search_results, :search_results_error,
                  :current_dest, :current_directions, :dragging,
                  :min_zoom, :max_zoom, :errors, :current_route,
                  :bounds, :bounds_size, :canvas, :progress_info

    def initialize(center)
      @center = center # HackOS::Maps::LatLng
      @center_changed = false
      @bounds = nil # HackOS::TileBounds
      @bounds_size = nil
      @errors = {}

      @zoom = 1
      @search_dest = ""
      @search_from = nil
      @search_intermediates = []

      @search_results = []
      @search_results_error = nil
      @current_location = center
      @current_dest = nil
      @current_directions = nil
      @current_route = nil

      @dragging = false
      @min_zoom = nil
      @max_zoom = nil

      @canvas = nil

      reverse_geocode(current_location) do |response|
        if response.code != 200
          errors[:current] = "Network failure"
          next
        end
        results = response.body.json
        @search_from = label_for_address(results.first) unless results.empty?
      end
    end

    def end_route
      @progress_geojson = nil
      @progress_info = nil
      @progress = nil
      self.current_dest = nil
      self.search_dest = ""
      self.search_from = nil
      self.current_route = nil
      self.zoom = 6
    end

    def calculate_remaining(info)
      remaining = [[info[:snapped].lng, info[:snapped].lat]] + @progress.coords[(info[:index] + 1)..-1].map { |ll| [ll.lng, ll.lat] }

      self.current_route = {
        "type" => "LineString",
        "coordinates" => remaining
      }
    end

    def progress
      return nil unless @gps&.tick
      return nil unless @progress

      @progress_info = @progress.locate(LatLng.new(*@gps.coordinates))
    end

    attr_reader :gps

    def gps=(gps)
      @gps = gps
    end

    def update_progress(info, heading = nil)
      return unless @progress && info

      @progress_geojson = Maps::Routing.progress_geojson(@progress, info, current_dest, heading: heading || @gps.heading)
    end

    def route_progress
      @progress
    end

    def progress_geojson
      @progress_geojson
    end

    def progress
      if @gps&.tick
        @progress_info =  @progress.locate(LatLng.new(*@gps.coordinates))
        @progress_info
      end
    end

    def gps=(gps)
      @gps = gps
    end

    def directions(address)
      lat = address["latitude"]
      lng = address["longitude"]
      self.current_dest = LatLng.new(lat, lng)
      self.current_location = LatLng.new(*@gps.coordinates) if @gps && @gps.coordinates.compact.size == 2
      errors[:route] = nil
      route do |response|
        if response.code != 200
          errors[:route] = "Network error"
          next
        end

        self.search_results.clear
        json = response.body.json
        
        trip = json["trip"]
        coords = []
        maneuvers = []
        trip["legs"].each do |leg|
          base = coords.size
          coords.concat(Routing.decode(leg["shape"]))
          leg["maneuvers"].each do |m|
            maneuvers << m.merge(
              "begin_shape_index" => m["begin_shape_index"] + base,
              "end_shape_index" => m["end_shape_index"] + base
            )
          end
        end

        trip = json["trip"]
        coords = trip["legs"].flat_map { |leg| HackOS::Maps::Routing.decode(leg["shape"]) }
        maneuvers = trip["legs"].flat_map { |leg| leg["maneuvers"] }
        @progress = RouteProgress.new(coords, maneuvers)
        @progress_geojson = nil
        @progress_info = nil
        self.current_route = {
          "type" => "LineString",
          "coordinates" => coords.map { |ll| [ll.lng, ll.lat] }
        }
        self.zoom = 11
        # info = @progress.locate(current_location)
        # @gps = FakeGPS.new(coords, speed: 43.0, jitter: 8.0)
        # Hokusai.speak info[:next_maneuver]["verbal_pre_transition_instruction"]
      end
    end

    def search_results_error
      errors[:search]
    end

    def search(term)
      errors[:search] = nil
      geocode(term) do |response|
        if response.code != 200
          errors[:search] = "Network failure"

          next
        end

        results = response.body.json
        if results.empty?
          errors[:search] = "No results (don't forget to include a State)"

          next
        end

        self.search_results = results
      end
    end

    def search_width
      (canvas&.owidth || 80.0) - 60.0
    end

    def resize(canvas)
      @bounds_size = Bounds.new([canvas.x, canvas.y], [canvas.x + canvas.width, canvas.y + canvas.height])

      update_bounds!
    end

    def update_bounds!
      @bounds = TileBounds.new(HackOS::Maps::EPSG3857, center, bounds_size)
    end

    def center=(value)
      @center = value
      @center_changed = true
    end

    def center_point
      HackOS::Maps::EPSG3857.lat_lng_to_point(center, zoom)
    end

    def geocode(term, reciever = self, &block)
      req = Hokusai::Request.init(reciever, GEOFFREY_URL)
      req.execute("/geocode/#{CGI.escape(term)}", { method: "GET" }, &block)
    end

    def route(reciever = self, &block)
      value = {
        locations: [{ lat: current_location.lat, lon: current_location.lng}, {lat: current_dest.lat, lon: current_dest.lng}],
        costing: "auto",
        units: "miles",
        shape_format: "geojson"
      }.to_json

      encoded = CGI.escape(value)
      req = Hokusai::Request.init(reciever, ROUTING_URL)
      req.execute("/route?json=#{encoded}", { method: "GET" }, &block)
    end

    def label_for_address(address)
      capital = ->(str) do
        str ? str.downcase.gsub(/\b\w/) { |letter| letter.upcase } : nil
      end

      street = [
        address["address_number_prefix"],
        address["address_number"],
        address["address_number_suffix"],
        address["street_predirectional"],
        address["street_pretype"],
        capital.call(address["street_name"]),
        address["street_posttype"],
        address["street_postdirectional"]
      ].reject(&:nil?).join(" ")

      "#{street}#{address["unit"] ? " #{address["unit"]}" : ""}, #{capital.call(address["postal_community"])}, #{address["state"]} #{address["zip_code"]}"
    end

    def reverse_geocode(latlng, reciever = self, &block)
      req = Hokusai::Request.init(reciever, GEOFFREY_URL)
      req.execute("/reverse-geocode?lat=#{latlng.lat}&lng=#{latlng.lng}", { method: "GET" }, &block)
    end

    def search_mode_address!
      self.search_mode = :address
    end

    def search_mode_directions!
      self.search_mode = :directions
    end

    def zoom_in
      self.zoom = [zoom + 1, 20].min
    end

    def zoom_out
      self.zoom = [zoom - 1, 0].max
    end
  end
end