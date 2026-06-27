module HackOS
  module Phone
    class Contacts < Hokusai::Block
      template do
        child(Hokusai::Blocks::Vblock) do
          prop :background do
            theme.colors.dark
          end

          child(HackOS::Panel) do
            each_child(Hokusai::Blocks::Vblock, :contacts) do |contact|
              prop :key do
                "#{contact.value["name"]}-#{contact.value["number"]}"
              end

              prop :padding do
                Hokusai::Padding.new(20.0, 40.0, 20.0, 40.0)
              end

              static "height", "130.0"

              child(Hokusai::Blocks::Hblock) do
                prop :padding do
                  Hokusai::Padding.new(0.0, 40.0, 0.0, 0.0)
                end
                
                child(Hokusai::Blocks::Vblock) do

                  child(HackOS::Text) do
                    prop :content do
                      contact.value["name"]
                    end

                    prop :size do
                      theme.sizes.med
                    end

                    prop :color do
                      theme.colors.light
                    end
                  end

                  child(HackOS::Text) do
                    prop :content do
                      contact.value["number"]
                    end

                    prop :size do
                      theme.sizes.small
                    end

                    prop :color do
                      theme.colors.main
                    end
                  end
                end

                child(Hokusai::Blocks::Icon) do
                  static :width, "90.0"

                  on :tap do |event|
                    control.dbus.modem.dial(contact.value["number"])
                  end

                  prop :type do
                    :phone
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
      end

      inject :control
      inject :theme

      def contacts
        control.db.contacts.list
      end
    end
  end
end
