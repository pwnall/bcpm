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
  # Custom options for the battlecode simulator.
  attr_reader :options
  
  # The environment that the match runs in.
  attr_reader :environment

  # Match output. Nil if the match hasn't completed.
  attr_reader :output
  
  # Detailed match data.
  attr_reader :data

  # Skeleton for a match.
  def initialize(vs, map, environment, options)
    @vs = vs
    @map = map
    @options = options.clone
    @environment = environment
    @output = nil
    @data = nil
  end
  
  # Run the game.
  def run
    @data = Bcpm::Match.match_data @environment.player_name, @vs, @map, @options
    @output = data[:ant]
  end

  # True if the test match has run, and its results are available.
  def ran?
    !output.nil?
  end

  # User-readable description of match conditions.
  def description
    desc = "vs #{vs} on #{map}"
    unless @options.empty?
      desc += ' with ' + options.map { |k, v| "#{k}=#{v}" }.join(",")
    end
    desc
  end
    
  # The match output, split into lines.
  def output_lines
    @output_lines ||= output.split("\n")
  end
end  # class Bcpm::Tests::TestMatch

end  # namespace Bcpm::Tests

end  # namespace Bcpm
