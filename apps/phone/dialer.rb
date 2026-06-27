require_relative "./dialer/key"

module HackOS
  module Phone
    class Dialer < Hokusai::Block
      style <<-EOF
      [style]
      phoneKey {
        width: 180.0;
        height: 180.0;
      }

      button {
        background: rgb(22,22,22);
      }

      buttonPrimary {
        background: rgb(45,45,45);
      }

      buttonSecondary {
        background: rgb(34,34,34);
      }

      phoneButton {
        background: rgb(0,0,0,0);
      }

      phoneButton@click {
        background: rgb(22,22,222);
      }
      EOF
      
      template do
        child(Hokusai::Blocks::Vblock) do
          prop :background do
            theme.colors.dark
          end

          prop :padding do
            Hokusai::Padding.new(20.0, 0.0, 60.0, 80.0)
          end

       
          child(AddContact) do
            show_if do
              @adding
            end

            on :close do
              @adding = false
            end
    
            prop :show do
              @adding
            end

            prop :number do
              dialing.empty? ? " " : dialing.join("")
            end
          end

          child(Hokusai::Blocks::Vblock) do
            prop :padding do
              Hokusai::Padding.new(90.0, 0.0, 0.0, 30.0)
            end

            static :width, "540.0"

            child(Hokusai::Blocks::Text) do
              prop :content do
                dialing.empty? ? " " : dialing.join("")
              end

              prop :size do
                theme.sizes.large
              end
            end
          end

          child(Hokusai::Blocks::Vblock) do
            static :height, "720.0"
            static :width, "540.0"

            child(Hokusai::Blocks::Hblock) do
              static :wrap, "true"

              each_child(Key, :keys) do |key|
                static :cursor, "'pointer'"
                prop :key do
                  key.value
                end

                prop :size do
                  theme.sizes.xlarge
                end

                prop :background do
                  if colors[key.value[0]]
                    colors.clear
                    theme.colors.mainalt
                  end
                end

                on :tap do
                  @colors[key.value[0]] = true
                  dialing << key.value[0]
                end
                
                merge_styles "phoneKey"
              end
            end 
          end

          # Dial buttons
          child(Hokusai::Blocks::Hblock) do
            merge_styles "button", "buttonPrimary"
            static "height", "90.0"
            static "width", "180.0"
            merge_styles "phoneButton"

            child(Hokusai::Blocks::Icon) do
              static "width", "180.0"
              prop :size do
                theme.sizes.med
              end

              prop :type do
                :account_plus
              end

              on :tap do |event|
                @adding = true
              end

              prop :color do
                theme.colors.light
              end
            end

            child(Hokusai::Blocks::Icon) do
              static "width", "180.0"
              prop :size do
                theme.sizes.med
              end

              prop :type do
                :phone
              end

              on :tap do |event|
                control.dbus.modem.dial(dialing.join(""))
                dialing.clear
              end

              prop :color do
                theme.colors.light
              end
            end

            child(Hokusai::Blocks::Icon) do
              static :type, "'deleteleft'"
              static "width", "180.0"

              on :tap do |event|
                dialing.pop  
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

      inject :control
      inject :theme

      attr_accessor :dialing

      def keys
        [
          %w[1],
          %w[2 abc],
          %w[3 def],
          %w[4 ghi],
          %w[5 jkl],
          %w[6 mno],
          %w[7 pqrs],
          %w[8 tuv],
          %w[9 wxyz],
          ["*", nil],
          ["0", "+"],
          ["#", nil]
        ]
      end

      def colors
        @colors ||= {}
      end

      def backgrounds
        @bgs ||= (0..12).map do |i|
          255 - (i * 10 * 2)
        end.to_a * 10

        @bgs
      end

      def contacts
        %w[Janesso Sean Bob Helen]
      end

      def initialize(**args)
        @call_status = :inactive
        @dialing = []
        @adding = false

        super
      end
    end
  end
end
