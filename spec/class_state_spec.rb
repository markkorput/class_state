require File.dirname(__FILE__) + '/spec_helper'
require 'class_state'

describe ClassState do
    let(:instance){
        ClassState.new
    }

    # READERS

    describe ".data" do
        it 'gives a hash with the current values' do
            expect(instance.data).to eq({})
        end
    end

    describe '.get' do
        it 'gives the current value of a specified property' do
            expect(instance.get(:name)).to eq nil
            expect(instance.set(:name => 'billy').get(:name)).to eq 'billy'
        end
        
        it 'returns nil when specified attribute is not set' do
            expect(instance.get(:foo)).to eq nil
        end
    end

    describe '[]' do
        it 'gives the current value of a specified property' do
            expect(instance[:name]).to eq nil
            expect(instance.set(:name => 'billy')[:name]).to eq 'billy'
        end
        
        it 'returns nil when specified attribute is not set' do
            expect(instance[:foo]).to eq nil
        end
    end
    
    # WRITERS

    describe '[]=' do
        it 'updates a specified state attibute' do
            instance = ClassState.new.update(:name => 'johnny')
            expect(instance.data).to eq({:name => 'johnny'})
            instance[:name] = 'cash'
            expect(instance.data).to eq({:name => 'cash'})
        end
    end

    describe '.update' do
        it 'updates the current values with the given hash' do
            instance.update(:name => 'rachel', :age => 25)
            expect(instance.data).to eq({:name => 'rachel', :age => 25})
            instance.update(:shoe_size => 39)
            expect(instance.data).to eq({:name => 'rachel', :age => 25, :shoe_size => 39})
        end

        it 'supports linked notation' do
            expect(ClassState.new.update(:name => 'johnny').update(:name => 'cool-i-o').update(:age => 20).data).to eq({:name => 'cool-i-o', :age => 20})
        end
    end

    describe '.set' do
        it 'sets the current values to the given hash, overwriting any current values' do
            instance.set(:name => 'rachel', :age => 25)
            expect(instance.data).to eq({:name => 'rachel', :age => 25})
            instance.set(:shoe_size => 39)
            expect(instance.data).to eq({:shoe_size => 39})
        end
        
        it 'supports linked notation' do
            expect(ClassState.new.set(:name => 'johnny').set(:name => 'cool-i-o').set(:age => 20).data).to eq({:age => 20})
        end
    end

    describe '.unset' do
        it 'removes a previously set attribute' do
            instance = ClassState.new(:percentage => 65, :id => 101)
            expect(instance.data).to eq({:percentage => 65, :id => 101})
            expect(instance.unset(:id)).to eq({:id => 101}) # it returns a hash of removed attributes/values
            expect(instance[:id]).to eq nil
            expect(instance.data).to eq({:percentage => 65})
        end
        
        it 'accepts an array of attribute identifiers' do
            instance = ClassState.new(:percentage => 65, :id => 101)
            expect(instance.data).to eq({:percentage => 65, :id => 101})
            expect(instance.unset([:id, :percentage])).to eq({:percentage => 65, :id => 101}) # it returns a hash of removed attributes/values
            expect(instance.data).to eq({})
        end
        
        it 'ignores specified unknown attributes' do
           instance = ClassState.new(:percentage => 65, :id => 101)
           expect(instance.unset(:foo)).to eq({}) # :foo attribute doesn't exist
           expect(instance.unset([:foo, :bar])).to eq({}) # :foo and :bar attributes dosn't exist
           expect(instance.data).to eq({:percentage => 65, :id => 101}) # nothing changed
        end
    end

    # CALLBACKS

    describe '.on' do
        describe 'general :change event' do
            it 'accepts a block to run' do
                # we're gonna 'record' changes into this array
                recording = {}
                instance.on(:change) do |state, changes|
                    recording.merge!(changes)
                end
    
                expect(recording).to eq({})
                instance.set({:id => 123, :value => 'X'})
                expect(recording).to eq({:id => 123, :value => 'X'})
                instance.set({:record_id => 101})
                expect(instance.data).to eq({:record_id => 101})
                expect(recording).to eq({:id => nil, :value => nil, :record_id => 101})
            end

            it 'accepts a subject and method pair' do
                # create instance of temporary dummy class with callbacker method
                recorder = Class.new(Object) do
                    def recording
                        @recording ||= {}
                    end

                    def callbacker(state, changes)
                        recording.merge!(changes)
                    end
                end.new
    
                instance.on(:change, recorder, :callbacker) # on change, call the 'callbacker' method on instance
                expect(recorder.recording).to eq({}) # callback not triggered yet
                instance.update(:change => 'is').update(:a => 'sound') # these trigger the callback
                expect(recorder.recording).to eq({:change => 'is', :a => 'sound'}) # verify
            end
        end
        
        describe ':change_attribute event' do
            it 'runs a block callback' do
                recording = {} 
                instance.on(:change_attribute, :id) do |state, changes|
                    recording.merge!(changes)
                end

                expect(recording).to eq({})
                # change id to 1
                instance.set(:name => 'billy', :id => 1) 
                # all changes are given in the callback
                expect(recording).to eq({:name => 'billy', :id => 1})
                # no changes to id
                instance.update(:name => 'johnny')
                expect(recording).to eq({:name => 'billy', :id => 1})
                # change id to 2
                instance.update(:id => 2) 
                expect(recording).to eq({:name => 'billy', :id => 2})
            end
            
            it 'triggers a specified method on a given instance' do
                # create instance of temporary dummy class with callbacker method
                recorder = Class.new(Object) do
                    def recording
                        @recording ||= {}
                    end

                    def record(state, changes)
                        recording.merge!(changes)
                    end
                end.new
                
                # when a change to attribute 'id' happens,
                # call method 'record' on recorder
                instance.on(:change_attribute, :id, recorder, :record)

                expect(recorder.recording).to eq({})
                # change id to 1
                instance.set(:name => 'billy', :id => 1) 
                expect(recorder.recording).to eq(:name => 'billy', :id => 1)
                # no changes to id
                instance.update(:name => 'johnny')
                expect(recorder.recording).to eq(:name => 'billy', :id => 1)
                # change id to 2
                instance.update(:id => 2)
                expect(recorder.recording).to eq(:name => 'billy', :id => 2)
            end
        end
        
        describe 'general :unset event' do
            let(:instance){
                ClassState.new(:id => 101, :value => 50)
            }

            it 'takes a callback as a block' do
                # we're gonna 'record' changes here
                recording = {}

                instance.on(:unset) do |state, unsets|
                    recording.merge!(unsets)
                end
    
                # nothing yet
                expect(recording).to eq({})
                # set some initial values
                instance.update({:id => 123, :value => 'X'})
                # callback not triggered yet
                expect(recording).to eq({})
                # id
                instance.unset(:id)
                expect(recording).to eq({:id => 123})
                # value
                instance.unset(:value)
                expect(recording).to eq({:id => 123, :value => 'X'})
                # nothing
                instance.unset(:foo)
                expect(recording).to eq({:id => 123, :value => 'X'})
            end
            
            it 'takes a callback as a subject/method pair' do 
                # create instance of temporary dummy class with callbacker method
                recorder = Class.new(Object) do
                    def recording
                        @recording ||= {}
                    end

                    def callbacker(state, unsets)
                        recording.merge!(unsets)
                    end
                end.new

                instance = ClassState.new(:a => 'b', :c => 'd')
                # on 'unset' event, call the 'callbacker' method on instance
                instance.on(:unset, recorder, :callbacker)
                expect(recorder.recording).to eq({}) # callback not triggered yet
                instance.unset([:a, :c]) # trigger the callback
                expect(recorder.recording).to eq({:a => 'b', :c => 'd'}) # verify
            end
        end

        describe ':unset_attribute event' do
            let(:instance){
                ClassState.new(:id => 101, :value => 50)
            }

            it 'takes a callback as a block' do
                # we're gonna 'record' changes to id attribute here
                recording = {}

                instance.on(:unset_attribute, :id) do |state, unsets|
                    recording.merge!(unsets)
                end
    
                # nothing yet
                expect(recording).to eq({})
                # set some initial values
                instance.update({:id => 123, :value => 'X'})
                # callback not triggered yet
                expect(recording).to eq({})
                # id
                instance.unset(:id)
                expect(recording).to eq({:id => 123})
                # value
                instance.unset(:value)
                expect(recording).to eq({:id => 123})
            end
            
            it 'takes a callback as a subject/method pair' do 
                # create instance of temporary dummy class with callbacker method
                recorder = Class.new(Object) do
                    def recording
                        @recording ||= {}
                    end

                    def callbacker(state, unsets)
                        recording.merge!(unsets)
                    end
                end.new

                instance = ClassState.new(:a => 'b', :c => 'd')
                # when the :id attribute is unset, call the 'callbacker' method on instance
                instance.on(:unset_attribute, :a, recorder, :callbacker)
                expect(recorder.recording).to eq({}) # callback not triggered yet
                instance.unset(:c) # this doesn't trigger the callback
                expect(recorder.recording).to eq({}) # callback still not triggered
                instance.unset(:a) # triggers the callback
                expect(recorder.recording).to eq({:a => 'b'}) # verify
            end
        end
    end
end

