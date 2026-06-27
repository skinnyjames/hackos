require_relative "./modem/call"
require_relative "./modem/message"

module HackOS
  module DBus
    class Modem
      attr_reader :container, :control, :pending
      attr_accessor :active

      def initialize(container, parent)
        @control = parent
        @container = container
        @pending = [] # list of pending call paths
        @active = nil
        @on_message_proc = ->(message) {}

        setup
      end

      def on_message(&block)
        @on_message_proc = block
      end

      def waiting
        pending.last
      end

      def managed
        @managed ||= SDBus.system.service("org.freedesktop.ModemManager1")
                    .object("/org/freedesktop/ModemManager1")
                    .interface("org.freedesktop.DBus.ObjectManager")
                    .call("GetManagedObjects")
                    .keys
                    .first

      end

      def manager
         SDBus.system.service("org.freedesktop.ModemManager1")
                     .object(managed)
      end

      def messaging
        manager.interface("org.freedesktop.ModemManager1.Modem.Messaging")
      end

      def voice
        manager.interface("org.freedesktop.ModemManager1.Modem.Voice")
      end

      def delete(path)
        voice.call("DeleteCall", [path])
      end

      def hold_and_accept
        voice.call("HoldAndAccept")
      end

      def hangup_and_accept
        voice.call("HangupAndAccept")
      end

      def hangup_all
        voice.call("HangupAll")
      end

      def setup
        voice.on("CallAdded", &call_added)
        voice.on("CallDeleted", &call_removed)
        messaging.on("Added", &message_added)
        messaging.on("Deleted", &message_deleted)

        transfer_messages
      end

      def message_send(content:, number:)
        path = message_create(content: content, number: number)
        Message.new(path, self).send
      end

      def message_create(content:, number:)
        messaging.call("Create", [{"number" => ["s", number], "text" => ["s", content] }])
      end

      def transfer_messages
        messages = messaging.get("Messages").map do |path|
          Message.new(path, self)
        end

        control.db.messages.save_messages(messages)

        messages.each(&:delete)
      end

      def transfer_calls
        paths = []
        calls = voice.call("ListCalls").map do |path|
          paths << path
          Call.from_path(path, self)         
        end

        control.db.calls.save_calls(calls)

        paths.each do |path|
          voice.call("DeleteCall", [path])
        end
      end

      def message_delete(path)
        messaging.call("Delete", [path])
      end

      def message_added
        @message_added_proc ||= ->(args) do
          path, received = args
          message = Message.new(path, self)
          @on_message_proc&.call(message)
          control.db.messages.save_messages([message])
          message.delete
        end
      end

      def message_deleted
        @message_deleted_proc ||= ->(args) do
          # path, received = args

          # message = Message.new(path, self)
          # @message_list[path.number].delete_if { |m| m.path == path }
        end
      end

      def call_added
        obj = self
        @call_added_proc ||= ->(path) do
          id = container.feedback.incoming_call
          call = Call.from_path(path, self, feedback: id)
          obj.pending << call

          control.db.calls.save_calls([call])
        end
      end

      def call_removed
        @call_removed_proc ||= ->(path) do
        end
      end

      def dial(number)
        call = Call.create(number, self)
        call.start
        
        self.active = call
      end
    end
  end
end
