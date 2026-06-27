module HackOS
  class Text < Hokusai::Block
    template <<-EOF
    [template]
      virtual
    EOF

    computed! :content
    computed :static, default: false
    computed :font, default: nil
    computed :size, default: 20, convert: proc(&:to_i)
    computed :color, default: [22, 22, 22], convert: Hokusai::Color
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding

    inject :panel_offset
    inject :panel_height
    inject :panel_top

    attr_accessor :counter

    def initialize(**args)
      @counter = 0
      @last_content = nil

      super
    end

    def user_font
      font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
    end

    def top(canvas)
      panel_top || canvas.y
    end

    def panel_height_or_canvas_height(canvas)
      panel_height || canvas.height
    end

    def cache(canvas)
      return @cache if counter >= 2 && static

      @cache = begin
        cache = Hokusai::Util::WrapCache.new
        if canvas.y > panel_height_or_canvas_height(canvas)
          y = canvas.y + offset
        else
          y = canvas.y
        end

        stream = Hokusai::Util::WrapStream.new(canvas.width - padding.width, canvas.x, y) do |string, extra|
          if w = user_font.measure_char(string, size)
            [w, size]
          else
            [user_font.measure(string, size).first, size]
          end
        end

        stream.on_text do |wrapped|
          cache << wrapped
        end
        stream.wrap(content, nil)
        stream.flush

        if (stream.y - canvas.y).zero?
          height = size
        else
          height = (stream.y - canvas.y - offset + size).ceil
        end

        node.meta.set_prop(:height, height + padding.height)
        emit("height_updated", height + padding.height)
        @last_content = content

        cache
      end
    end

    def offset
      panel_offset || 0.0
    end

    def height(canvas)
      panel_height || canvas.height
    end

    def render(canvas)

      token_cache = cache(canvas) 
      tokens = token_cache.tokens_for(Hokusai::Canvas.new(canvas.width, height(canvas), canvas.x, canvas.y))
      tokens.each do |wrapped|
        if wrapped.y - canvas.y == 0
          y = canvas.y 
        else
          y = wrapped.y - offset  # for multiline wrap
        end

        # draw text
        text(wrapped.text, wrapped.x, y) do |command|
          command.color = color
          command.size = size
          if font
            command.font = user_font
          end
        end
      end

      self.counter += 1 if counter < 2
      yield canvas
    end
  end
end
