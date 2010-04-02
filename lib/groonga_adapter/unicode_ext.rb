# http://d.hatena.ne.jp/cesar/20070401/p1
module Unicode
  def escape(str)
    ary = str.unpack("U*").map!{|i| "\\u#{i.to_s(16)}"}
    ary.join
  end

  UNESCAPE_WORKER_ARRAY = []
  def unescape(str)
    str.gsub(/\\u([0-9a-f]{4})/) {
      UNESCAPE_WORKER_ARRAY[0] = $1.hex
      UNESCAPE_WORKER_ARRAY.pack("U")
    }
  end

  module_function :escape, :unescape
end
