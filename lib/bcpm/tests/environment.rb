require 'English'

# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests
  
# A match run for simulation purposes.
#
# Each test case is its own anonymous class.
class Environment
  # Name of the player container for the enviornment.
  attr_reader :player_name

  # Creates a new environment blueprint.
  def initialize
    @player_name = self.class.new_player_name
  end
  
  # Puts together an environment according to the blueprint.
  #
  # Args:
  #   player_source_path_or_uri:: name or git uri for the player source code
  def setup(player_source_path_or_uri, branch)
    Bcpm::Player.checkpoint player_source_path_or_uri, branch, player_name    
  end
  
  # Undoes the effects of setup.
  def teardown
    Bcpm::Player.uninstall player_name
  end
  
  # A player name guaranteed to be unique across the systme.
  def self.new_player_name
    @prefix ||= "test_#{(Time.now.to_f * 1000).to_i}_#{$PID}"
    @counter ||= 0
    @counter += 1
    "#{@prefix}_#{@counter}"
  end
end  # class Bcpm::Tests::TestMatch

end  # namespace Bcpm::Tests

end  # namespace Bcpm
