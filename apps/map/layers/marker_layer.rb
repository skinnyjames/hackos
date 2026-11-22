module HackOS::Maps
  class MarkerLayer < Hokusai::Block
    template <<~EOF
    [template]
      virtual
    EOF

    computed :marker, default: nil

    inject :zoom
    inject :center
    inject :container_size
    inject :tile_bounds

    def on_mounted
      node.meta.set_prop(:z, "3")
      node.meta.set_prop(:ztarget, "parent")
    end

    def render(canvas)
      return if marker.nil?

      draw do
        circle(marker.x, marker.y, 5) do |command|
          command.color = Hokusai::Color.new(44, 68, 224)
        end
      end
    end
  end
end