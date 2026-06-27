module HackOS
  module DBus
    class GeoClue2
      attr_reader :dbus, :container

      def initialize(container)
        @container = container
        # @dbus = SDBus.user.service("org.freedesktop.GeoClue2")
        #                   .object("/org/freedesktop/GeoClue2/Manager")
        #                   .interface("org.freedesktop.GeoClue2.Manager")
      end

      def coordinates
        [39.976852, -83.05305]
      end
    end
  end
end