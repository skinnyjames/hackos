module HackOS
  module DBus
    class CallAudio
      attr_reader :dbus, :container
      def initialize(container)
        @container = container
        @dbus = SDBus.user.service("org.mobian_project.CallAudio")
                          .object("/org/mobian_project/CallAudio")
                          .interface("org.mobian_project.CallAudio")
      end

      def speaker=(value)
        dbus.call("EnableSpeaker", [value])
      end

      def mute=(value)
        dbus.call("MuteMic", [value])
      end

      def regular!
        dbus.call("SelectMode", [0])
      end

      def voice!
        dbus.call("SelectMode", [1])
      end
    end
  end
end