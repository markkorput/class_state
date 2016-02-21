require 'class_state/class_state'

# monkey patch the Owner module insto the ClassState class scope
class ClassState
    module Owner
        attr_reader :state

        def self.included(cls)
            cls.extend(ClassMethods)
        end
        
        def initialize(_state_values = {})
            @state ||= ClassState.new(_state_values)
        end
    
        def method_missing(method_name, *args)
            # byebug

            if method_name =~ /=$/
                # byebug
                if writer = self.class.state_writers.find{|state_writer| "#{state_writer[:name]}=" == method_name.to_s}
                    return self.state[writer[:attribute] || writer[:name]] = args.first
                end
                
                puts self.class.state_writers.inspect
                raise NoMethodError.new(method_name, *args)
                return
            end

            if reader = self.class.state_readers.find{|state_reader| state_reader[:name].to_s == method_name.to_s}
                return self.state[reader[:attribute] || reader[:name]] || reader[:default]
            end
            
            raise NoMethodError.new(method_name, *args)
        end

        module ClassMethods
            def state_readers
                @state_readers ||= []
            end
            
            def state_writers
                @state_writers ||= []
            end
                
            def state_reader(name, opts = {})
                state_readers << opts.merge(:name => name)
                # self.define_method(name) do
                #     self.state[opts[:attribute] || name] || opts[:default]
                # end
            end
    
            def state_writer(name, opts = {})
                state_writers << opts.merge(:name => name)
            end
    
            def state_accessor(name, opts = {})
                state_readers << opts.merge(:name => name)
                state_writers << opts.merge(:name => name)
            end
        end
    end
end