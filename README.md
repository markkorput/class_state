# class_state
A ruby gem for managing class states

[![Build Status](https://travis-ci.org/markkorput/class_state.svg)](https://travis-ci.org/markkorput/class_state)

## Installation

Rubygems:
```
gem install class_state
```

Bundler:
```
	gem 'class_state'
```

## Implementation

manage a class' state using ClassState by including the ClassState::Owner module and optionally creating some state attribute readers/writers/accessors

	require 'class_state'

	class Operation
		include ClassState::Owner
	
		state_accessor :status, :default => 'unknown'
		state_reader :id, :attribute => :identifier
		state_writer :verbose
	end


## Initialize

the ClassState::Owner module creates an initialize method
which accepts an optional hash of values

	op1 = Operation.new 
	op2 = Operation.new(:verbose => true, :status => 'pending', :date => '2016-02-21')

## Access state object directly

the ClassState::Owner module provides direct access to the instance's ClassState object through the `state` method

	op1.state # => #<ClassState object>
	op1.state.set(:id => '101') # => #<ClassState object>
	op2.state.get(:date) # => '2016-02-21'
	op2.state[:status] # => 'pending'
	
For the complete API of the ClassState object see examples below

## Access state attributes through proxy methods

	# read/write
	op1.state[:status] # => nil ('status' state attribute doesn't exist)
	op1.status # => 'unknown' (default value)
	op1.status = 'started' # (updates state attribute value through writer proxy method)
	op1.status # => 'started' (updated value through reader proxy method)
	op1.state[:status] # => 'started' (updated value directly from state object)

	# read-only
	op1.id # => nil
	op1.id = 123 # => NoMethodError (read-only)
	op1.state[:id] = 123
	op1.id # => nil (the reader reads from state attribute `identifier`)
	op1.state[:identifier] = 456
	op1.id # => 456

	# write-only
	op1.verbose = true
	op1.verbose # NoMethodError (write-only)
	op1.state[:verbose] # => true


## Complete ClassState API

	# Initialize with (optional) values hash
	state =	ClassState.new(:verbose => true, :status => 'pending')

	# read state attributes
	state[:verbose] # => true
	state.get(:status) # => 'pending'
	state.data #=> {:verbose => true, :status => 'pending'}

	# update state
	state.update(:verbose => false, :id => 101)
	state.data # => {:verbose => false, :status => 'pending', :id => 101}
	state[:id] = 202
	state.data # => {:verbose => false, :status => 'pending', :id => 202}
	
	# (re-)set state
	state.set(:verbose => true)
	state.data # => {:verbose => true}
	state.set(:id => 123)
	state.data # => {:id => 123}

	# unset state attributes
	state.unset(:id)
	state.data # => {}
	state.set(:min => 1, :max => 10, :avg => 5)
	state.unset([:min, :max])
	state.data # => {:avg => 5}

	# block change callback
	state.on(:change) do |state, changes|
		puts changes.inspect
	end
	
	state.update(:key => 'value') # prints: {:key => 'value'}

	# instance method change callback
	instance = Class.new(Object) do
		def foo(state, changes)
			puts changes.inspect	
		end
	end.new
	
	state = ClassState.new(:min => 0, :max => 5)
	state.on(:change, instance, :foo)
	state.update(:min => 2, :max => 5) # prints: {:min => 2} (max didn't change)

	# specific attribute change callback
	state = ClassState.new(:min => 0, :max => 5)
	state.on(:change_attribute, :max) do |state, changes|
		puts changes.inspect
	end
	
	state.update(:min => 3, :average => 8) # nothing printed because 'max' didn't change
	state[:max] = 22 # prints: {:max => 22}
	state.update(:min => 5, :max => 15) # prints {:min => 5, :max => 15} because max changed, and all the update's changes are passed on to the callback
	
	
	# unset callback
	state = ClassState.new(:value => 4)
	state.on(:unset) do |state, changes|
		puts changes.inspect
	end
	
	state.unset(:value) # prints: {:value => 4}
	
	# :unset_attribute callback
	logger = Class.new(Object) do
		def log(state, changes)
			puts changes.inspect
		end
	end.new

	state = ClassState.new(:value => 5, :max => 100)
	state.on(:unset_attribute, :max, logger, :log)
	
	state.unset(:value) # prints nothing, because max is unaffected
	state.unset(:max) # prints: {:max => 100}
