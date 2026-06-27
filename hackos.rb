
require_relative "./patches"
require_relative "./blocks"
require_relative "./control"
require_relative "./apps"

CONTROL = HackOS::Control.new

module HackOS
  class App < Hokusai::Block
    template <<-EOF
    [template]
    vblock
      [if="locked"]
        lockscreen
      [else]
        launcher
    keyboard
    EOF

    uses(
      vblock: Hokusai::Blocks::Vblock,
      lockscreen: Lockscreen,
      launcher: Launcher,
      keyboard: Keyboard,
    )

    provide :theme, :theme
    provide :control, :control
    provide :dbus, :dbus

    attr_reader :control

    def theme
      control.theme
    end

    def dbus
      control.dbus
    end

    def locked
      control.locked
    end

    def initialize(**args)
      @control ||= CONTROL
      @control.theme.apps # load apps
      @control.weather.fetch!

      super
    end
  end
end

APP_ICONS = {
  phone: "phone.png",
  files: "files.png",
  messages: "messages.png",
  settings: "settings.png",
  clock: "clock.png",
  maps: "maps.png",
  camera: "camera.png",
  calendar: "calendar.png",
  mail: "mail.png",
  photos: "photos.png",
}

CHARSET = "–—‘’“”…\r\n\t\s0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%%^&*()°,.?/\"\\[]-_=+|~`{}<>;:'"

Hokusai::Backend.run(HackOS::App) do |config|
  config.title = "hackos"
  config.fps = 60
  config.width = 720
  config.height = 1400
  config.config_flags = HP_FLAG_WINDOW_RESIZABLE
  config.audio = false
  config.touch = true
  config.event_waiting = false
  config.hot_reload = "hackos.rb"
  # config.log = true

  config.after_load do
    Hokusai.fonts.register "default", Hokusai::Backend::Font.from_ext("assets/boldy.ttf", 34 * 4, CHARSET)
    Hokusai.fonts.activate "default"

    Hokusai.fonts.register "icons", Hokusai::Backend::Font.from_ext("assets/material.ttf", 34 * 4, Hokusai::Blocks::Icon::MAP.values.join(""))

    Hokusai.images.register "wallpaper", Hokusai::Image.from_file("icons/wallpaper.png")
  end
end
