class Hash
  # Stolen partially from Merb : http://noobkit.com/show/ruby/gems/development/merb/hash/to_params.html
  # Convert this hash to a query string:
  #   
  #   { :name => "Bob",
  #     :address => {
  #       :street => '111 Ruby Ave.',
  #       :city => 'Ruby Central',
  #       :phones => ['111-111-1111', '222-222-2222']
  #     }
  #   }.to_params
  #   #=> "name=Bob&address[city]=Ruby Central&address[phones]=111-111-1111222-222-2222&address[street]=111 Ruby Ave."
  # 
  def to_params
    params = ''
    stack = []
    
    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      elsif v.is_a?(Array)
        stack << [k,Hash.from_array(v)]
      else
        params << "#{k}=#{v}&"
      end
    end
    
    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end
    
    params.chop! # trailing &
    params
  end
  
  ##
  # Builds a hash from an array with keys as array indices.
  def self.from_array(array = [])
    h = Hash.new
    array.size.times do |t|
      h[t] = array[t]
    end
    h
  end

end

