module HackOS::Maps
  class CRS
    class << self
      def get(code)
        {
          "EPSG3857" => EPSG3857,
        }
      end

      def lat_lng_to_point(latlng, zoom)
        point = projection.project(latlng)
        scale = scale(zoom)

        transformation.transform(point, scale)
      end

      def point_to_lat_lng(point, zoom)
        scale = scale(zoom)
        untransformed = transformation.untransform(point, scale)

        projection.unproject(untransformed)
      end

      def project(latlng)
      end

      def unproject(point)
      end

      def scale(zoom)
        256 * 2 ** zoom;
      end

      def zoom(scale)
      end

      def projected_bounds(zoom)
        b = projection.bounds
        s = scale(zoom)
        min = transformation.transform(b.min, s)
        max = transformation.transform(b.max, s)
        Bounds.new(min, max)
      end

      def wrap_lat_lng(latlng)
      end
    end
  end
end

require_relative "./crs/EPSG3857"
