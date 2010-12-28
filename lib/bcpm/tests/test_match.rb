# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests
  
# A match run for simulation purposes.
#
# Each test case is its own anonymous class.
class TestMatch
  # Name of opposing player in the match.
  attr_reader :vs  
  # Name of map for the match.
  attr_reader :map
  
  # The environment that the match runs in.
  attr_reader :environment

  # Match output. Nil if the match hasn't completed.
  attr_reader :output
  
  # Detailed match data.
  attr_reader :data

  # Skeleton for a match.
  def initialize(vs, map)
    @vs = vs
    @map = map
    # TODO(pwnall): environment reuse
    @environment = Bcpm::Tests::Environment.new
    @output = nil
    @data = nil
  end
  
  # Run the game.
  def run
    @data = Bcpm::Match.match_data @environment.player_name, @vs, @map
    @output = data[:ant]
  end

  # True if the test match has run, and its results are available.
  def ran?
    !output.nil?
  end

  # User-readable description of match conditions.
  def description
    "vs #{vs} on #{map}"
  end
    
  # The match output, split into lines.
  def output_lines
    @output_lines ||= output.split("\n")
  end
end  # class Bcpm::Tests::TestMatch

end  # namespace Bcpm::Tests

end  # namespace Bcpm
