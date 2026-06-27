module HackOS
  module DBus
    class Keyboard
      attr_reader :container
      attr_accessor :absolute

      def initialize(container)
        @container = container
        @show = false
        @absolute = false
      end

      def on
        @show
      end

      def toggle
        @show = !@show
      end

      def show
        @show = true 
      end

      def hide
        @show = false
        @absolute = false
      end
    end
  end
end