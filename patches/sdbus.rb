module SDBus
  class Interface
    def set(prop_name, value)
      if prop = props[prop_name]
        raise "Cannot set a readable prop" unless prop[:access] == "write" || prop[:access] == "readwrite"

        vargs = [prop[:type], value]
        args = [name, prop_name, vargs]

        conn.call(
          object.service.name,
          object.name,
          "org.freedesktop.DBus.Properties",
          "Set",
          "ssv",
          args
        )
      end
    end
  end

  class Object
    def interfaces
      @interfaces ||= begin
        # fetch introspect xml
        str = service.bus.conn.call(
          service.name,
          name,
          "org.freedesktop.DBus.Introspectable",
          "Introspect",
          "",
          []
        )

        xml = XML.parse str
        parse_interfaces(xml)
      end
    end
  end
end