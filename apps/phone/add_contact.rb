module HackOS
  class AddContact < Hokusai::Block
    template do
      child(Hokusai::Blocks::Vblock) do
        on :tap do |event|
          event.stop
        end

        on :taphold do |event|
          event.stop
        end

        prop :padding do
          Hokusai::Padding.new(300.0, 100.0, 300.0, 100.0)
        end

        child(Hokusai::Blocks::Dynamic) do
          child(Hokusai::Blocks::Label) do
            prop :size do
              theme.sizes.large
            end

            prop :content do
              "Add Contact"
            end

            prop :color do
              theme.colors.light
            end
          end

          child(Hokusai::Blocks::Label) do
            prop :size do
              theme.sizes.med
            end

            prop :content do
              number
            end

            prop :color do
              theme.colors.main
            end
          end

          child(HackOS::Input) do
            prop :color do
              theme.colors.dark
            end

            prop :size do
              theme.sizes.med
            end

            on :update do |str|
              @content = str
              @clear = false
            end

            prop :clear do
              @clear
            end
          end

          child(Hokusai::Blocks::Hblock) do
            static "height", "80.0"
            prop :padding do
              Hokusai::Padding.new(30.0, 0.0, 0.0, 0.0)
            end

            child(Hokusai::Blocks::Icon) do
              prop :type do
                :closecircle
              end

              on :tap do
                control.dbus.keyboard.hide
                emit("close")
              end

              prop :size do
                theme.sizes.med
              end

              prop :color do
                theme.colors.light
              end
            end

            child(Hokusai::Blocks::Icon) do
              prop :type do
                :save
              end

              on :tap do
                next if number.size < 10 || @content.empty?

                num = number.size == 10 ? "1#{number}" : number.to_s
                control.dbus.keyboard.hide
                control.db.contacts << { name: @content, number: num }
                control.db.contacts.save
                
                p control.db.contacts.all
                emit("close")
              end

              prop :size do
                theme.sizes.med
              end

              prop :color do
                theme.colors.light
              end
            end
          end
        end
      end
    end

    computed! :number
    computed :show, default: nil
    inject :theme
    inject :control

    def on_mounted
      node.meta.set_prop(:z, 1)
      node.meta.set_prop(:ztarget, "root")
      node.meta.set_prop(:zposition, Hokusai::Boundary.new(0.0, 0.0, 0.0, 0.0)) 
      control.dbus.keyboard.show
      control.dbus.keyboard.absolute = true
    end

    def render(canvas)
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = Hokusai::Color.new(22, 22, 22, 200)
        end
      end

      yield canvas
    end
  end
end