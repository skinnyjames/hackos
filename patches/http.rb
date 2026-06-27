
module Hokusai
  module HTTP
    class ResponseBody
      def all
        tmp = File.read(@tmp)

        IO.popen("rm #{@tmp}") if File.exist?(@tmp)

        tmp
      end
    end
  end

  class Block
    def fetch(url, opts, path: "/", &block)
      instance_eval do
        req = Hokusai::Request.init(self, url)
        req.execute(path, opts, &block)
      end
    end
  end
end