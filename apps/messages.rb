module HackOS
  module Messages
    class Message < Hokusai::Block    
      template <<~EOF
      [template]
        hblock { padding="20.0,0.0,20.0,0.0" }
          empty { :width="outwidth" }
          vblock {
            :padding="padding"
            :background="background"
            :rounding="0.2"
            :width="600.0"
          }
            text {
              :size="theme.sizes.small"
              :content="content"
              :color="theme.colors.light"
              @height_updated="height_updated"
            }
      EOF

      uses(
        hblock: Hokusai::Blocks::Hblock,
        vblock: Hokusai::Blocks::Vblock,
        text: HackOS::Text,
        empty: Hokusai::Blocks::Empty,
      )

      computed! :direction
      computed! :content
      computed! :theme

      def height_updated(height)
        node.meta.set_prop(:height, height + 100.0)

        emit("height_updated", height + 100.0)
      end
  
      def background
        if direction.to_s == "outgoing"
          theme.colors.main
        else
          theme.colors.mainalt
        end
      end

      def outwidth
        if direction.to_s == "outgoing"
          100.0
        else
          0.0
        end
      end

      def padding
        @padding ||= begin
          if direction.to_s == "incoming"
            Hokusai::Padding.new(20.0, 20.0, 20.0, 20.0)
          else
            Hokusai::Padding.new(20.0, 20.0, 20.0, 20.0)
          end
        end
      end
    end

    class Conversation < Hokusai::Block
      style <<-EOF
      [style]
      container {
        padding: padding(20.0, 20.0, 20.0, 20.0);
      }
      EOF
      template do
        child(HackOS::Panel) do
          prop :align do
            :bottom
          end

          child(Hokusai::Blocks::Hblock) do
            static "height", "100.0"
            prop :padding do
              Hokusai::Padding.new(20.0, 0.0, 0.0, 0.0)
            end

            on :tap do |event|
              emit("close")
            end

            child(Hokusai::Blocks::Label) do
              prop :size do
                theme.sizes.small
              end

              prop :color do
                theme.colors.light
              end

              prop :content do
                "Conversation with #{number}"
              end

              prop :height do
                theme.sizes.small + 30.0
              end

            end
          end

          child(HackOS::MessagesText) do
            prop :theme do
              theme
            end

            prop :messages do
              messages
            end

            prop :size do
              theme.sizes.small
            end

            prop :color do
              theme.colors.light
            end
          end
        end
        
        child(Hokusai::Blocks::Hblock) do
          prop :height do
            @input_height || theme.sizes.med + 40.0
          end
          
          child(HackOS::Input) do
            on :tap do |event|
              control.dbus.keyboard.toggle
            end

            prop :size do
              theme.sizes.small
            end

            prop :padding do
              Hokusai::Padding.new(20.0, 10.0, 20.0, 10.0)
            end

            on :update do |str|
              @content = str
              @clear = false
            end

            prop :clear do
              @clear
            end

            on :height_updated do |height|
              @input_height = height
            end
          end

          child(Hokusai::Blocks::Vblock) do
            static "width", "130.0"
            prop :background do
              theme.colors.mainalt
            end

            prop :rounding do
              0.3
            end

            child(Hokusai::Blocks::Icon) do
              prop :size do
                theme.sizes.med
              end

              prop :type do
                :send
              end

              prop :color do
                theme.colors.light
              end

              on :tap do |event|
                control.dbus.modem.message_send(content: @content, number: number) unless @content.empty?
                @clear = true
              end
            end
          end
        end
      end

      inject :control
      inject :theme
      computed! :conversation

      def number
        conversation[0]
      end

      def messages
        conversation[1]
      end
    end

    class Latest < Hokusai::Block
      style <<-EOF
      [style]
      container {
        padding: padding(20.0, 20.0, 20.0, 20.0);
        outline: outline(0.0, 0.0, 1.0, 0.0);
        outline_color: rgb(222,222,222,22);
        height: 150.0;
      }
      EOF
      template do
        child(Hokusai::Blocks::Vblock) do
          merge_styles "container"
  
          child(HackOS::Text) do
            prop :content do
              name
            end

            prop :color do
              theme.colors.light
            end

            prop :size do
              theme.sizes.med
            end
          end

          child(HackOS::Text) do
            prop :content do
              "#{message["content"][0..55]}.."
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

      computed! :theme
      computed! :number
      computed! :message
      inject :control

      def name
        @name ||= (control && control.db.contacts.search(number)&.dig("name")) || number
      end
    end

    class Summary < Hokusai::Block
      template do
        child(Hokusai::Blocks::Vblock) do
          each_child(Latest, :sorted) do |item|
            prop :height do
              150.0
            end
            
            prop :key do
              "summary-#{item.value[0]}-#{item.value[1]["time"]}"
            end

            prop :theme do
              theme
            end

            prop :number do
              item.value[0]
            end

            prop :message do
              item.value[1]
            end

            on :tap do |event|
              emit("set", item.value[0])
            end
          end
        end
      end

      inject :theme
      computed! :all

      def sorted
        list = []
        
        # we want list to be ordered with
        # [number, most recent]
        all.each do |k,v|
          list << [k, v.last]
        end

        list.sort_by { |arr| arr[1]["timestamp"] }.reverse
      end
    end

    class ContactItem < Hokusai::Block
      style <<-EOF
      [style]
      contain {
        outline: outline(0.0, 0.0, 1.0, 0.0);
        outline_color: rgb(55,55,55);
        padding: padding(15.0, 0.0, 0.0, 0.0);
      }
      EOF
      template <<~EOF 
      [template]
        vblock { ...contain @tap="select" }
          text {
            :size="size"
            :color="color"
            :content="content"
          }
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        text: Hokusai::Blocks::Label
      )

      computed! :size
      computed! :color
      computed! :content
      computed! :number

      def select(event)
        emit("select", number)
      end
    end

    class SearchContacts < Hokusai::Block
      template do
        child(Hokusai::Blocks::Vblock) do
          prop :background do
            theme.colors.main
          end

          prop :padding do
            Hokusai::Padding.new(20.0, 20.0, 0.0, 20.0)
          end

          child(Hokusai::Blocks::Dynamic) do
            on :size_updated do |_, height|
              node.meta.set_prop(:height, height + 40.0)
            end

            child(HackOS::Input) do
              static "height", "70.0"
              prop :size do
                theme.sizes.med
              end

              on :update do |term|
                @term = term
              end

              prop :clear do
                @clear
              end

              on :keypress do |event|
                if event.symbol == :return
                  emit("select", @term)
                end
              end
            end

            each_child(ContactItem, :contacts) do |contact|
              prop :key do
                next if contact.value.nil?
        
                "#{contact.value["name"]}-#{contact.value["number"]}"
              end

              prop :height do
                theme.sizes.med + 30.0
              end

              prop :size do
                theme.sizes.med
              end

              prop :color do
                theme.colors.light
              end

              prop :number do
                next if contact.value.nil?
                contact.value["number"]
              end

              prop :content do
                next if contact.value.nil?
                "#{contact.value["name"]} - #{contact.value["number"]}"
              end

              on :select do |number|
                emit("select", "+#{number}")
              end
            end
          end
        end
      end

      inject :theme
      inject :control

      def contacts
        if @term && !@term.empty?
          control.db.contacts.list.select { |contact| contact["name"] =~ /#{@term}/ }
        else
          []
        end
      end

      def on_mounted
        node.meta.set_prop(:z, 2)
      end

      def initialize(**args)
        @term = nil
        @clear = false
        super
      end
    end

    class App < Hokusai::Block
      template <<-EOF
      [template]
        vblock { :background="theme.colors.dark" padding="20.0,20.0,20.0,20.0" }
          [if="active"]
            conversation { :conversation="active" @close="close" }
          [else]
            vblock
              search { @tap="toggle_keyboard" @select="new_conversation" }
              summary { :all="messages" @set="set_active" }
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        panel: HackOS::Panel,
        conversation: Conversation,
        summary: Summary,
        search: SearchContacts,
      )

      inject :control
      inject :theme

      attr_reader :messages, :active

      def new_conversation(number)
        @active = [number, @messages[number] || []]
      end

      def set_active(key)
        @active = [key, @messages[key]]
      end

      def close
        @active = nil
      end

      def toggle_keyboard(event)
        control.dbus.keyboard.toggle
      end
  
      def initialize(**args)
        super

        @active = nil
        @messages = control.db.messages.summary(20)

        control.dbus.modem.on_message do |message|
          @messages[message.number] ||= []
          @messages[message.number] << message.to_h
        end
      end
    end
  end
end
