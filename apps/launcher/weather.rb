module HackOS  
  class WeatherWidget < Hokusai::Block
    style <<-EOF
    [style]
    contain {
      padding: padding(50.0, 0.0, 0.0, 50.0);
    }
    EOF

    template <<~EOF
    [template]
      vblock { ...contain }
        text {
          :content="control.current_date"
          :size="theme.sizes.large"
          :color="theme.colors.light"
        }
        icon { 
          :type="control.weather.icon"
          :content="control.weather.temperature.to_s"
          :size="theme.sizes.med"
          :center="false"
          :color="theme.colors.light"
        }
    EOF

    inject :theme
    inject :control

    attr_accessor :temp, :timer

    uses(
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      text: Hokusai::Blocks::Label,
      icon: Hokusai::Blocks::Icon,
      center: Hokusai::Blocks::Center
    )

    def initialize(**args)
      @timer = Timer.new

      super
    end

    def render(canvas)
      if timer.elapsed?(900)
        control.weather.fetch!
        timer.restart
      end

      yield canvas
    end
  end
end