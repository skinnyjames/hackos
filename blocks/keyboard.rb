module HackOS
  class Keyboard < Hokusai::Block
    template <<-EOF
    [template]
      empty {
        @tap="set_coords"
        @taphold="prevent"
        @swipe="swipey"
        @pinchin="prevent"
        @pinchout="prevent"
      }
    EOF

    uses(
      empty: Hokusai::Blocks::Empty
    )
    
    inject :control
    inject :theme
    computed :override, default: false

    attr_accessor :coords, :mode
    attr_reader :widths

    def swipey(event)
      if event.swipe_direction == :up
        control.dbus.keyboard.hide
      end

      event.stop
    end

    def prevent(event)
      event.stop
    end

    def release(event)
      @last = event.pos
    end

    def set_coords(event)
      @coords = [event.pos.x, event.pos.y]

      event.stop
    end

    def initialize(**args)
      @coords = []
      @mode = :letters
      @widths = {}

      super
    end

    def render(canvas)
      if control.dbus.keyboard.on || override
        node.meta.set_prop(:height, 430.0)
        node.meta.set_prop(:width, nil)

        # if control.dbus.keyboard.absolute
        node.meta.set_prop(:z, 999)
        node.meta.set_prop(:ztarget, "root")
        node.meta.set_prop(:zposition, Hokusai::Boundary.new(canvas.height - 430.0, 0.0, 0.0, 0.0))
        # end
      else
        node.meta.set_prop(:width, 0.0)
        node.meta.set_prop(:height, 0.0)
        node.meta.set_prop(:z, nil)
        @mode = :letters
        
        return
      end
      tappedchar = nil

      case mode
      when :capitals
        rows = [
          %w[Q W E R T Y U I O P],
          %w[A S D F G H J K L],
          [:shift, %w[Z X C V B N M], :deleteleft].flatten,
          [:numeric, ",", :spacebar, ".", :return]
        ]
      when :letters
        rows = [
          %w[q w e r t y u i o p],
          %w[a s d f g h j k l],
          [:shift, %w[z x c v b n m], :deleteleft].flatten,
          [:numeric, ",", :spacebar, ".", :return]
        ]
      when :numbers
        rows = [
          %w[1 2 3 4 5 6 7 8 9 0],
          %w[@ # $ _ & - + ( ) /],
          [:symbol, %w[* " ' : ; ! ?], :deleteleft].flatten,
          [:alpha, ",", :spacebar, ".", :return]
        ]
      when :symbols
        rows = [
          ["Ctrl", "Alt"].flatten,
          [:arrowleft, %w[~ ` | * < >], :arrowright].flatten,
          [:numeric, %w[% [ ] { } = \ /], :deleteleft].flatten,
          [:alpha, ",", :spacebar, ".", :return]
        ]
      end

      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.padding = Hokusai::Padding.new(10.0, 0.0, 10.0, 0.0)
          command.color = Hokusai::Color.new(22, 22, 22, 255)
        end

        y = canvas.y + 10.0
        x = canvas.x
        w = 65.0
        h = 90.0

        rows.each_with_index do |row, idx|
          if idx == 1 && (mode == :letters || mode == :capitals)
            x += w / 2.0
          elsif idx == 2
            x += 12.0
          elsif idx == 3
            x += 5.0
          end

          row.each do |char|
            w = 65.0
            tapped = false
            
            if char.is_a?(Symbol)
              font = Hokusai.fonts.get("icons")
              codepoint = Hokusai::Blocks::Icon::MAP[char]
              if char == :spacebar
                cw = 65.0
                w = 350.0
              elsif widths[codepoint]
                cw = widths[codepoint]
              else
                cw, _ = font.measure(codepoint, theme.sizes.med)
                widths[codepoint] = cw
              end
            elsif widths[char]
              cw = widths[char]
              w = cw + 40.0 if char == "Ctrl" || char == "Alt"
            else
              cw, _ = Hokusai.fonts.active.measure(char, theme.sizes.med)
              widths[char] = cw
            end
            
            unless coords.empty?
              ccx, ccy = coords

              # click symbol
              if ccx >= x && ccy >= y && ccx <= x + w + 20.0 && ccy <= y + h
                case char
                when :shift
                  case mode
                  when :letters
                    @mode = :capitals
                  else
                    @mode = :letters
                  end
                when :numeric
                  @mode = :numbers
                when :alpha
                  @mode = :letters
                when :symbol
                  @mode = :symbols
                else
                  tappedchar = char
                end
                tapped = true
              end
            end

            if char.is_a?(Symbol)  
              rect(x, y, w + 20.0, h) do |command|
                command.color = tapped ? theme.colors.mainalt : Hokusai::Color.new(111,111,111,100)
                command.round = 0.2
              end

              text(codepoint, x + (w - cw + 20) / 2.0, y + 15.0) do |command|
                command.color = theme.colors.light
                command.size = theme.sizes.med
                command.font = font
              end

              x += w + 30.0
            else
              rect(x, y, w, h) do |command|
                command.color = tapped ? theme.colors.mainalt : Hokusai::Color.new(111,111,111,100)
                command.round = 0.2
              end

              text(char, x + (w - cw) / 2.0, y + (h - theme.sizes.med) / 2.0) do |command|
                command.color = theme.colors.light
                command.size = theme.sizes.med
              end

              x += w + 8.0
            end
          end

          x = canvas.x
          y += h + 10.0
        end
      end

      @coords = []
      input = yield canvas

      unless tappedchar.nil?
        input.keyboard.set_new(tappedchar) 
        control.dbus.feedback.button
      end
    end
  end
end
