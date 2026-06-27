module HackOS
  module Phone
    class Avatar < Hokusai::Block
      style <<~EOF
      [style]
      contactIcon {
        width: 136;
        height: 136;
      }
      EOF

      inject :theme
      computed :animate, default: false

      attr_accessor :circles

      template do
        child(Hokusai::Blocks::Icon) do
          static :type, "'contact'"

          merge_styles "contactIcon"

          prop :color do
            if animate
              theme.colors.dark
            else
              theme.colors.light
            end
          end

          prop :size do
            theme.sizes.xlarge
          end
        end
      end

      def on_mounted
        node.meta.set_prop(:width, 136.0)
        node.meta.set_prop(:height, 136.0)
      end

      def render(canvas)
        if animate
          if @timer.elapsed? 1
            4.times do |i|
              t = Timer.new
              t.start += i * 0.4
              circles << t

            end
            @timer.restart
          end

          sx = canvas.x + canvas.width / 2.0
          sy = canvas.y + canvas.height / 2.0
          base = theme.sizes.xlarge

          draw do
            circles.select! do |timer|
              size = base + 100 * timer.elapsed
              alpha = 200 * timer.elapsed
              timer.next
              if timer.elapsed? 1 || alpha >= 200 || size >= 226.0
                false
              else
                circle(sx, sy, size) do |command|
                  command.color = Hokusai::Color.new(225, 225, 225, 225 - alpha)
                end

                true
              end
            end
          end

          @timer.next
        end

        yield canvas
      end

      def initialize(**args)
        @circles = []
        @timer = Timer.new
        super
      end
    end
  end
end