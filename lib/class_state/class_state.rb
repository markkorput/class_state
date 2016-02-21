require 'logger'

class ClassState
    attr_reader :values
    attr_reader :callback_definitions

    def initialize(_values = {})
        @callback_definitions = []
        self.set(_values)
    end
    
    def logger
        @_logger ||= Logger.new(STDOUT).tap do |l|
            l.level = Logger::WARNING
        end
    end
            
        
    # readers

    def get(attr_name)
        values[attr_name]
    end
    
    def [](attr_name)
        values[attr_name]
    end
    
    def data
        self.values
    end
    
    # writers
    
    def []=(key, val)
        return self.update(key => val)
    end

    def update(_values)
        self.set(self.values.merge(_values))
        return self
    end

    def set(_values)
        original = self.values || {}
        @values = _values
        changes = get_changes_hash(original, _values)

        changes.keys.each do |changed_attr|
            trigger_attribute_callbacks(:change_attribute, changed_attr, self, changes)
        end

        if !changes.empty?
            trigger_callbacks(:change, self, changes)
        end
        
        return self
    end
    
    def unset(attrs)
        unsets = {}

        [attrs].flatten.each do |attr_name|
            if self.values.keys.include?(attr_name)
                unsets.merge!(attr_name => self.values.delete(attr_name))
            end
        end
        
        unsets.keys.each do |changed_attr|
            trigger_attribute_callbacks(:unset_attribute, changed_attr, self, unsets)
        end

        if !unsets.empty?
            trigger_callbacks(:unset, self, unsets)
        end

        return unsets
    end

    def on(*args, &block)
        callback_definition = {:event => args.first}

        if block
            callback_definition[:block] = block
            callback_definition[:attribute] = args[1] # could be nil
        else
            if args.first == :change_attribute or args.first == :unset_attribute
                callback_definition[:attribute] = args[1]
                callback_definition[:subject] = args[2]
                callback_definition[:method] = args[3]
            else
                callback_definition[:subject] = args[1]
                callback_definition[:method] = args[2]
            end
        end

        if callback_definition[:block].nil? and callback_definition[:method].nil?
            logger.warn "ClassState.on didn't get a callback method or block"
        end
        
        if !callback_definition[:method].nil?
            callback_definition[:method] = callback_definition[:method].to_s.to_sym
        end

        # save definition
        @callback_definitions << callback_definition
    end
    
    private
    
    def get_changes_hash(before, after)
        # assume all new values as changes, but reject the ones that are still the same as before
        changes = after.reject do |key, value|
            before[key] == value # new value is same as old value; don't include in 'changes' data hash
        end

        # also include the removed attributes in the changes
        before.each_pair do |key, value|
            if !after.keys.include?(key)
                changes.merge!(key => nil)
            end
        end

        return changes
    end
    
    def trigger_callbacks(event, *args)
        self.callback_definitions.each do |callback_def|
            if callback_def[:event] == event and callback_def[:attribute].nil?
                if callback_def[:block]
                    callback_def[:block].call(*args)
                else
                    callback_def[:subject].send(callback_def[:method], *args)
                end
            end
        end
    end

    def trigger_attribute_callbacks(event, attr, *args)
        self.callback_definitions.each do |callback_def|
            if callback_def[:event] == event and callback_def[:attribute] == attr
                if callback_def[:block].nil?
                    callback_def[:subject].send(callback_def[:method], *args)
                else
                    callback_def[:block].call(*args)
                end
            end
        end
    end
end # of class ClassState