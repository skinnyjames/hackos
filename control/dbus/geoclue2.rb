module HackOS
  module DBus
    # Real location from GeoClue2 (system bus).
    #
    # Needs /etc/geoclue/geoclue.conf to allow the "hackos" desktop id:
    #   [hackos]
    #   allowed=true
    #   system=false
    #   users=
    # and GPS through ModemManager:
    #   [modem-gps]
    #   enable=true
    class GeoClue2
      SERVICE = "org.freedesktop.GeoClue2"
      DESKTOP_ID = "hackos"

      # RequestedAccuracyLevel: 8 = exact (GPS), 6 = street, 4 = city
      ACCURACY_EXACT = 8

      # used until the first fix arrives (and when GeoClue isn't available)
      FALLBACK = [39.976852, -83.05305]

      attr_reader :container, :latitude, :longitude, :accuracy,
                  :speed, :heading, :timestamp, :error

      def initialize(container)
        @container = container
        @latitude = nil
        @longitude = nil
        @accuracy = nil
        @speed = nil
        @heading = nil
        @timestamp = nil
        @error = nil
        @listeners = []

        start
      end

      # block receives self on every new fix
      def on_update(&block)
        @listeners << block
        block
      end

      def off_update(block)
        @listeners.delete(block)
      end

      def coordinates
        fix? ? [@latitude, @longitude] : FALLBACK
      end

      def fix?
        !@latitude.nil?
      end

      # under ~20m is almost certainly GPS; wifi/cell fixes are much coarser
      def gps?
        fix? && @accuracy && @accuracy < 20.0
      end

      # GeoClue reports -1.0 for unknown speed/heading
      def speed_known?
        @speed && @speed >= 0
      end

      def heading_known?
        @heading && @heading >= 0
      end

      def start
        manager = bus.object("/org/freedesktop/GeoClue2/Manager")
                     .interface("org.freedesktop.GeoClue2.Manager")

        @client_path = manager.call("GetClient")

        # DesktopId must be set before Start or GeoClue refuses the client
        set_client_prop("DesktopId", ["s", DESKTOP_ID])
        set_client_prop("RequestedAccuracyLevel", ["u", ACCURACY_EXACT])
        set_client_prop("DistanceThreshold", ["u", 0])
        set_client_prop("TimeThreshold", ["u", 0])

        client.on("LocationUpdated", &location_updated)
        client.call("Start")
      rescue => e
        # no GeoClue (desktop dev, not allowed in geoclue.conf, ...): keep the fallback
        @error = e
        p ["geoclue unavailable", e.class, e.message]
      end

      def stop
        client.call("Stop") if @client_path
      rescue => e
        @error = e
      end

      private

      def bus
        SDBus.system.service(SERVICE)
      end

      def client
        @client ||= bus.object(@client_path).interface("org.freedesktop.GeoClue2.Client")
      end

      def set_client_prop(name, variant)
        bus.object(@client_path)
           .interface("org.freedesktop.DBus.Properties")
           .call("Set", ["org.freedesktop.GeoClue2.Client", name, variant])
      end

      # LocationUpdated(o old, o new)
      def location_updated
        @location_updated ||= ->(args) do
          _old, path = args
          loc = bus.object(path).interface("org.freedesktop.GeoClue2.Location")

          @latitude = loc.get("Latitude")
          @longitude = loc.get("Longitude")
          @accuracy = loc.get("Accuracy")   # meters
          @speed = loc.get("Speed")         # m/s, -1 if unknown
          @heading = loc.get("Heading")     # degrees from north, -1 if unknown
          @timestamp = loc.get("Timestamp") # [seconds, microseconds]

          @listeners.each { |l| l.call(self) }
        end
      end
    end
  end
end