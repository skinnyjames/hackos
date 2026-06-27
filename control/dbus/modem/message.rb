module HackOS
  module DBus
    class Message
      STATES = {
        0 => :unknown,
        1 => :stored,
        2 => :receiving,
        3 => :received,
        4 => :sending,
        5 => :sent
      }

      STORAGES = {
        0 => :unknown,
        1 => :sim,
        2 => :sd,
        3 => :sim_sd,
        4 => :status_report,
        5 => :broadcast,
        6 => :ta
      }

      attr_reader :path, :modem
      
      def initialize(path, modem)
        @path = path
        @modem = modem
      end

      def complete?
        state == :received || state == :sent || state == :stored
      end

      def direction
        case state
        when :received, :receiving
          :incoming
        when :sending, :sent
          :outgoing
        else
          :incoming
        end
      end

      def interface
        @interface ||= SDBus.system.service("org.freedesktop.ModemManager1")
                                   .object(path)
                                   .interface("org.freedesktop.ModemManager1.Sms")
      end

      def save(location = :sim)
        storage = STORAGES.invert[location]
        interface.call("Store", [storage])
      end

      def send
        interface.call("Send")
      end
      
      def delete
        modem.message_delete(path)
      end

      def state
        STATES[interface.get("State")]
      end

      def number
        interface.get("Number")
      end
      
      def text
        interface.get("Text")
      end

      def timestamp
        stamp = interface.get("Timestamp") 
        return Time.now.strftime("%Y-%m-%dT%H:%M:%S%Z") if stamp.empty? || stamp.nil?

        stamp
      end

      def to_h
        {
          "state" => state,
          "direction" => direction,
          "content" => text,
          "number" => number,
          "timestamp" => Time.parse_modem(timestamp).to_i,
          "time" => Time.parse_modem(timestamp)
        }
      end

      def to_json
        to_h.to_json
      end
    end
  end
end
