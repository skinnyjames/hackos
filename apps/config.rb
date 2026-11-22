class TrollioConfig
  class << self
    def assets_path
      "assets"
    end

    def asset(name)
      File.join(assets_path, name)
    end
  end
end