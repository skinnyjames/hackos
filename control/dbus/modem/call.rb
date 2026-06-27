module HackOS
  module DBus
    class Call
      def self.from_path(path, modem, feedback: nil)
        obj = SDBus.system.service("org.freedesktop.ModemManager1")
                          .object(path)
                          .interface("org.freedesktop.ModemManager1.Call")
        
        new(obj, modem, path, feedback: feedback)
      end

      def self.create(number, modem)
        if number.size == 10
          number = "1#{number}"
        end

        path = SDBus.system.service("org.freedesktop.ModemManager1")
                          .object(modem.managed)
                          .interface("org.freedesktop.ModemManager1.Modem.Voice")
                          .call("CreateCall", [{"number" => ["s", "+#{number}"]}])


        from_path(path, modem)
      end

      STATES = {
        0 => :unknown,
        1 => :dialing,
        2 => :ringing_out,
        3 => :ringing_in,
        4 => :active,
        5 => :held,
        6 => :waiting,
        7 => :terminated,
      }

      DIRECTIONS = {
        0 => :unknown,
        1 => :incoming,
        2 => :outgoing,
      }

      REASONS = {
        0 => :unknown,
        1 => :outgoing_started,
        2 => :incoming_new,
        3 => :accepted,
        4 => :terminated,
        5 => :refused,
        6 => :error,
        7 => :audio_failed,
        8 => :transferred,
        9 => :deflected,

      }

      attr_reader :call, :modem, :path, :time
      attr_accessor :feedback

      def initialize(interface, modem, path, feedback: feedback)
        @call = interface
        @path = path
        @modem = modem
        @feedback = feedback
        @time = Time.now

        @call.on("StateChanged", &state_changed)
      end

      def to_h
        {
          state: state,
          direction: direction,
          number: number,
          reason: reason,
          timestamp: @time.to_i
        }
      end

      def to_json
        to_h.to_json
      end

      def reason
        value = call.get("StateReason")
        REASONS[value]
      end

      def state
        value = call.get("State")
        STATES[value]
      end

      def direction
        DIRECTIONS[call.get("Direction")]
      end

      def number
        call.get("Number")
      end

      def multi?
        call.get("MultiParty")
      end

      def started
        @started
      end

      # hangup handler
      def state_changed
        @state_changed_proc ||= ->(arr) do
          if state == :active
            Hokusai.sleep 10
            modem.container.audio.voice!
            modem.container.audio.mute = false
          end

          if state == :terminated
            if modem.active == self
              modem.active = nil
            else
              modem.pending.delete(self)
            end
            Hokusai.sleep 10

            modem.container.audio.regular!
          end
        end
      end

      def accept
        if state == :ringing_in && direction == :incoming

          if feedback
            modem.container.feedback.stop(feedback)
            self.feedback = nil
          end
        
          call.call("Accept")
          @started = Time.now
          modem.container.audio.voice!

          modem.active = self
          modem.pending.delete(self)
        end
      end

      def start
        if state == :unknown && direction == :outgoing
          @started = Time.now
          call.call("Start")
        end
      end

      def hangup
        call.call("Hangup")
      end

      def join_multi
        if state == :held
          call.call("JoinMultiparty")
        end
      end

      def leave_multi
        if state == :held && multi?
          call.call("LeaveMultiparty")
        end
      end
    end
  end
end
