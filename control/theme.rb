class Theme
  COLORS = [
    :dark,
    :darkalt,
    :main,
    :mainalt,
    :light
  ]

  SIZES = [
    :xsmall,
    :small,
    :med,
    :large,
    :xlarge
  ]

  attr_reader :path
  
  def initialize(path)
    @path = path
    @state = JSON.parse(File.read(path))
  end

  # don't call until screen is loaded.
  def apps
    @apps ||= begin
      a = @state["apps"]
      a.each do |item|
        Hokusai.images.register "icon-#{item["name"]}", Hokusai::Image.from_file("icons/#{item["icon"]}")
        # item["class"] = eval(item["class"])
      end

      a
    end
  end

  def save
    File.open(path, "w") do |io|
      io << @state.to_json
    end
  end

  def move(app_name, idx)
    app = apps.delete do |item|
      item["name"] == app_name
    end

    if app
      apps.insert(idx, app)

      save
    end
  end

  def colors
    @colors ||= begin
      obj = Colors.new

      COLORS.each do |key|
        val = @state["colors"][key.to_s] || "0,0,0"

        obj.send("#{key}=", Hokusai::Color.convert(val))
      end

      obj
    end
  end

  def sizes
    @sizes ||= begin
      obj = Sizes.new

      SIZES.each do |key|
        val = @state["sizes"][key.to_s] || 14

        obj.send("#{key}=", val.to_i)
      end

      obj
    end
  end

  class Colors
    attr_accessor *COLORS
  end

  class Sizes
    attr_accessor *SIZES
  end
end
