require_relative "./earth"

module HackOS::Maps
  class EPSG3857 < Earth
    class << self
      def projection
        SphericalMercator
      end

      def transformation
        @transformation ||= begin
          scale = 0.5 / (Math::PI * SphericalMercator::R)
          Transformation.new(scale, 0.5, -scale, 0.5)
        end
      end
    end
  end
end