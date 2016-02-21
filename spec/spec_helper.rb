# loads and runs all tests for the rxsd project
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rspec'

require 'logger'

begin
  require 'byebug'
rescue LoadError => e
  Logger.new(STDOUT).warn("Could not load byebug, continuing without it")
end

$: << File.expand_path('../lib', File.dirname(__FILE__))

