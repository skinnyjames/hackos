module HackOS
  module Status
    class Bar < Hokusai::Block
      style <<-EOF
      [style]
      style {
        color: rgb(255,255,255);
        size: 14;
        width: 23.0;
      }
      labelContainer {
        padding: padding(10.0, 0.0, 0.0, 15.0);
      }
      labelStyle {
        color: rgb(255,255,255);
        size: 14;
      }
      background {
        background: rgb(0,0,0);
        cursor: "pointer";
      }
      EOF
      template <<-EOF
      [template]
      hblock { ...background  @tap="emit_open" }
        vblock { ...labelContainer }
          text { :content="current_time"  ...labelStyle }
        hblock { :width="86.0" }
          icon { type="signal" ...style }
          icon { type="wifi" ...style }
          icon { type="batteryfull" ...style }
      EOF

      uses(
        hblock: Hokusai::Blocks::Hblock,
        vblock: Hokusai::Blocks::Vblock,
        text: Hokusai::Blocks::Label,
        icon: Hokusai::Blocks::Icon
      )

      inject :current_time

      def emit_open(event)
        # if event.swipe_direction == :down
          emit("open")
        # end
      end

      def on_mounted
        node.meta.set_prop(:height, 35.0)
      end
    end
  end
end