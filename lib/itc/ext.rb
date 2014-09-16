class Hash
  def each_with_parent(parent=nil, &blk)
    each do |k, v|
      Hash === v ? v.each_with_parent(k, &blk) : blk.call(parent, k, v)
    end
  end
end
