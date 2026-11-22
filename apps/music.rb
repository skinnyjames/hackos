module HackOS
  module Music
    class Controls < Hokusai::Block
      style <<~EOF
      [style]
      contain {
        outline: outline(1.0, 0.0, 0.0, 0.0);
        outline_color: rgb(55, 55, 55);
      }

      icon {
        color: rgb(222, 222, 222);
        size: 80;
      }
      EOF
      
      template do
        child(Hokusai::Blocks::Hblock) do
          merge_styles "contain"
          # prev
          child(Hokusai::Blocks::Icon) do
            merge_styles "icon"

            prop :type do
              :skipprev
            end
          end

          # play/pause
          child(Hokusai::Blocks::Icon) do
            merge_styles "icon"

            prop :type do
              playing ? :pause : :play
            end

            on :tap do |event|
              p "playing? #{playing}"
              emit(playing ? "pause" : "play") 
            end
          end
          
          # next
          child(Hokusai::Blocks::Icon) do
            merge_styles "icon"

            prop :type do
              :skipnext
            end
          end
        end
      end

      computed :playing, default: false
    end

    class FileItem < Hokusai::Block
      template do
        child(Hokusai::Blocks::Vblock) do
          prop :padding do
            Hokusai::Padding.new(20.0, 20.0, 20.0, 20.0)
          end

          prop :outline do
            Hokusai::Outline.new(1.0, 0.0, 0.0, 0.0)
          end

          prop :outline_color do
            theme.colors.light
          end

          on :tap do |event|
            emit("select", file)
          end

          child(HackOS::Text) do
            prop :size do
             50.0
            end

            prop :color do
              theme.colors.light
            end

            prop :content do
              file
            end
          end
        end
      end

      inject :theme
      computed! :file
    end

    class App < Hokusai::Block
      style <<~EOF
      [style]
      item {
        color: rgb(222, 222, 222);
      }
      EOF
      template do
        child(Hokusai::Blocks::Vblock) do
          prop :background do 
            theme.colors.dark
          end
          # file list panel
          child(HackOS::Panel) do
            each_child(FileItem, :files) do |file|
              prop :key do
                "music-item-#{file.value}"
              end

              prop :height do
                120.0
              end

              prop :file do
                file.value
              end

              on :select do |file|
                @current = file
                @audio = Hokusai::Music.from_file(file)
                @audio.volume = 1.0
              end
            end
          end

          # current song
          child(Hokusai::Blocks::Vblock) do
            prop :height do 
              theme.sizes.med + 40.0
            end

            prop :padding do
              Hokusai::Padding.new(20.0, 20.0, 20.0, 20.0)
            end

            prop :background do
              Hokusai::Color.new(0, 0, 0, 160)
            end

            prop :outline do
              Hokusai::Outline.new(1.0, 0.0, 1.0, 0.0)
            end

            prop :outline_color do
              theme.colors.light
            end

            child(HackOS::Text) do
              prop :size do
                theme.sizes.med
              end
              prop :color do
                theme.colors.mainalt
              end
              prop :content do
                current.nil? ? "No song selected" : current.split("/").last
              end
            end
          end

          # controls
          child(Controls) do
            prop :height do
              180.0
            end

            prop :playing do
              audio&.playing?
            end
            
            on :next do
            end

            on :prev do
            end

            on :play do
              audio&.playing? ? @audio&.resume : audio&.play
            end

            on :pause do
              @audio&.pause
            end
          end
        end
      end

      SUPPORTED_EXTENSIONS = /(\.mp3|\.wav|\.ogg\|\.flac)$/

      computed :location, default: "/home/user/Music", convert: proc(&:to_s)
      inject :control
      inject :theme

      def files
        @files ||= Dir.glob("#{location}/**/*").select do |file|
          file =~ SUPPORTED_EXTENSIONS
        end.uniq
      end

      attr_accessor :current, :playing, :audio

      def initialize(**args)
        @current = nil
        @audio = nil
        @playing = false

        super
      end

      def render(canvas)
      
        audio&.update

        yield canvas
      end
    end
  end
end
