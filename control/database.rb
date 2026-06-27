module HackOS
  module Database
    MESSAGE_TYPE = "M"
    CALL_TYPE = "C"
    CONTACTS_TYPE = "X"

    class Contacts
      attr_reader :container, :list

      def initialize(container)
        @container = container
        @list = all
      end

      def search(number)
        @list.find do |contact|
          contact["number"] == number || "+#{contact["number"]}" == number
        end
      end

      def purge
        container.db.transaction do |txn, dbi|
          MDB.put(txn, dbi, CONTACTS_TYPE, [].to_json)
        end
      end

      def <<(contact)
        @list << contact
      end

      def all
        contacts = nil
        container.db.each_prefix(CONTACTS_TYPE) do |key, value|
          contacts = JSON.parse(value)
        end
        contacts || []
      end

      def save
        container.db.transaction do |txn, dbi|
          MDB.put(txn, dbi, CONTACTS_TYPE, list.to_json)
        end
      end
    end

    class Calls
      attr_reader :container, :list

      def initialize(container)
        @container = container
        @list = all
      end

      def fetch
        @list = all
      end

      def all(size = nil)
        calls = []
        i = 0
        container.db.each_prefix(CALL_TYPE) do |key, value|
          calls << JSON.parse(value)
          break if size && i >= size
          i += 1
        end
        calls
      end

      def save_calls(calls)
        container.db.transaction do |txn, dbi|
          calls.each do |call|
            MDB.put(txn, dbi, index(call), call.to_json)
          end
        end
      end

      def index(call)
        time = call.time.to_i

        "#{CALL_TYPE}#{clean_number(call.number)}\0#{time}"
      end

      def clean_number(number)
        num = number.gsub(/[+\s-]/, "")
        if num.size == 10
          "1#{num}"
        else
          num
        end
      end
    end

    class Messages
      attr_reader :container

      def initialize(container)
        @container = container
      end

      def summary(size = 30)
        messages = {}
        container.db.cursor do |cursor|
          if arr = cursor.last        
            key, value = arr
            if key.start_with?(MESSAGE_TYPE)
              data = JSON.parse(value)
              messages[data["number"]] ||= []
              messages[data["number"]].unshift(data)
            end
          end
          
          while arr = cursor.prev
            key, value = arr
            next unless key.start_with?(MESSAGE_TYPE)

            data = JSON.parse(value)
            messages[data["number"]] ||= []
            messages[data["number"]].unshift(data) unless messages[data["number"]].size > size
          end
        end

        messages
      end

      def all
        messages = []
        container.db.each_prefix(MESSAGE_TYPE) do |key, value|
          messages << JSON.parse(value)
        end
        messages
      end

      def for(number, after: nil, limit: 100)
        prefix = "#{MESSAGE_TYPE}#{clean_number(number)}"
        if after
          prefix += "\0#{after.to_i}"
        end

        list = []
        i = 1
        container.db.cursor do |cursor|
          key, value = cursor.set_range(prefix)
          obj = JSON.parse(value)
          obj["time"] = Time.at(obj["timestamp"])
          list << obj

          while payload = cursor.next
            key, value = payload

            obj = JSON.parse(value)
            obj["time"] = Time.at(obj["timestamp"])
            list << obj

            i += 1
            break if i >= limit
          end
        end

        list
      end

      def save_messages(messages)
        container.db.transaction do |txn, dbi|
          messages.each do |message|
            MDB.put(txn, dbi, index(message), message.to_json)
          end
        end
      end

      def index(message)
        seconds = Time.parse_modem(message.timestamp).to_i

        "#{MESSAGE_TYPE}#{clean_number(message.number)}\0#{seconds}"
      end

      def clean_number(number)
        num = number.gsub(/[+\s-]/, "")
        if num.size == 10
          "1#{num}"
        else
          num
        end
      end
    end

    class Container
      attr_reader :db

      def initialize
        env = MDB::Env.new(
          mapsize:    50000000,
          maxreaders: 50,
          maxdbs:     4
        )
        
        env.open("hackos.db", MDB::NOSUBDIR)
        @db = env.database(MDB::CREATE, "hackosdata")
        @env = env
      end

      def messages
        @messages ||= Database::Messages.new(self)
      end

      def calls
        @calls ||= Database::Calls.new(self)
      end

      def contacts
        @contacts ||= Database::Contacts.new(self)
      end
    end
  end
end
