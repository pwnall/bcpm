# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests
  
# Base class for test cases.
#
# Each test case is its own anonymous class.
class CaseBase
  class <<self
    # Called before any code is evaluated in the class context.
    def setup
      @map = nil
      @vs = nil
      @match = nil
      @tests = []
      @environments = []
      @matches = []
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
  
    # Create a test match. The block contains test cases for the match.
    def match(&block)
      begin
        @match = Bcpm::Tests::TestMatch.new @vs, @map
        self.class_eval(&block)
        @matches << @match
        # TODO(pwnall): environment reuse
        @environments << @match.environment
      ensure
        @match = nil
      end
    end

    # Create a test match.
    def it(label, &block)
      raise "it can only be called within match blocks!" if @match.nil?        
      @tests << self.new(label, @match, block)
    end

    # All the environments used in the tests.
    attr_reader :environments
    # All the matches used in the tests.
    attr_reader :matches
    # All test cases.
    attr_reader :tests
  end
  
  # Descriptive label for the test case.
  attr_reader :label
  # Test match used by the test case.
  attr_reader :match
  
  # Called by match.
  def initialize(label, match, block)
    @label = label
    @match = match
    @block = block
  end
  
  # User-readable description of test conditions.
  def description
    "#{match.description} #{label}"
  end

  # Verifies the match output against the test case.
  #
  # Returns nil for success, or an AssertionError exception if the case failed.
  def check_output
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
