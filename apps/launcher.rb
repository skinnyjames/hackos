require_relative "./launcher/homescreen"

module HackOS
  class Launcher < Hokusai::Block
    style <<-EOF
    [style]
    actions {
      height: 100.0;
      background: rgb(22, 22, 22);
    }
    icon {
      size: 40.0;
      color: rgb(244,244,244);
    }
    EOF

    template <<-EOF
    [template]
    vblock
      [if="active"]
        vblock
          variable { :klass="active" }
          hblock { ...actions }
            vblock { @tap="exit_active" }
              icon { ...icon type="exittoapp"}
            vblock { @tap="close_active" }
              icon { ...icon type="closecircle"}
      [else]
        homescreen { @open="launch" :active="currents" }
    EOF

    uses(
      hblock: Hokusai::Blocks::Hblock,
      vblock: Hokusai::Blocks::Vblock,
      center: Hokusai::Blocks::Center,
      icon: Hokusai::Blocks::Icon,
      variable: Variable,
      homescreen: Homescreen,
      keyboard: Keyboard
    )

    inject :control
    inject :theme
    inject :dbus

    attr_reader :currents, :timer
    attr_accessor :active, :last

    def close_active(event)
      # run teardown
      active.before_destroy if active.respond_to?(:before_destroy)
      control.dbus.keyboard.hide

      currents.delete_if do |k, v|
        v == active
      end
      
      self.active = nil
    end

    def exit_active(event)
      self.active = nil
    end

    def launch(app) 
      if current = currents[app]
        self.active = current
      else
        # mount and setup events
        self.active = begin
          config = control.theme.apps.find do |config|
            config["name"] == app
          end

          klass = eval config["class"]
          klass.provides.merge!(@injections)
          obj = klass.mount("root", node, providers: @injections)
          obj
        end

        currents[app] = active
      end
    end

    def initialize(**args)
      @currents = {}
      @active = nil
      @timer = Timer.new

      super
    end

    # poll for any pending phone calls
    def render(canvas)
      if control.dbus.keyboard.on && !control.dbus.keyboard.absolute
        node.meta.set_prop(:height, 1400.0 - 430.0)
      else
        node.meta.set_prop(:height, nil)
      end

      control.dbus.next
      
      if timer.elapsed?(0.5)
        if control.dbus.modem.waiting || control.dbus.modem.active
          currents[:call] ||= begin
            klass = HackOS::Phone::Call
            klass.provides.merge!(@injections)
            obj = klass.mount("root", node, providers: @injections)
            obj
          end

          self.active = currents[:call]
        else
          if currents[:call]
            p "deleting call"
            self.active = nil
            currents.delete(:call) 
            p "after delete call"
          end
        end

        timer.restart
      end

      timer.next

      yield canvas
    end
  end
end
