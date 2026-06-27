module HackOS
  class Panel < Hokusai::Block
    template <<~EOF
    [template]
      clipped {
        @tap="on_tapdown"
        @drag="on_taphold"
        @taphold="on_taphold"
        @taprelease="on_taprelease"
        :autoclip="autoclip"
        :offset="offset"
      }
        dynamic { @size_updated="set_size" }
          slot
    EOF

    uses(
      clipped: Hokusai::Blocks::Clipped,
      dynamic: Hokusai::Blocks::Dynamic,
    )

    computed :autoclip, default: false
    computed :align, default: :top
    computed :acceleration, default: 1.0, convert: proc(&:to_f)
    computed :friction, default: 0.80, convert: proc(&:to_f)
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding

    provide :panel_top, :panel_top
    provide :panel_offset, :offset
    provide :panel_height, :panel_height

    attr_accessor :top, :offset, :clipped_content_height, :panel_height

    def on_tapdown(event)
      @last_y = event.pos.y
      @last_time = Hokusai.monotonic
      @drag_vy = 0.0
      @velocity = nil
    end

    def on_taphold(event)
      return unless @last_y

      now = Hokusai.monotonic
      dt = now - @last_time
      delta = (@last_y - event.pos.y) * acceleration

      if dt > 0.0001
        raw_v = delta / dt
        if @drag_vy != 0.0 && (raw_v > 0) != (@drag_vy > 0)
          @drag_vy = 0.0
        end
        @drag_vy = @drag_vy * 0.3 + raw_v * 0.7
      end

      @last_y = event.pos.y
      @last_time = now

      clamp_offset(delta)
    end

    def on_taprelease(event)
      if @drag_vy && @drag_vy.abs > 20.0
        @velocity = @drag_vy * 0.016
      end
      @last_y = nil
      @last_time = nil
      @drag_vy = 0.0
    end

    def clamp_offset(delta)
      return if content_height <= panel_height
      new_offset = offset + delta
      if new_offset < panel_top
        self.offset = 0.0
        @drag_vy = 0.0
        @velocity = nil
      elsif new_offset > content_height - panel_height
        self.offset = content_height - panel_height
        @drag_vy = 0.0
        @velocity = nil
      else
        self.offset = new_offset
      end
    end

    def momentum
      @velocity *= friction
      if @velocity.abs < 0.2
        @velocity = nil
        return
      end
      clamp_offset(@velocity * 16)
    end

    def content_height
      clipped_content_height
    end

    def panel_top
      top || 0.0
    end

    def set_size(_, height)
      if panel_height != clipped_content_height || clipped_content_height.zero?
        self.clipped_content_height = height < panel_height ? panel_height : height
      end

      if align == :bottom && @last_height != height
        @last_height = height
        clamp_offset(panel_height)
      end
    end

    def initialize(**args)
      @top = nil
      @offset = 0
      @clipped_content_height = 0
      @panel_height = 0
      @drag_vy = 0.0
      @velocity = nil
      @last_y = nil
      @last_time = nil
      @count = 0
      @last_height = nil

      super
    end

    def render(canvas)
      self.top ||= canvas.y
      self.panel_height = canvas.height

      momentum if @velocity
      yield canvas
    end
  end
end