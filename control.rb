require_relative "./control/dbus"
require_relative "./control/database"
require_relative "./control/theme"
require_relative "./control/weather"
require_relative "./control/calls"
require_relative "./control/contacts"

module HackOS
  class Control
    def self.build(&block)
      control = new
      yield control
      control
    end

    attr_reader :theme, :calls, :contacts

    def initialize
      @theme ||= Theme.new("theme.json")
    end

    def locked
      false
    end

    def flashlight=(val)
      num = val ? "1" : "0"
      IO.popen("echo #{num} | tee /sys/class/leds/white:flash/brightness")
    end

    def current_date
      Time.now.strftime("%b %e %Y")
    end

    def current_time
      Time.now.strftime("%b %e %Y @ %l:%M %p")
    end

    def weather
      @weather ||= Weather.new(self)
    end

    def db
      @db ||= Database::Container.new
    end

    def dbus
      @dbus ||= DBus::Container.new(self)
    end

    def theme=(path)
      @theme = Theme.new(path)
    end
  end
end
