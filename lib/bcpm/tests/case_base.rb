# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests
  
# Base class for test cases.
#
# Each test case is its own anonymous class.
class CaseBase
  class <<self
    # Called before any code is evaluated in the class.
    def setup
      @map = nil
      @vs = nil
      @tests = []
    end
  
    # Set the map for following matches.
    def map(map_name)
      @map = map_name.dup.to_s
    end
  
    # Set the enemy for following matches.
    def vs(player_name)
      @vs = player_name.dup.to_s
    end
  
    # TODO(pwnall): patch data
  
    # Create a match test. The block contains assertions for the match.
    def match(label = '(no description)', &block)
      # TODO(pwnall): environment processing
      # TODO(pwnall): pass patch data
      @tests << self.new(label, @vs, @map, block)
    end

    # All match tests.
    attr_reader :tests
  end
  
  # Descriptive label for the match test.
  attr_reader :label
  # Name of opposing player in the match.
  attr_reader :vs  
  # Name of map for the match.
  attr_reader :map
  # Match output.
  attr_reader :output

  # Called by match.
  def initialize(label, vs, map, block)
    @label = label
    @vs = vs
    @map = map
    @block = block
  end
  
  # User-readable description of test conditions.
  def description
    "vs #{vs} on #{map} (#{label})"
  end

  # Verifies the match output against the tests.
  def check_output(output)
    @output = output
    begin
      self.instance_eval &@block
      return nil
    rescue Bcpm::Tests::AssertionError => e
      return e
    end      
  end
  
  include Bcpm::Tests::Assertions
end  # class Bcpm::Tests::CaseBase

end  # namespace Bcpm::Tests

end  # namespace Bcpm
