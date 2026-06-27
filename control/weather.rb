module HackOS
  class Weather < ::Hokusai::Block
    ENDPOINT = "https://api.open-meteo.com/v1"

    template <<~EOF
    [template]  
      virtual
    EOF

    attr_reader :control, :daytime

    def initialize(control)
      @control = control
      @temperature = "?"
      @weather_code = 0
      @daytime = true
    end

    def icon
      case @weather_code
      when 0
        daytime ? :sun : :moon
      when (1..2)
        daytime ? :cloud_sun : :moon_cloud
      when 3
        daytime ? :cloud : :moon_cloud
      when 19
        :tornado
      when (45..48)
        :smog
      when (51..55)
        daytime ? :cloud_rain : :moon_cloud_rain
      when (56..57)
        :snowflake
      when (61..65)
        :cloud_showers_heavy
      when (66..67)
        :cloud_meatball
      when (71..75)
        :snowflake
      when 77
        :snowflake
      when (80..82)
        :cloud_sun_rain
      when (85..86)
        :snowman
      when 95
        :cloud_bolt
      when (96..98)
        :cloud_showers_water
      when 99
        :tornado
      else
        :sun
      end
    end

    def temperature
      "#{@temperature}°"
    end

    def fetch!
      lat, lng = control.dbus.geo.coordinates

      options = { 
        latitude: lat, 
        longitude: lng,
        current: "temperature_2m,weather_code,is_day", 
        temperature_unit: "fahrenheit"
      }.reduce([]) do |memo, (k, v)|
        memo << "#{k}=#{v}"
        memo
      end.join("&")

      fetch(ENDPOINT, { method: "GET"}, path: "/forecast?#{options}") do |res|
        if res.status == "OK"
          json = res.body.json
          @temperature = json.dig("current", "temperature_2m")
          @weather_code = json.dig("current", "weather_code")
          @daytime = json.dig("current", "is_day") == 1
        end
      end
    end
  end
end
