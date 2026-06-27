module HackOS
  module DBus
    class Screen
      attr_reader :dbus, :container, :screen
      def initialize(container)
        @container = container
        @dbus = SDBus.user.service("org.gnome.SettingsDaemon.Power")
                         .object("/org/gnome/SettingsDaemon/Power")
        @screen = dbus.interface("org.gnome.SettingsDaemon.Power.Screen")
      end

      def brighten
        screen.call("StepUp")
      end

      def darken
        screen.call("StepDown")
      end
    end
  end
end
