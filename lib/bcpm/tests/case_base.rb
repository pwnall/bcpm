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
    def _setup
      @map = nil
      @vs = nil
      @match = nil      
      @options = {}
      @env = Bcpm::Tests::Environment.new
      @env_used = false
      
      @tests = []
      @environments = []
      @matches = []
    end
    
    # Called after all code is evaluated in the class context.
    def _post_eval
      @environments << @env if @env_used
      @env = nil
      @options = nil
    end
    
    # Called by public methods before they change the environment.
    def _env_change
      if @env_used
        @environments << @env
        @env = Bcpm::Tests::Environment.new
        @env_used = false
      end
    end
  
    # Set the map for following matches.
    def map(map_name)
      @map = map_name.dup.to_s
    end
  
    # Set the enemy for following matches.
    def vs(player_name)
      @vs = player_name.dup.to_s
    end
    
    # Set a simulation option.
    def option(key, value)
      if value.nil?
        @options.delete key
      else
        @options[key] = value
      end
    end
    
    # Plugs a test class into the player code.
    def add_class(target, source)
      _env_change
      @env.file_op [:file, target, source]
    end

    # Replaces a player class with a test class.
    def replace_class(target, source)
      _env_change
      @env.file_op [:file, target, source]
    end
    
    # Replaces all fragments labeled with target_fragment in target_class with another fragment.
    def replace_code(target_class, target_fragment, source_class, source_fragment)
      _env_change
      @env.file_op [:fragment, [target_class, target_fragment], [source_class, source_fragment]]
    end
    
    # Redirects all method calls using a method name to a static method.
    def stub_call(source, target)
      _env_change
      @env.patch_op [:stub, target, source]
    end
  
    # Create a test match. The block contains test cases for the match.
    def match(&block)
      begin
        @env_used = true
        @match = Bcpm::Tests::TestMatch.new @vs, @map, @env, @options
        self.class_eval(&block)
        @matches << @match
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
