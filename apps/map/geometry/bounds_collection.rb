module HackOS::Maps
  class BoundsProxy
    attr_reader :map, :screen

    def initialize(screen, map)
      @map = map
      @screen = screen
    end

    def top_left
      screen.top_left
    end

    def bottom_right
      screen.bottom_right
    end
  end

  class BoundsProxyCollection
    include Enumerable

    attr_reader :bounds

    attr_accessor :offset
    
    def initialize
      @bounds = []
      @offset = Point.new(0, 0)
    end

    def each
      bounds.each do |b|
        yield b
      end
    end

    def <<(proxy)
      @bounds << proxy
    end

    def top_left
      bounds.map(&:top_left).min
    end

    def bottom_right
      bounds.map(&:bottom_right).max
    end

    def map_contains(point)
      bounds.find do |b|
        b.map.contains(point)
      end
    end

    def contains(point)
      bounds.find do |b|
        b.screen.contains(point)
      end
    end
  end
end
