module HackOS
  module Phone
    class Menu < Hokusai::Block
      template do
        child(Hokusai::Blocks::Hblock) do
          # recents
          each_child(Hokusai::Blocks::Icon, :items) do |item|
            prop :type do
              item.value[:icon]
            end

            prop :size do
              theme.sizes.med
            end

            prop :key do
              "phone-menu-#{item.value[:name]}"
            end

            on :tap do |event|
              emit("switch", item.value[:app])
            end
          end
        end
      end

      def items
        [
          { name: "recents", icon: "home", app: HackOS::Phone::Recents },
          { name: "contacts", icon: "contact", app: HackOS::Phone::Contacts },
          { name: "dialer", icon: "dialpad", app: HackOS::Phone::Dialer },
          { name: "voicemail", icon: "voicemail", app: HackOS::Phone::Voicemail },
        ]
      end

      inject :theme

      def render(canvas)
        yield canvas
      end
    end
  end
end
