module HackOS
  module Status
    class Menu < Hokusai::Block
      style <<-EOF
      [style]
      style {
        z: 1;
        ztarget: "parent";
        background: rgb(0,0,0);
        cursor: "pointer";
      }
      icon {
        width: 40.0;
        height: 40.0;
        size: 34;
        color: rgb(255,255,255);
      }
      padded {
        padding: padding(20.0, 0.0, 0.0, 20.0);
        width: 70.0;
      }
      EOF

      template <<-EOF
      [template]
        vblock { ...style @swipe="emit_close" }
          vblock { :height="80.0" }
            text { :content="current_time" size="12" }
          hblock { :height="80.0" }
            vblock { ...padded }
              icon { type="sun" ...icon }
            slider { @change="update_bright" min="0" max="100" step="1" }
          hblock { :height="80.0" }
            vblock { ...padded }
              icon { type="signal" ...icon }
            slider { min="0" max="100" step="1" }
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        hblock: Hokusai::Blocks::Hblock,
        empty: Hokusai::Blocks::Empty,
        text: Hokusai::Blocks::Text,
        slider: Hokusai::Blocks::Slider,
        icon: Hokusai::Blocks::Icon,
      )

      inject :current_time

      def update_bright(val)
        @val ||= val
      #   if val < @val
      #    p  bright.call("StepDown")
      #   else
      #   p  bright.call("StepUp")
      #   end
      end

      def emit_close(event)
        if event.swipe_direction == :up
          self.closing = true
          self.timer = Timer.new
        end
      end

      def on_mounted
        node.meta.set_prop(:z, nil)
        node.meta.set_prop(:height, 0)
      end

      def render(canvas)
        if @timer.elapsed?(0.08) && !closing
          node.meta.set_prop(:z, 2)
          node.meta.set_prop(:ztarget, "root")
        elsif !closing
          height = canvas.oheight * (@timer.elapsed * 5)
          node.meta.set_prop(:height, height)
          @timer.next
        elsif timer.elapsed? 0.08
          emit("close")
        else
          node.meta.set_prop(:z, nil)

          height = canvas.oheight * (timer.elapsed * 5)
          node.meta.set_prop(:height, canvas.oheight - height)
          @timer.next
        end

        yield canvas
      end

      attr_accessor :timer, :closing, :bright

      def initialize(**args)
        @timer = Timer.new
        @closing = false
        @bright = SDBus.user.service("org.gnome.SettingsDaemon.Power")
          .object("/org/gnome/SettingsDaemon/Power")
          .interface("org.gnome.SettingsDaemon.Power.Screen")
        super
      end
    end
  end
end
