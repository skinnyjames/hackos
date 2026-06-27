module HackOS
  class Contacts
    attr_accessor :contacts

    def initialize(path)
      @contacts = JSON.parse(File.read(path))
      @path = path
    end

    def all
      @contacts
    end

    def <<(entry)
      @contacts << entry
    end

    def save
      File.open(path, "w") do |io|
        io << @contacts.to_json
      end
    end
  end
end