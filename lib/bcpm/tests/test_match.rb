require 'tmpdir'

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
  def initialize(vs, map, environment, options = {})
    @vs = vs
    @map = map
    @options = options.clone
    @environment = environment
    @output = nil
    @data = nil
  end
  
  # Run the game.
  def run(live = false)
    @data = Bcpm::Match.match_data @environment.player_name, @vs, @map, live, @options
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
  
  # The output line showing who won the game.
  def outcome
    outcome = output_lines[-3] || ''
    outcome = '(no victory)' unless outcome.index('wins')
    outcome
  end

  # The output line showing the reason the game ended.
  def reason
    reason = output_lines[-2] || ''
    reason = '(no reason)' unless reason.index('Reason:')
    reason
  end
  
  # Stashes the match data somewhere on the system.
  #
  # Returns a string containing user-friendly instructions for accessing the match data.
  def stash_data
    txt_path = File.join Dir.tmpdir, data[:uid] + '.txt'
    File.open(txt_path, 'wb') { |f| f.write output } unless File.exist?(txt_path)
    rms_path = File.join Dir.tmpdir, data[:uid] + '.rms'
    File.open(rms_path, 'wb') { |f| f.write data[:rms] }  unless File.exist?(rms_path)
  
    "Output: #{open_binary} #{txt_path}\nReplay: bcpm replay #{rms_path}\n"  
  end  

  # Name of program for opening text files.
  def open_binary
    return ENV['EDITOR'] if ENV['EDITOR']
    case RUBY_PLATFORM
    when /darwin/
      'open'
    when /win/
      'notepad'
    when /linux/
      'gedit'
    end
  end
end  # class Bcpm::Tests::TestMatch

end  # namespace Bcpm::Tests

end  # namespace Bcpm
