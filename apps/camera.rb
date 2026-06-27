module HackOS
  module Camera
    class App < Hokusai::Block
      template <<~EOF
      [template]
        empty {
          @tap="filter"
          @doubletap="switch"
        }
      EOF

      uses(empty: Hokusai::Blocks::Empty)

      computed :size, default: 300

      attr_accessor :lw, :lh, :w, :h, :texture, :camera

      def initialize(**args)
        @texture = nil
        @camera = nil
        @filter = false
        @timer = Timer.new
        @current = :rear

        super
      end

      def filter(event)
        @filter = !@filter
      end
      
      def switch(event)
        camera.close
        IO.popen('media-ctl -d "platform:1cb0000.csi" -r')
        Hokusai.sleep 500

        w = size
        h = (4 * w) / 3

        case @current
        when :rear
          # IO.popen('media-ctl -d /dev/media1 --links \'"gc2145 4-003c":0->"sun6i-csi":0\'')
          self.camera = V4L2::Camera.init("/dev/video2", w, h, V4L2::PINEPHONE_FRONT)
          @current = :front
        else
          # IO.popen('media-ctl -d /dev/media1 --links \'"ov5640 4-004c":0->"sun6i-csi":0\'')
          self.camera = V4L2::Camera.init("/dev/video2", w, h, V4L2::PINEPHONE_REAR)
          @current = :rear
        end

        camera.open
      end

      def punk
        <<-EOF
        #version 100
        precision mediump float;

        varying vec2 fragTexCoord;
        varying vec4 fragColor;

        uniform sampler2D texture0;
        uniform float time; // Pass this from your Ruby loop!

        void main() {
            // 1. Apply your 90 degrees Clockwise rotation first
            vec2 rotatedUV = vec2(fragTexCoord.y, 1.0 - fragTexCoord.x);
            
            // 2. Chromatic aberration color split offsets
            vec2 offset = vec2(0.007, 0.0);
            float r = texture2D(texture0, rotatedUV + offset).r;
            float g = texture2D(texture0, rotatedUV).g;
            float b = texture2D(texture0, rotatedUV - offset).b;
            vec4 baseColor = vec4(r, g, b, 1.0);
            
            // 3. Calculate horizontal scanlines across the physical screen.
            // Using rotatedUV.y ensures lines are horizontal on the device display.
            // Adding (time * 4.0) makes the scanlines scroll downward over time.
            float scanline = sin((rotatedUV.y * 350.0) + (time * 4.0)) * 0.12;
            baseColor.rgb -= scanline;
            
            // 4. Subtle screen flicker effect using time
            float flicker = 0.97 + 0.03 * sin(time * 80.0);
            baseColor.rgb *= flicker;
            
            // Neon cyber tint
            baseColor.rgb *= vec3(0.9, 1.1, 0.9);

            gl_FragColor = baseColor * fragColor;
        }
        EOF
      end

      def neon
        <<-EOF
        #version 100
        precision mediump float;

        varying vec2 fragTexCoord;
        varying vec4 fragColor;

        uniform sampler2D texture0;

        void main() {
            // Your original 90 degrees Clockwise rotation
            vec2 rotatedUV = vec2(fragTexCoord.y, 1.0 - fragTexCoord.x);
            
            // Distance between texels (adjust based on camera frame size)
            float stepX = 1.0 / 300.0;
            float stepY = 1.0 / 400.0;
            
            // Sample intensity from surrounding 3x3 pixel kernel
            float tleft  = texture2D(texture0, rotatedUV + vec2(-stepX,  stepY)).g;
            float left   = texture2D(texture0, rotatedUV + vec2(-stepX,    0.0)).g;
            float bleft  = texture2D(texture0, rotatedUV + vec2(-stepX, -stepY)).g;
            float top    = texture2D(texture0, rotatedUV + vec2(   0.0,  stepY)).g;
            float bottom = texture2D(texture0, rotatedUV + vec2(   0.0, -stepY)).g;
            float tright = texture2D(texture0, rotatedUV + vec2( stepX,  stepY)).g;
            float right  = texture2D(texture0, rotatedUV + vec2( stepX,    0.0)).g;
            float bright = texture2D(texture0, rotatedUV + vec2( stepX, -stepY)).g;
            
            // Sobel operators for Horizontal & Vertical changes
            float h = -tleft - 2.0 * left - bleft + tright + 2.0 * right + bright;
            float v = -tleft - 2.0 * top - tright + bleft + 2.0 * bottom + bright;
            
            // Edge magnitude
            float edge = sqrt(h * h + v * v);
            
            // Output neon blue outlines on a dark background
            vec3 neonColor = vec3(0.0, 0.8, 1.0) * edge;
            
            gl_FragColor = vec4(neonColor, 1.0) * fragColor;
        }
        EOF
      end


      def fragment
        <<-EOF
        #version 100
        precision mediump float;

        // Input from raylib
        varying vec2 fragTexCoord;
        varying vec4 fragColor;

        // The texture texture bound by raylib
        uniform sampler2D texture0;

        void main() {
            // 90 degrees Clockwise rotation
            vec2 rotatedUV = vec2(fragTexCoord.y, 1.0 - fragTexCoord.x);
            
            // Fetch and output pixel
            gl_FragColor = texture2D(texture0, rotatedUV) * fragColor;
        }
        EOF
      end

      def before_destroy
        @camera.close
        IO.popen('media-ctl -d "platform:1cb0000.csi" -r')
        Hokusai.sleep 100
      end
  
      def render(canvas)
        # camera is 3x4
        # 3 / 4 = width / x

        w = size
        h = (4 * w) / 3

        cw = canvas.width
        ch = (4 * cw) / 3

        if @camera.nil?
          p [w, h]          
          IO.popen('media-ctl -d "platform:1cb0000.csi" -r')
          self.camera = ::V4L2::Camera.init("/dev/video2", w.to_i, h.to_i, ::V4L2::PINEPHONE_REAR)
          camera.open

          self.texture = Hokusai::Texture.init(w, h)
          self.texture.clear
        end

        frame = self.camera.frame
        if frame
          self.texture.update(frame)
        end
          
        draw_with do |commands|
          commands.shader_begin do |command|
            command.fragment_shader = fragment
          end

          if @timer.elapsed?(600)
            @timer.restart
          end

          if @filter
            commands.shader_begin do |command|
              command.fragment_shader = punk
              command.uniforms = { 'time' => [@timer.elapsed, HP_SHADER_UNIFORM_FLOAT]}
            end
          end

          commands.texture(@texture, canvas.x, canvas.y) do |command|
            if @current == :rear
              command.width = cw
              command.height = ch
              command.flip = false
            else
              command.width = cw
              command.height = ch
              command.flip = true
            end
          end

          commands.shader_end if @filter

          commands.shader_end
        end

        @timer.next

        yield canvas
      end
    end
  end
end