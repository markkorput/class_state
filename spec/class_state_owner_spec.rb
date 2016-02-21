require File.dirname(__FILE__) + '/spec_helper'
require 'class_state'

describe ClassState::Owner do
    let(:klass){
        Class.new do
            include ClassState::Owner
        end
    }

    let(:data){
        {:treshold => 45, :verbose => false}   
    }

    describe '.state' do
        let(:instance){
            klass.new(data)
        }

        it 'gives the instance\'s configuration object' do
            expect(instance.state.class).to eq ClassState
        end

        it 'allows you to access all ClassState functionality directly on the object itself' do
            expect(instance.state.update(:treshold => 50))
            expect(instance.state[:treshold]).to eq 50
            expect(instance.state.data).to eq(:treshold => 50, :verbose => false)
        end
    end

    describe '.initialize' do
        it 'creates a default initialize method that accepts a hash parameter with configuration values' do
            # without 
            expect(klass.new(:name => 'bill', :age => 45).state.data).to eq(:name => 'bill', :age => 45)
        end

        it 'configuration through initialize is optional' do
            expect(klass.new.state.data).to eq({})
        end
    end

    # state attribute proxy methods

    describe 'self.state_reader' do
        let(:klass){
            Class.new do
                include ClassState::Owner
                state_writer :name
            end
        }
        
        let(:instance){
            klass.new
        }

        it 'creates a state attribute-writer proxy method in the owner' do
            expect(instance.state[:name]).to eq nil
            instance.name = 'freddy'
            expect(instance.state[:name]).to eq 'freddy'
        end
        
        describe ':attribute option' do
            it 'lets the caller specify a state-attribute with a different name than the setter method' do
                klass.state_writer :age, :attribute => :value
                instance = klass.new
                expect(instance.state.data).to eq({})
                instance.age = 35
                expect(instance.state.data).to eq(:value => 35)
            end
        end
    end

    describe 'self.state_writer' do
        let(:klass){
            Class.new do
                include ClassState::Owner
                state_reader :name
            end
        }
        
        let(:instance){
            klass.new
        }

        it 'creates a state attribute-writer proxy method in the owner' do
            instance.state.set(:name => 'bobby')
            expect(instance.name).to eq 'bobby'
        end

        describe ':attribute option' do
            it 'lets the caller specify a state-attribute with a different name than the setter method' do
                # expect(instance.respond_to?(:age)).to eq false
                instance.class.state_reader :age, :attribute => :year
                # expect(instance.respond_to?(:age)).to eq true
                # age getter method doesn't read the age state attribute
                instance.state.set(:age => 23)
                expect(instance.age).to eq nil
                # it reads the year state attribute
                instance.state.set(:year => 24)
                expect(instance.age).to eq 24
            end
        end
        
        describe ':default option' do
            it 'lets the caller define a default value for when the ClassState\'s attribute is nil' do
                # expect(instance.respond_to?(:foo)).to eq false
                instance.class.state_reader :foo, :default => 'bar'
                # expect(instance.respond_to?(:foo)).to eq true
                expect(instance.state[:foo]).to eq nil # foo attribute not set in the ClassState
                expect(instance.foo).to eq 'bar' # the getter returns the default value
            end
            
            it 'plays nice with the :attribute option' do
                # expect(instance.respond_to?(:foo)).to eq false
                # expect(instance.respond_to?(:bar)).to eq false
                instance.class.state_reader :foo, :attribute => :bar, :default => 'foo'
                # expect(instance.respond_to?(:foo)).to eq true
                # expect(instance.respond_to?(:bar)).to eq false
                expect(instance.foo).to eq 'foo' # the getter returns the default value
                instance.state.set(:bar => 'foobar')
                expect(instance.foo).to eq 'foobar' # reads bar state attribute
            end
        end
    end

    describe 'self.state_accessor' do
        let(:klass){
            Class.new do
                include ClassState::Owner
                state_accessor :name
            end
        }
        
        let(:instance){
            klass.new
        }

        it 'creates state attribute-reader/writer proxy methods in the owner' do
            expect(instance.state[:name]).to eq nil
            instance.name = 'john'
            expect(instance.state[:name]).to eq 'john'
            expect(instance.name).to eq 'john'
        end

        describe ':attribute option' do
            it 'lets the caller specify a state-attribute with a different name than the method' do
                # no accessor methods
                # expect(instance.respond_to?(:age)).to eq false
                # expect(instance.respond_to?(:age=)).to eq false
                # create methods
                instance.class.state_accessor :age, :attribute => :years_old
                # vieryf methods
                # expect(instance.respond_to?(:age)).to eq true
                # expect(instance.respond_to?(:age=)).to eq true

                # initial status
                expect(instance.state[:years_old]).to eq nil
                expect(instance.age).to eq nil
                # update
                instance.age = '99'

                # state verifications
                expect(instance.state[:age]).to eq nil
                expect(instance.state[:years_old]).to eq '99'
                # reader method verification
                expect(instance.age).to eq '99'
            end
        end
        
        describe ':default option' do
            it 'works like the self.state_reader :default option' do
                instance.class.state_accessor :v1, :default => '100%'
                expect(instance.state[:v1]).to eq nil
                expect(instance.v1).to eq '100%'
                instance.v1 = '200%'
                expect(instance.v1).to eq '200%'
            end
            
            it 'plays nice with the :attribute option' do
                instance.class.state_accessor :v2, :attribute => :percentage, :default => '10%'
                expect(instance.state[:v2]).to eq nil
                expect(instance.state[:percentage]).to eq nil
                expect(instance.v2).to eq '10%'
                instance.v2 = '20%'
                expect(instance.v2).to eq '20%'
                expect(instance.state[:percentage]).to eq '20%'
                expect(instance.state.data.keys.include?(:v2)).to eq false
            end
        end
    end
end
