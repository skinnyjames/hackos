module HackOS
  module Phone
    class Key < Hokusai::Block
      template <<-EOF
      [template]
        empty {
          @tap="emit_clicked"
        }
      EOF

      uses(empty: Hokusai::Blocks::Empty)

      inject :theme
      computed! :key
      computed :size, default: 136, convert: proc(&:to_i)
      computed :background, default: nil

      def emit_clicked(event)
        emit(:clicked, event)
      end

      def centert(text, size, canvas)
        w, h = Hokusai.fonts.active.measure(text, size)
        hw = w / 2.0
        mid = canvas.x + canvas.width / 2
        midh = canvas.y + canvas.height / 2

        [mid - hw, midh - h / 2.0]
      end

      def render(canvas)
        x, y = centert(key[0], size, canvas)

        draw do
          rect(canvas.x + 3, canvas.y + 3, canvas.width - 3, canvas.height - 3) do |command|
            command.padding = Hokusai::Padding.new(5.0, 5.0, 5.0, 5.0)
            command.color = background if background
          end

          text(key[0], x, y) do |command|
            command.size = size
            command.color = theme.colors.light
          end

          if nums = key[1]
            nx, ny = centert(key[1], 34, canvas)

            text(nums, nx, y + size - 10) do |command|
              command.size =  34
              command.color = theme.colors.light
            end
          end
        end

        yield canvas
      end
    end
  end
end
