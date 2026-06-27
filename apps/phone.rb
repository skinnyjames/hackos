require_relative "./phone/dialer"
require_relative "./phone/call"
require_relative "./phone/contacts"
require_relative "./phone/recents"
require_relative "./phone/voicemail"
require_relative "./phone/menu"
require_relative "./phone/add_contact"

module HackOS
  module Phone
    class App < Hokusai::Block
      template <<-EOF
      [template]
        vblock
          [if="active"]
            variable { :klass="active" @switch="handle_switch" }
          menu { :height="100.0" @switch="handle_switch" }
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        variable: HackOS::Variable,
        menu: Menu,
        dialer: Dialer,
        call: Call,
      )

      inject :control
      inject :theme
      inject :dbus

      attr_accessor :active

      def handle_switch(klass)
        klass.provides.merge!(@injections)
        obj = klass.mount(@root, node, providers: @injections)
        self.active = obj
      end

      def on_destroy
        control.dbus.keyboard.hide
      end

      def initialize(**args)
        @active = nil
        super

        handle_switch(HackOS::Phone::Dialer)
      end
    end
  end
end