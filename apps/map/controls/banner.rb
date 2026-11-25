module HackOS::Maps
  module NavFormat
    MANEUVER_ICONS = {
      1 => :nav_start, 2 => :nav_right, 3 => :nav_left,
      4 => :nav_destination, 5 => :nav_destination, 6 => :nav_destination,
      7 => :nav_straight, 8 => :nav_straight,
      9 => :nav_slight_right, 10 => :nav_right, 11 => :nav_sharp_right,
      12 => :nav_uturn_right, 13 => :nav_uturn_left,
      14 => :nav_sharp_left, 15 => :nav_left, 16 => :nav_slight_left,
      17 => :nav_straight, 18 => :nav_slight_right, 19 => :nav_slight_left,
      20 => :nav_slight_right, 21 => :nav_slight_left,
      22 => :nav_straight, 23 => :nav_fork, 24 => :nav_fork,
      25 => :nav_merge, 26 => :nav_roundabout, 27 => :nav_roundabout,
      28 => :nav_ferry, 29 => :nav_ferry
    }

    def maneuver_icon(m)
      (m && MANEUVER_ICONS[m["type"]]) || :nav_straight
    end

    def format_distance(meters)
      feet = meters * 3.28084
      if feet < 1000
        "#{((feet / 50).round * 50).to_i} ft"
      else
        "#{(meters / 1609.34).round(1)} mi"
      end
    end
  end

  class Banner < Hokusai::Block
    include NavFormat

    style <<~EOF
    [style]
      bannerContainer {
        background: rgb(15, 110, 86);
        height: 150.0;
        outline: outline(0.0, 0.0, 1.0, 0.0);
        outline_color: rgb(110, 214, 188);
      }
      bannerPrimary {
        padding: padding(20.0, 20.0, 10.0, 20.0);
      }
      bannerIcon {
        size: 80;
        width: 100.0;
        color: rgb(225, 245, 238);
      }
      bannerDistance {
        size: 48;
        color: rgb(225, 245, 238);
      }
      bannerInstruction {
        size: 28;
        color: rgb(159, 225, 203);
      }
      bannerSecondary {
        background: rgb(8, 80, 65);
        height: 44.0;
        padding: padding(6.0, 20.0, 6.0, 20.0);
      }
      thenIcon {
        size: 28;
        width: 40.0;
        color: rgb(159, 225, 203);
      }
      thenText {
        size: 24;
        color: rgb(159, 225, 203);
      }
    EOF

    template <<~EOF
    [template]
      [if="info"]
        vblock { ...bannerContainer }
          hblock { ...bannerPrimary }
            icon { :type="next_icon" ...bannerIcon }
            vblock
              text { :content="distance" ...bannerDistance }
              text { :content="instruction" ...bannerInstruction }
          [if="then_maneuver"]
            hblock { ...bannerSecondary }
              text { content="Then" ...thenText }
              icon { :type="then_icon" ...thenIcon }
              text { :content="then_street" ...thenText }
    EOF

    uses(
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      text: Hokusai::Blocks::Text,
      icon: Hokusai::Blocks::Icon
    )

    inject :mcontrol

    def info
      mcontrol.progress_info
    end

    def next_maneuver
      info && info[:next_maneuver]
    end

    def next_icon
      maneuver_icon(next_maneuver)
    end

    def distance
      info && info[:to_next_m] ? format_distance(info[:to_next_m]) : ""
    end

    def instruction
      next_maneuver ? next_maneuver["instruction"] : ""
    end

    # the step after next, only when it comes right after (Valhalla's multi-cue)
    def then_maneuver
      m = next_maneuver
      return nil unless m && m["verbal_multi_cue"]

      steps = mcontrol.route_progress.maneuvers
      i = steps.index(m)
      i && steps[i + 1]
    end

    def then_icon
      maneuver_icon(then_maneuver)
    end

    def then_street
      m = then_maneuver
      return "" unless m
      (m["street_names"] || []).first || m["instruction"]
    end
  end
end


module HackOS
  class ArrivalBar < Hokusai::Block
    style <<~EOF
    [style]
      arrivalContainer {
        outline: outline(1.0, 0.0, 0.0, 0.0);
        outline_color: rgb(200, 200, 200);
        background: rgb(255, 255, 255);
        height: 120.0;
        padding: padding(16.0, 20.0, 20.0, 20.0);
      }
      arrivalTime {
        size: 44;
        color: rgb(39, 80, 10);
      }
      arrivalDetail {
        size: 26;
        color: rgb(95, 94, 90);
      }
      endButton {
        size: 44;
        width: 88.0;
        cursor: "pointer";
        color: rgb(252, 235, 235);
        background: rgb(163, 45, 45);
      }
    EOF

    template <<~EOF
    [template]
      vblock
        [if="info"]
          hblock { ...arrivalContainer }
            vblock
              text { :content="arrival" ...arrivalTime }
              text { :content="detail" ...arrivalDetail }
            icon { type="closecircle" ...endButton @click="end_route" }
    EOF

    uses(
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      text: Hokusai::Blocks::Text,
      icon: Hokusai::Blocks::Icon
    )

    include NavFormat

    inject :mcontrol

    def info
      mcontrol.progress_info
    end

    def progress
      mcontrol.route_progress
    end

    def arrival
      arrival_time(info, progress)
    end

    # "6 min · 1.4 mi"
    def detail
      "#{format_duration(remaining_seconds(info, progress))} · #{format_distance(info[:remaining_m])}"
    end

    def end_route(event)
      mcontrol.end_route
    end

    def format_duration(secs)
      mins = (secs / 60.0).ceil
      return "#{mins} min" if mins < 60

      "#{mins / 60} hr #{mins % 60} min"
    end

    def remaining_seconds(info, progress)
      steps = progress.maneuvers
      cur = info[:maneuver]
      return 0 unless cur

      i = steps.index(cur) || 0
      c = progress.cumulative
      step_len = c[cur["end_shape_index"]] - c[cur["begin_shape_index"]]
      left_frac = step_len > 0 ? info[:to_next_m] / step_len : 0

      rest = 0.0
      (steps[(i + 1)..-1] || []).each { |m| rest += m["time"].to_f }
      cur["time"].to_f * left_frac + rest
    end

    def arrival_time(info, progress)
      t = Time.now + remaining_seconds(info, progress)
      hour = t.hour % 12
      hour = 12 if hour.zero?
      "#{hour}:#{t.min.to_s.rjust(2, "0")} #{t.hour < 12 ? "AM" : "PM"}"
    end
  end
end