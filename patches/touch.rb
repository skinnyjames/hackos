
class Hokusai::Blocks::ScissorBegin < Hokusai::Block
  template <<~EOF
  [template]
    slot
  EOF

  computed :offset, default: 0.0, convert: proc(&:to_f)
  computed :auto, default: true

  def render(canvas)
    draw do
      scissor_begin(canvas.x, canvas.y, canvas.width, canvas.height)
    end

    canvas.y -= offset if auto
    canvas.offset_y = offset

    yield canvas
  end
end

module Hokusai
  class Touch
    def released?
      @type == :released || @type == :none
    end
  end

  class Node
    def mount(klass, providers: {})
      NodeMounter.new(self, klass, previous_providers: providers).mount
    end
  end

  class Block
    def self.mount(name = "root", parent_node = nil, providers: {})
      compile(name, parent_node).mount(self, providers: providers)
    end
  end

  class Keyboard
    def set(key, down)
      if down
        case key
        when :left_shift, :right_shift
          @shift = true
        when :left_control, :right_control
          @control = true
        when :left_super, :right_super
          @super = true
        when :left_alt, :right_alt
          @alt = true
        end
      end

      if down && keys[key][:up]
        keys[key][:pressed] = true
        keys[key][:released]= false

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })
        
        @pressed << nkey
      elsif down
        keys[key][:pressed] = false
        keys[key][:released] = false
        keys[key][:down] = true

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })

        @down << nkey
      elsif !down && keys[key][:down]
        keys[key][:pressed] = false
        keys[key][:released] = true

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })

        @released << nkey
      else
        keys[key][:pressed] = false
        keys[key][:released] = false
      end

      keys[key][:down] = down
      keys[key][:up] = !down
    end
  end
end
