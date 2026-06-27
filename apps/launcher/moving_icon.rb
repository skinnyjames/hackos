module HackOS
  class MovingIcon < Hokusai::Block
    template <<~EOF
    [template]
      virtual
    EOF

    computed! :moving
    computed! :name
    computed! :width
    computed! :height
    computed :active, default: false
    computed :padding, default: Hokusai::Padding.new(0.0, 0.0, 0.0, 0.0), convert: Hokusai::Padding

    def vertex
      <<-EOF
     #version 100
      attribute vec3 vertexPosition;
      attribute vec2 vertexTexCoord;
      attribute vec4 vertexColor;

      uniform mat4 mvp;
      uniform float uTime;
      uniform int uIsHeld;

      varying vec2 fragTexCoord;
      varying vec4 fragColor;

      void main() {
          fragTexCoord = vertexTexCoord;
          fragColor = vertexColor;
          
          vec3 pos = vertexPosition;
          
          if (uIsHeld == 1) {
              // Warp the X and Y bounds slightly based on time to simulate jiggliness
              pos.x += sin(pos.y * 0.1 + uTime * 15.0) * 4.0;
              pos.y += cos(pos.x * 0.1 + uTime * 12.0) * 2.0;
          }
          
          gl_Position = mvp * vec4(pos, 1.0);
      }
      EOF
    end

    def fragment
      <<-EOF
      #version 100
      precision mediump float;
      varying vec2 fragTexCoord;
      varying vec4 fragColor;
      uniform sampler2D texture0;

      void main() {
          gl_FragColor = texture2D(texture0, fragTexCoord) * fragColor;
      }
    EOF
    end

    def glitch
      <<-EOF
      #version 100
      precision mediump float;

      varying vec2 fragTexCoord;
      varying vec4 fragColor;
      uniform sampler2D texture0;

      uniform float uTime;
      uniform int uIsHeld;

      // Simple pseudo-random generator
      float rand(vec2 co) {
          return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
      }

      void main() {
          if (uIsHeld == 1) {
              // Create an intermittent horizontal slicing glitch triggered by time
              float glitchThreshold = step(0.85, sin(uTime * 10.0)); 
              float sliceY = floor(fragTexCoord.y * 10.0); // Split button into 10 bands
              
              vec2 uvOffset = vec2(0.0);
              if (glitchThreshold > 0.0) {
                  // Apply unique horizontal displacement per vertical slice band
                  uvOffset.x = (rand(vec2(sliceY, uTime)) - 0.5) * 0.08;
              }

              // Sample separate channels with offsets to create Chromatic Aberration splits
              float r = texture2D(texture0, fragTexCoord + uvOffset).r;
              float g = texture2D(texture0, fragTexCoord).g;
              float b = texture2D(texture0, fragTexCoord - uvOffset).b;
              float a = texture2D(texture0, fragTexCoord + uvOffset).a;

              // Inject subtle matrix lines
              float scanline = sin(fragTexCoord.y * 120.0) * 0.15 + 0.85;

              gl_FragColor = vec4(vec3(r, g, b) * scanline, a) * fragColor;
          } else {
              gl_FragColor = texture2D(texture0, fragTexCoord) * fragColor;
          }
      }
      EOF
    end

    def render(canvas)
      unless Hokusai.can_render(canvas)
        yield canvas
        return
      end

      @time = Hokusai.monotonic - @start
      draw do
        if img = Hokusai.images.get(name)
          draw do
            if moving == "t"
              uniforms = {
                "uIsHeld" => [1, HP_SHADER_UNIFORM_INT],
                "uTime" => [@time, HP_SHADER_UNIFORM_FLOAT]
              }

              shader_begin do |command|
                # command.vertex_shader = vertex
                command.fragment_shader = glitch
                command.uniforms = uniforms 
              end
            end
            if active
              x = (canvas.x + (width&.to_f || canvas.width) / 2.0)
              y = (canvas.y + (height&.to_f || canvas.height) / 2.0)
              circle(x + 25.0, y + 25.0, 100.0) do |command|
                command.color = Hokusai::Color.new(22,22,22, 200)
              end
            end
            image(img, canvas.x + padding.left, canvas.y + padding.top, (width&.to_f || canvas.width) - padding.right, (height&.to_f || canvas.height) - padding.bottom)

            shader_end if moving
          end
        end
      end

      yield canvas
    end

    def initialize(**args)
      @start = Hokusai.monotonic

      super
    end
  end
end