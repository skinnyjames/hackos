module HackOS
  module Maps
  end
end

require_relative "./map/ai/cgi"
require_relative "./map/ai/fake_gps"
require_relative "./map/ai/real_gps"
require_relative "./map/ai/route_progress"
require_relative "./map/error"
require_relative "./map/geo"
require_relative "./map/geometry"
require_relative "./map/layers"
require_relative "./map/ai/routing"
require_relative "./map/control"
require_relative "./config"
require_relative "./map/controls/search"
require_relative "./map/controls/zoom"
require_relative "./map/controls/banner"

module HackOS::Maps
  class Map < Hokusai::Block
    template <<~EOF
    [template]
      vblock
        slot
    EOF

    uses(vblock: Hokusai::Blocks::Vblock)

    inject :mcontrol

    def before_updated
      if mcontrol.center_changed
        mcontrol.update_bounds!
        mcontrol.center_changed = false
      end
    end

    def on_resize(canvas)
      mcontrol.resize canvas
    end

    def render(canvas)
      on_resize(canvas) if mcontrol.bounds_size.nil?

      yield canvas
    end
  end
end

class App < Hokusai::Block
  style <<~EOF
  [style]
    tileStyle {
      url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
      zoom_offset: 8;
    }
    box {
      background: rgb(48, 48, 48);
      height: 100.0;
      padding: padding(20.0, 0.0, 30.0, 0.0);
    }
    label {
      color: rgb(255,255,255);
    }
    zstyle {
      z: 2;
      ztarget: "parent";
      reverse: true;
    }
    currentLocation {
      height: 30.0;
      background: rgb(22, 22, 22);
      padding: padding(5.0, 5.0, 5.0, 5.0);
    }
    currentLocationText {
      size: 20;
      color: rgb(255,255,255);
    }
  EOF

  template <<~EOF
  [template]
    vblock
      map {
        @change="update_latlng"
        @clear_update_center="clear_update_center"
        :update_center="update_center"
        cursor="pointer"
        :center="mcontrol.center"
        :zoom="mcontrol.zoom"
      }
        tile_layer { ...tileStyle }
        [if="route"]
          geojson_layer { :data="route" }
      arrival { :height="120.0" }
      [if="current_address"]
        vblock { ...currentLocation :height="current_address_height" }
          text { :content="current_address" ...currentLocationText @height_updated="set_current_address_height" }
    hblock { ...zstyle }
      [if="driving"]
        banner
      [else]
        search
  EOF

  uses(
    arrival: HackOS::Maps::ArrivalBar,
    banner: HackOS::Maps::Banner,
    dynamic: Hokusai::Blocks::Dynamic,
    text: Hokusai::Blocks::Text,
    search: HackOS::Maps::Controls::Search,
    zoom: HackOS::Maps::Controls::Zoom,
    icon: Hokusai::Blocks::Icon,
    selectable: Hokusai::Blocks::Selectable,
    hblock: Hokusai::Blocks::Hblock,
    vblock: Hokusai::Blocks::Vblock,
    label: Hokusai::Blocks::Label,
    input: Hokusai::Blocks::Input,
    empty: Hokusai::Blocks::Empty,
    button: Hokusai::Blocks::Button,
    map: HackOS::Maps::Map,
    tile_layer: HackOS::Maps::TileLayer,
    geojson_layer: HackOS::Maps::GeoJSONLayer,
    marker_layer: HackOS::Maps::MarkerLayer
  )

  attr_reader :drag_offset, :update_center
  attr_reader :mcontrol, :current_address_height
  provide :mcontrol, :mcontrol
  inject :control

  def initialize(**args)
    super 
    @mcontrol = HackOS::Maps::Control.new(HackOS::Maps::LatLng.new(39.9612, -82.9988))
    @mcontrol.gps = RealGPS.new(control.dbus.geo)
    @current_address_height = 30.0 + 10.0
  end

  def driving
    !mcontrol.progress_geojson.nil?
  end

  def set_current_address_height(height)
    @current_address_height = height + 10.0
  end

  def route
    mcontrol.progress_geojson
  end

  def current_address
    mcontrol.errors[:current] || mcontrol.search_from
  end

  def announce(info, speed)
    m = info[:next_maneuver]
    d = info[:to_next_m]
    return unless m && d

    key = m["begin_shape_index"]
    secs = speed > 1 ? d / speed : Float::INFINITY

    # just finished a turn: say what comes next
    cur = info[:maneuver]
    if cur && !@announced[[cur["begin_shape_index"], :post]]
      @announced[[cur["begin_shape_index"], :post]] = true
      say(cur["verbal_post_transition_instruction"])
    end

    # heads-up
    if secs < 30 && !@announced[[key, :alert]]
      @announced[[key, :alert]] = true
      say(m["verbal_transition_alert_instruction"])
    end

    # right before the turn; short version if we're nearly there
    if secs < 8 && !@announced[[key, :now]]
      @announced[[key, :now]] = true
      say(secs < 4 ? m["verbal_succinct_transition_instruction"] : m["verbal_pre_transition_instruction"])

      # "Then ..." already covered the next turn
      if m["verbal_multi_cue"]
        steps = mcontrol.route_progress.maneuvers
        idx = steps.index(m)
        following = idx && steps[idx + 1]
        @announced[[following["begin_shape_index"], :alert]] = true if following
      end
    end
  end

  def target_zoom(info, speed)
    base = speed > 22 ? 5 : (speed > 13 ? 8 : 10)   # highway / arterial / city
    d = info[:to_next_m] || Float::INFINITY

    if d < 120
      @zoomed_in = true
    elsif d > 250
      @zoomed_in = false
    end

    @zoomed_in ? [base + 1, 9].min : base
  end

  def say(text)
    Hokusai.speak(text) if text && !text.empty?
  end
  
  def render(canvas)
    if @announced_for != mcontrol.route_progress.object_id
      @announced = {}
      @announced_for = mcontrol.route_progress.object_id
    end
    mcontrol.canvas = canvas

    if info = mcontrol.progress
      mcontrol.center = info[:snapped]
      mcontrol.update_progress(info, mcontrol.gps.heading)
      announce(info, mcontrol.gps.speed)
    end

    yield canvas
  end
end
