module HackOS
  class Calls
    attr_accessor :calls

    def initialize(path)
      @calls = JSON.parse(File.read(path))
      @path = path
    end
    
    def all
      @calls
    end

    def missed
      all.select do |call|
        call["status"] == "missed"
      end
    end

    def received
      all.select do |call|
        call["status"] == "connected"
      end
    end

    def <<(entry)
      @calls.unshift entry
      @calls = @calls[0..50] if @calls.size > 50
    end

    def save
      File.open(path, "w") do |io|
        io << @calls.to_json
      end
    end 
  end
end