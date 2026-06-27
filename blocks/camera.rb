# module HackOS
#   class Camera < Hokusai::Block
#     template <<~EOF
#     [template]
#       empty { @tap="shit" }
#     EOF

#     uses(empty: Hokusai::Blocks::Empty)

#     attr_accessor :lw, :lh, :texture, :camera

#     def initialize(**args)
#       @lw = nil
#       @lh = nil
#       @texture = nil
#       @camera = nil
#       @filter = false
#       super
#     end
    
#     def shit(event)
#       @filter = !@filter
#     end

#     def render(canvas)
#       if @camera.nil?
#         self.camera = ::V4L2::Camera.init("/dev/video2", 480, 640, ::V4L2::PINEPHONE_REAR)
#       p [camera.width, camera.height, canvas.width, canvas.height]
#         camera.open

#         # Use actual negotiated dimensions, not requested ones
#         self.lw = camera.width
#         self.lh = camera.height
#         self.texture = Hokusai::Texture.init(lw, lh)
#         self.texture.clear
#       end

#       frame = self.camera.frame
#       if frame
#         self.texture.update(frame)
#       end
        
#       draw_with do |c|
#         if @filter
#           c.blend_mode_begin("multiply")
#           c.rect(canvas.x, canvas.y, canvas.width, canvas.height) do |com|
#             com.color = Hokusai::Color.new(222,22,22)
#           end
#         end
#           c.texture(@texture, canvas.x, canvas.y) do |command|
#             command.width = canvas.width
#             command.height = canvas.height
#             command.flip = false
#           end
#         if @filter
#           c.blend_mode_end
#         end
#       end

#       yield canvas
#     end
#   end
# end
