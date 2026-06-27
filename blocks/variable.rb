
module HackOS
  class Variable < Hokusai::Block
    template <<~EOF
    [template]
      empty
    EOF

    uses(empty: Hokusai::Blocks::Empty)

    computed! :klass

    inject :control
    inject :theme
    inject :dbus

    attr_accessor :last

    def after_updated
      if @last_height != children[0].node.meta.get_prop(:height)
        @last_height = children[0].node.meta.get_prop(:height)

        node.meta.set_prop(:height, @last_height)
        emit("height_updated", @last_height)
      end
    end

    def before_updated
      if last != klass
        self.last = klass
        app = klass

        node.meta.set_child(0, app)
      end
    end

    def on_mounted
      raise Hokusai::Error.new("Class #{klass} is not a Hokusai::Block") unless klass.is_a?(Hokusai::Block)
      self.last = klass
      app = klass
      node.meta.set_child(0, app)
    end

    def render(canvas)
      if Hokusai.can_render(canvas)
        yield canvas
      end
    end
  end
end