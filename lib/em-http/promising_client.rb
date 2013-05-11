if require 'em-promise' || defined?(EM::Q)
  module PromisingHttpRequest                                                                                                                                                                              
    def then(success_back = nil, error_back = nil, &blk)                                                                                                                                                   
      deferred = EM::Q.defer                                                                                                                                                                               
                                                                                                                                                                                                           
      self.callback {                                                                                                                                                                                      
        deferred.resolve(self)                                                                                                                                                                             
      }                                                                                                                                                                                                    
      self.errback {                                                                                                                                                                                       
        deferred.reject("Connection failure")                                                                                                                                                              
      }                                                                                                                                                                                                    
      deferred.promise.then(success_back, error_back, &blk)                                                                                                                                                
    end                                                                                                                                                                                                    
                                                                                                                                                                                                           
    def is_a?(klass)                                                                                                                                                                                       
      return true if klass == EventMachine::Q::Promise                                                                                                                                                     
      super(klass)                                                                                                                                                                                         
    end                                                                                                                                                                                                    
  end                                                                                                                                                                                                      
  EM::HttpClient.send(:include, PromisingHttpRequest) 
end
