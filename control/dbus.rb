require_relative "./dbus/modem"
require_relative "./dbus/feedback"
require_relative "./dbus/power"
require_relative "./dbus/geoclue2"
require_relative "./dbus/callaudio"
require_relative "./dbus/keyboard"

module HackOS
  module DBus
    class Container
      attr_reader :control

      def initialize(control)
        @control = control
      end

      def keyboard
        @keyboard ||= Keyboard.new(self)
      end

      def modem
        @modem ||= Modem.new(self, control)
      end

      def audio
        @audio ||= CallAudio.new(self)
      end

      def feedback
        @feedback ||= Feedback.new(self)
      end

      def geo
        @geo ||= GeoClue2.new(self)
      end

      def power
        @power ||= Power.new(self)
      end

      def osk
        @osk ||= Keyboard.new(self)
      end

      def next
        SDBus.system.next
        SDBus.user.next
      end
    end
  end
end
