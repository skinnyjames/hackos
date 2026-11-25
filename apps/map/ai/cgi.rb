module CGI
  HEX = "0123456789ABCDEF"

  def self.unreserved?(b)
    (b >= 0x30 && b <= 0x39) ||  # 0-9
    (b >= 0x41 && b <= 0x5A) ||  # A-Z
    (b >= 0x61 && b <= 0x7A) ||  # a-z
    b == 0x2D || b == 0x2E || b == 0x5F || b == 0x7E  # - . _ ~
  end

  def self.escape(str)
    out = ""
    str.each_byte do |b|
      if b == 0x20
        out << "%20"
      elsif unreserved?(b)
        out << b.chr
      else
        out << "%" << HEX[b >> 4] << HEX[b & 0x0F]
      end
    end
    out
  end

  def self.unescape(str)
    out = ""
    i = 0
    len = str.bytesize
    while i < len
      c = str.getbyte(i)
      if c == 0x2B  # '+'
        out << " "
        i += 1
      elsif c == 0x25 && i + 2 < len + 0 && (hex = str.byteslice(i + 1, 2)) && hex.bytesize == 2
        out << hex.to_i(16).chr
        i += 3
      else
        out << c.chr
        i += 1
      end
    end
    out
  end
end
