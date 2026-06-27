module HackOS
  class MessagesText < Hokusai::Block
    template <<-EOF
    [template]
      virtual
    EOF

    computed! :messages
    computed! :theme
    computed :font, default: nil
    computed :size, default: 20, convert: proc(&:to_i)
    computed :color, default: [22, 22, 22], convert: Hokusai::Color
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding

    inject :panel_offset
    inject :panel_height
    inject :panel_top

    def user_font
      font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
    end

    def top(canvas)
      panel_top || canvas.y
    end

    def panel_height_or_canvas_height(canvas)
      panel_height || canvas.height
    end

    def offset
      panel_offset || 0.0
    end

    def height(canvas)
      panel_height || canvas.height
    end

    def render(canvas)
      if canvas.y > panel_height_or_canvas_height(canvas)
        y = canvas.y + offset
      else
        y = canvas.y
      end

      stream = Hokusai::Util::WrapStream.new(canvas.width - padding.width - 100.0, canvas.x, y) do |string, extra|
        if w = user_font.measure_char(string, size)
          [w, size]
        else
          [user_font.measure(string, size).first, size]
        end
      end

      oy = y + padding.top
      px = 10.0
      py = 10.0

      extra = 0.0

      draw do
        stream.on_text do |wrapped|
          if wrapped.extra == :done
            oy += 30.0
            extra += 30.0
            next
          end

          direction = wrapped.extra['direction']
          ow = canvas.width - 100.0 - 10.0
    
          oh = wrapped.height + padding.height + 20.0

          if direction == 'incoming'
            wrapcolor = theme.colors.mainalt
            ox = wrapped.x + padding.left
          else
            ox = wrapped.x + 100.0
            wrapcolor = theme.colors.main
          end

          rect(ox, oy, ow + px, oh + py) do |command|
            command.color = wrapcolor
            command.round = 0.3
          end
          
          text(wrapped.text,  ox + padding.left + px, oy + padding.top + py) do |command|
            command.color = color
            command.size = size
            command.font = user_font if font
          end

          oy += wrapped.height + 10.0
          extra += 10.0
        end
      end

      messages.each do |message|
        stream.wrap(message['content'], message)
        stream.wrap("\n", :done)
      end

      stream.flush

      if (stream.y - canvas.y).zero?
        height = size
      else
        height = (stream.y - canvas.y + extra + size).ceil
      end

      node.meta.set_prop(:height, height + padding.height)
      emit("height_updated", height + padding.height)

      yield canvas
    end
  end
end
