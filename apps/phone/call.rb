
require_relative "./avatar"

module HackOS
  module Phone
    class Call < Hokusai::Block
      template do
        # information
        child(Hokusai::Blocks::Vblock) do
          static :height, "900"
          prop :background do
            theme.colors.dark
          end

          child(Hokusai::Blocks::Vblock) do
            child(Hokusai::Blocks::Center) do
              child(Avatar) do
                prop :animate do
                  call&.state == :ringing_in || call&.state == :ringing_out
                end
              end
            end
          
            child(Hokusai::Blocks::Vblock) do
              static :height, "200"
              child(Hokusai::Blocks::Center) do
                child(Hokusai::Blocks::Label) do
                  prop :color do
                    theme.colors.light
                  end

                  prop :size do
                    theme.sizes.large
                  end

                  prop :content do
                    name
                  end
                end
              end

              child(Hokusai::Blocks::Center) do
                show_if do
                  timestamp
                end

                child(Hokusai::Blocks::Label) do
                  prop :color do
                    theme.colors.light
                  end

                  prop :size do
                    theme.sizes.med
                  end

                  prop :content do
                    timestamp.to_s
                  end
                end
              end
            end
          end
        end

        # actions
        child(Hokusai::Blocks::Vblock) do
          prop :background do
            theme.colors.dark
          end
          child(Hokusai::Blocks::Icon) do
            on :tap do
              case call&.state 
              when :ringing_in
                call.accept
              when :active
                call.hangup
              when :ringing_out
                call.hangup
              end     
            end
            
            prop :type do
              case call&.state
              when :ringing_in
                :phone_classic
              when :active
                :phone_classic_off
              when :ringing_out
                :phone_classic_off
              else

                :phone_classic
              end
            end

            prop :size do
              theme.sizes.xlarge
            end

            prop :color do
              case call&.state
              when :ringing_in
                theme.colors.light
              when :active
                theme.colors.mainalt
              when :ringing_out
                theme.colors.mainalt
              else
                theme.colors.light
              end
            end
          end
        end
      end

      def timestamp
        if call&.started
          sec = (Time.now - call.started).round(0).to_i
          hours = sec / 3600
          minutes = (sec % 3600) / 60
          seconds = sec % 60

          "#{hours.to_s.rjust(2, "0")}:#{minutes.to_s.rjust(2, "0")}:#{sec.to_s.rjust(2, "0")}"
        end
      end

      def call
        control.dbus.modem.waiting || control.dbus.modem.active
      end

      def name
        control.db.contacts.search(number)&.dig("name") || number
      end

      def number
        call&.number || "Ending"
      end

      inject :theme
      inject :control
    end
  end
end
