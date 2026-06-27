module HackOS
  class Input < Hokusai::Block
    template do
      child(Hokusai::Blocks::Vblock) do
        prop :padding do
          padding
        end
        
        prop :rounding do
          0.3
        end
        
        on :keypress do |event|
          if event.printable?
            @content << event.char
          else
            case event.symbol
            when :deleteleft
              @content.pop
            when :return
              @content << "\n"
            when :spacebar
              @content << " "
            end
          end

          emit("keypress", event)
          emit("update", @content.join(""))
        end

        prop :background do
          theme.colors.light
        end
        
        child(HackOS::Text) do
          prop :content do
            @content.empty? ? " " : @content.join("")
          end

          prop :padding do
            padding
          end

          prop :color do
            theme.colors.dark
          end

          prop :size do
            size
          end

          on :height_updated do |height|
            emit("height_updated", height)
            node.meta.set_prop(:height, height)
          end
        end
      end
    end

    inject :theme
    inject :control

    computed :clear, default: false
    computed :size, default: 30, convert: proc(&:to_i)
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding

    def initialize(**args)
      @content = []
      super
    end

    def after_updated
      @content.clear if clear
    end
  end
end
