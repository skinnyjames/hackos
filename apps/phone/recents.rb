module HackOS
  module Phone
    class RecentCall < Hokusai::Block
      style <<~EOF
      [style]
      container {
        outline: outline(0.0, 0.0, 2.0, 0.0);
        outline_color: rgb(92, 90, 97);
      }
      EOF
      template do
        child(Hokusai::Blocks::Vblock) do
          merge_styles "container"

          # call status with number
          child(Hokusai::Blocks::Hblock) do
            child(Hokusai::Blocks::Icon) do
              static :width, "100"
              prop :type do
                icon
              end

              prop :color do
                color
              end

              prop :size do
                theme.sizes.med
              end
            end
            
            child(Hokusai::Blocks::Vblock) do
              child(HackOS::Text) do
                prop :content do
                  number
                end

                prop :color do
                  color
                end

                prop :size do
                  theme.sizes.med
                end
              end

              child(HackOS::Text) do
                prop :content do
                  key
                end

                prop :color do
                  theme.colors.light
                end

                prop :size do
                  theme.sizes.small
                end
              end
            end
          end
        end
      end

      computed! :key
      computed! :record
      computed! :control
      computed! :theme

      def contact
        @contact ||= control.db.contacts.search(record["number"])
      end

      def number
        if contact
          contact["name"]
        else
          record["number"]
        end
      end

      def color
        case record["status"]
        when "missed"
          theme.colors.mainalt
        else
          Hokusai::Color.new(130,214,81)
        end
      end

      def icon
        case record["direction"]
        when "incoming"
          :phone_incoming
        when "outgoing"
          :phone_outgoing
        else
          :phone_both
        end
      end
    end

    class Recents < Hokusai::Block
      template do
        child(Hokusai::Blocks::Vblock) do
          prop :background do
            theme.colors.dark
          end

          prop :padding do
            Hokusai::Padding.new(50.0, 50.0, 0.0, 50.0)
          end

          child(HackOS::Panel) do
            each_child(HackOS::Phone::RecentCall, :recents) do |recent|
              static "height", "140.0"

              prop :key do
                "#{recent.value["time"]}-#{recent.value["number"]}-#{recent.value["status"]}"
              end

              prop :control do
                control
              end

              prop :theme do
                theme
              end

              
              prop :record do
                recent.value
              end
            end
          end
        end
      end

      def recents
        control.db.calls.list.reverse
      end

      inject :theme
      inject :control
      inject :dbus
    end
  end
end
