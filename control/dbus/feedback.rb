module HackOS
  module DBus
    class Feedback
      attr_reader :dbus, :container

      def initialize(container)
        @container = container
        @dbus = SDBus.user.service("org.sigxcpu.Feedback")
                          .object("/org/sigxcpu/Feedback")
                          .interface("org.sigxcpu.Feedback")
      end

      def button(timeout = -1)
        dbus.call("TriggerFeedback", ["button-pressed", "button-pressed", {}, timeout])        
      end
      
      def incoming_call(timeout = -1)
        dbus.call("TriggerFeedback", ["net.hack.os", "phone-incoming-call", {}, timeout])
      end

      def stop(id)
        dbus.call("EndFeedback", [id])
      end
    end
  end
end