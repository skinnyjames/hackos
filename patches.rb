require_relative "./patches/icon"
require_relative "./patches/sdbus"
require_relative "./patches/timer"
require_relative "./patches/time"
require_relative "./patches/center"
require_relative "./patches/touch"
require_relative "./patches/http"
require_relative "./patches/label"

module Hokusai
  class Backend
    class Config
      def hot_reload=(topper)
        @i = 0
        @mtimes = {}
  
        on_reload do
          if @i >= 60
            @i = 0
            reload = false

            mtime = File::Stat.new(topper).mtime
            if !@mtimes[topper]
              @mtimes[topper] = mtime
            elsif @mtimes[topper] < mtime
              reload = true
              eval RubyResolver.new(topper).code, Backend.htop
              @mtimes[topper] = mtime
            end

            Reloader.new(topper).traverse do |file|
              mtime = File::Stat.new(file).mtime
              if !@mtimes[file]
                @mtimes[file] = mtime
              elsif @mtimes[file] < mtime
                reload = true
                eval RubyResolver.new(file).code, Backend.htop
                @mtimes[file] = mtime
              end
            end

            reload
          else
            @i += 1
            false
          end
        end
      end
    end
  end
end

module Hokusai::Util
  # A cache that stores the results of WrapStream.
  # Utiltiy methods are provided to quickly fetch a subset of tokens
  # Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens

    def bsearch(canvas)
      low = 0
      high = tokens.size - 1

      while low <= high
        return low if (low.zero? && high.zero?)
        mid = low + (high - low) / 2

        if matches(tokens[mid], canvas)
          return mid
        end

        if tokens[mid].y > canvas.y
          high = mid - 1
        end

        if tokens[mid].y < canvas.y
          low = mid + 1
        end
      end

      return nil
    end
  end
end


module Hokusai
  class Painter
    attr_reader :root, :input, :before_render, :after_render,
                :events

    # @return [Array(Commands::Base)] the command list
    def render(canvas, resize = false, capture: true)
      return if root.children.empty?
      input.keyboard.reset_new

      zindexed = {}
      zindex_counter = 0

      zroot_x = canvas.x
      zroot_y = canvas.y
      zroot_w = canvas.width
      zroot_h = canvas.height

      @root.on_resize(canvas) if resize

      before_render&.call([root, nil], canvas, input)

      # root_children = (canvas.reverse? ? root.children?&.reverse.dup : root.children?&.dup) || []
      groups = []
      root_entry = PainterEntry.new(root, canvas.x, canvas.y, canvas.width, canvas.height)
      groups << [root_entry, measure([root], canvas)]

      unless input.touch
        mouse_y = input.mouse.pos.y
        can_capture = mouse_y >= (canvas.y || 0.0) && mouse_y <= (canvas.y || 0.0) + canvas.height
      else
        can_capture = true
      end

      hovered = false
      while payload = groups.pop
        group_parent, group_children = payload
        
        parent_z = group_parent.block.node.meta.get_prop(:z)&.to_i
        zindex_counter -= 1 if (parent_z || 0) > 0 && group_children.empty?

        while group = group_children.shift
          z = group.block.node.meta.get_prop(:z)&.to_i || 0
          ztarget = group.block.node.meta.get_prop(:ztarget)

          if (zindex_counter > 0 || z > 0)
            pos = group.block.node.meta.get_prop(:zposition)
            pos = pos.nil? ? Hokusai::Boundary.default : Hokusai::Boundary.convert(pos)

            case ztarget
            when ZTARGET_ROOT
              entry = PainterEntry.new(group.block, (zroot_x || 0.0) + pos.left, (zroot_y || 0.0) + pos.top, zroot_w + pos.right, zroot_h + pos.bottom).freeze
            when ZTARGET_PARENT
              entry = PainterEntry.new(group.block, (group_parent.x || 0.0) + pos.left, (group_parent.y || 0.0) + pos.top, group_parent.w + pos.right, group_parent.h + pos.bottom).freeze
            else
              entry = PainterEntry.new(group.block, group.x + pos.left, group.y + pos.top, group.w + pos.right, group.h + pos.bottom).freeze
            end
          else
            entry = PainterEntry.new(group.block, group.x, group.y, group.w, group.h).freeze
          end

          canvas.reset(entry.x, entry.y, entry.w, entry.h)

          before_render&.call([group.block, group.parent], canvas, input)

          if resize
            group.block.on_resize(canvas)
          end

          breaked = false

          group.block.render(canvas) do |local_canvas|
            # defer capture for zindexed items so they can stop propagation.
            if capture && (zindex_counter.zero? && z.zero?)
              capture_events(group.block, local_canvas, hovered: hovered)
            # since evented styles happens during capture and z-index skips capture, well add some
            elsif capture && !input.touch && input.hovered?(local_canvas)
              if target = group.block.node.meta.target
                group.block.node.add_evented_styles(target.class, "hover")
              end
            end

            local_children = (local_canvas.reverse? ? group.block.children?&.reverse : group.block.children?)

            unless local_children.nil?
              groups << [group_parent, group_children]
              parent = PainterEntry.new(group.block, canvas.x, canvas.y, canvas.width, canvas.height)
              wrap = group.block.node.meta.get_prop(:wrap) || false

              groups << [parent, measure(local_children, local_canvas, wrap: wrap)]

              breaked = true
            else
              breaked = false
            end

            input
          end
          
          if z > 0
            zindex_counter += 1
            # puts ["start (#{z}) <#{parent_z}> {#{zindex_counter}} #{group.block.class}".colorize(:blue), z, group.block.node.portal&.ast&.id]
            zindexed[zindex_counter  ] ||= []
            zindexed[zindex_counter] << group
          elsif zindex_counter > 0
            zindexed[zindex_counter] ||= []
            # puts ["push (#{z}) <#{parent_z}>  {#{zindex_counter}} initial #{group.block.class}".colorize(:red), z, group.block.node.portal&.ast&.id]
            zindexed[zindex_counter] << group
          else
            # puts ["draw (#{z}) <#{parent_z}>  {#{zindex_counter}} #{group.block.class}".colorize(:yellow), z, group.block.node.portal&.ast&.id]
            group.block.execute_draw
          end


          break if breaked
        end
      end


      zindexed.sort.each do |z, groups|
        groups.uniq.each do |group|
          canvas.reset(group.x, group.y, group.w, group.h)
          capture_events(group.block, canvas)
          group.block.execute_draw
        end
      end

      if capture

        events[:hover].bubble
        events[:wheel].bubble
        events[:click].bubble
        events[:keyup].bubble
        events[:keypress].bubble
        events[:mousemove].bubble
        events[:mouseout].bubble
        events[:mousedown].bubble
        events[:mouseup].bubble
        events[:keydown].bubble


        unless input.touch.nil?
          events[:tap].bubble
          events[:doubletap].bubble
          events[:drag].bubble
          events[:taphold].bubble
          events[:pinchin].bubble
          events[:pinchout].bubble
          events[:swipe].bubble
          events[:taprelease].bubble
          events[:tapdown].bubble
          events[:tapup].bubble
        end
      end

      after_render&.call

    end
  end
end

module Hokusai
  class Keyboard
    attr_accessor :shift, :control, :super, :alt
    attr_reader :keys, :pressed, :released, :down

    def initialize
      @shift = false
      @control = false
      @super = false
      @alt = false
      @pressed = []
      @lpressed = []
    end

    def printable?
      symbol.nil?
    end

    def symbol
      pressed[0]&.[](:symbol)
    end

    def char
      pressed[0]&.[](:char)
    end

    def ctrl
      @control
    end

    def reset_new
      @pressed = @lpressed.dup
      @lpressed.clear

      @shift = false
      @control = false
      @super = false
      @alt = false
    end

    def reset
    end

    def set(key, down)
    end

    def set_new(key)
      if key.is_a?(Symbol)
        case symbol
        when :shift
          @shift = true
        when :control
          @control = true
        when :super
          @super = true
        when :alt
          @alt = true
        end
        
        @lpressed << { symbol: key, char: nil, pressed: true, down: true}
      else
        @lpressed << { down: true, char: key, pressed: true, symbol: nil}
      end
    end
  end
end

module Hokusai
  class Touch
    def set(event)
      @type = EVENTS[event]
      if @last && @last.x != @pos.x && @last.y != @pos.y && @type == :none && !(@pos.x == 0 && @pos.y == 0) && !(@last.x == 0 && @last.y == 0)
        @type = :tap
      end
      @last = @pos.dup
      @type
    end
  end
end
module Hokusai
  def self.copy_state(src, target)
    stack = [src]
    tstack = [target]

    while src_block = stack.pop
      if t_block = tstack.pop
        if stack.size > tstack.size
          # nodes have been removed
          # drop nodes until they match up again.
          while src_block.class != t_block.class
            src_block = stack.pop
          end

        elsif tstack.size > stack.size
          # nodes have been added
          # skip until they match up again
          while src_block.class != t_block.class
            t_block = tstack.pop
          end
        end

        if t_block.class == src_block.class 
          src_block.instance_variables.each do |var|
            unless var == :@node
              t_block.instance_variable_set(var, src_block.instance_variable_get(var))
            end
          end

          src_block.node.meta.props&.each do |k, v|
            t_block.node.meta.set_prop(k, v)
          end
        end

        tstack.concat t_block.children.reverse
      end

      stack.concat src_block.children.reverse
    end
  end
end