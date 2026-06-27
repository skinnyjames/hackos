require_relative "./moving_icon"
require_relative "./weather"

module HackOS
  class Homescreen < Hokusai::Block
    style <<-EOF
    [style]
    appIcon {
      width: 228.0;
      height: 228.0;
      padding: padding(50.0, 50.0, 50.0, 50.0);
    }
    container {
      padding: padding(80.0, 0.0, 0.0, 80.0);
    }
    EOF

    template do
      child(HackOS::Panel) do
        on :taprelease do
          if pressing
            self.pressing = nil
            control.theme.save
          end
        end

        child(Hokusai::Blocks::Vblock) do
          static :height, "300.0"

          
          child(WeatherWidget) do
            on :tap do
              if @on == false
                control.flashlight = true
                @on = true
              else
                control.flashlight = false
                @on = false
              end
            end
          end
        end

        child(Hokusai::Blocks::Hblock) do
          static :wrap, "true"
          static :width, "684.0"
          static :height, "2000.0"

          each_child(MovingIcon, :apps) do |app|
            merge_styles "appIcon"

            prop :active do
              !!active[app.value["name"]]
            end

            prop :key do
              "app-#{app.value["name"]}"
            end

            prop :name do
              "icon-#{app.value["name"]}"
            end

            prop :moving do
              pressing && pressing["name"] == app.value["name"] ? "t" : "f"
            end

            prop :width do
              pressing && pressing["name"] == app.value["name"] ? 240.0 : 228.0
            end

            prop :height do
              pressing && pressing["name"] == app.value["name"] ? 240.0 : 228.0
            end

            on :tap do
              @tapped = true
            end

            on :taprelease do
              emit("open", app.value["name"]) if @tapped

              @tapped = false
            end

            on :taphold do |event|
              if event.duration > 0.3
                event.stop
                @tapped = false
                control.dbus.feedback.button(1)
                self.pressing = app.value
              end
            end

            # prevent opening the app on swipe
            on :swipe do |event|
              @tapped = false

              event.stop if pressing
            end

            on :drag do |event|
              # prevent panel from dragging while moving an icon
              event.stop if pressing
            end

            on :tapdown do |event|
              if pressing
                move(pressing["name"], app.value["name"])
              end
            end
          end
        end
      end
    end

    inject :theme
    inject :control

    computed! :active

    attr_accessor :pressing

    def initialize(**args)
      @pressing = nil

      super
    end

    def move(from, to)
      return if from == to
      targetidx = apps.index { |app| app["name"] == to }
      app = apps.find{ |app| app["name"] == from }
      apps.delete(app)
      apps.insert(targetidx, app)
    end

    def apps
      theme.apps
    end

    def render(canvas)
      image(Hokusai.images.get("wallpaper"), canvas.x, canvas.y, canvas.width, canvas.height) do |command|
      end

      yield canvas
    end
  end
end
