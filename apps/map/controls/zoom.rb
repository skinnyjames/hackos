module HackOS::Maps
  module Controls
    class Zoom < Hokusai::Block
      style <<~EOF
      [style]
      container {
        background: rgb(206, 206, 206);
        outline: outline(1.0, 1.0, 1.0, 1.0);
        outline_color: rgb(136, 136, 136);
        rounding: 0.2;
      }

      border {
        outline: outline(0.0, 0.0, 1.0, 0.0);
        outline_color: rgb(136, 136, 136);
      }

      zoomIn {
        content: "+";
        size: 20;
        padding: padding(10.0, 0.0, 0.0, 12.5);
      }

      zoomOut {
        content: "-";
        size: 20;
        padding: padding(10.0, 0.0, 0.0, 12.5);
      }
      EOF
      
      template <<~EOF
      [template]
        vblock {
          @mousedown="stop"
          @mouseup="stop"
          ...container
        }
          rect.zoomin {
            @click="emit_zoom_in"
            ...border
          }
            label { ...zoomIn }
          rect.zoomout {
            @click="emit_zoom_out"
          }
            label { ...zoomOut }
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        rect: Hokusai::Blocks::Rect,
        label: Hokusai::Blocks::Label
      )

      def stop(event)
        # p["stopping", event.captures.map(&:class)]
        event.stop
      end

      def emit_zoom_in(event)
        p ["clicked zoomin"]
        event.stop
        emit("zoomin")
      end

      def emit_zoom_out(event)
        p ["clicked zoomout"]
        event.stop
        emit("zoomout")
      end

      def render(canvas)
        canvas.x += 10.0
        canvas.y += 10.0
        canvas.width = 35.0

        yield canvas
      end
    end
  end
end