require 'tmpdir'

# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests
  
# A match run for simulation purposes.
#
# Each test case is its own anonymous class.
class TestMatch
  # Side of the tested player in the match.
  attr_reader :side
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
  def initialize(side, vs, map, environment, options = {})
    @side = side
    @vs = vs
    @map = map
    @options = options.clone
    @environment = environment
    @output = nil
    @data = nil
    
    @output_lines = nil
    @outcome = nil
    @winner = nil
    @reason = nil
  end
  
  # Run the game.
  def run(live = false)
    case @side
    when :a
      @data = Bcpm::Match.match_data @environment.player_name, @vs, true, @map, live, @options
    when :b
      @data = Bcpm::Match.match_data @vs, @environment.player_name, false, @map, live, @options
    end
    @output = data[:ant]
  end

  # True if the test match has run, and its results are available.
  def ran?
    !output.nil?
  end

  # User-readable description of match conditions.
  def description
    if File.basename(map) == map
      map_name = map
    else
      map_name = "suite/maps/#{File.basename(map).sub(/\.xml$/, '')}"
    end
    desc = "as team #{side.to_s.upcase} vs #{vs} on #{map_name}"
    unless @options.empty?
      desc += ' with ' + options.map { |k, v| "#{k}=#{v}" }.join(",")
    end
    desc
  end
    
  # The match output, split into lines.
  def output_lines
    @output_lines ||= output.split("\n")
  end
  
  # The output printed by map units, without the [source] prefixess.
  def chatter
    @chatter ||= output_lines.map { |line| line.gsub /^\[[^\]]+\]\s/, '' }.reject(&:empty?).join("\n")
  end
  
  # The output line showing who won the game.
  def outcome
    return @outcome if @outcome
    @outcome = output_lines[-3] || ''
    @outcome = '(no victory)' unless outcome.index('wins')
    @outcome
  end
  
  # The side that own the game
  def winner
    return @winner if @winner
    win_match = /\((.)\) wins/.match outcome
    @winner = if win_match
      (win_match[1] == 'A') ? :a : :b
    else
      :error
    end
    @winner
  end

  # The output line showing the reason the game ended.
  def reason
    return @reason if @reason
    @reason = output_lines[-2] || ''
    @reason = '(no reason)' unless reason.index('Reason:')
    @reason
  end
  
  # Stashes the match data somewhere on the system.
  #
  # Returns a string containing user-friendly instructions for accessing the match data.
  def stash_data
    path = self.class.gamesave_path
    FileUtils.mkdir_p path
    
    txt_path = File.join path, data[:uid] + '.txt'
    File.open(txt_path, 'wb') { |f| f.write output } unless File.exist?(txt_path)
    rms_path = File.join path, data[:uid] + '.rms'
    File.open(rms_path, 'wb') { |f| f.write data[:rms] }  unless File.exist?(rms_path)
  
    "Output: #{open_binary} #{txt_path}\nReplay: bcpm replay #{rms_path}\n"
  end
  
  # All game replays saved by calls to stash_data.
  def self.stashed_replays
    Dir.glob File.join(gamesave_path, '*.rms')
  end
  
  # All game outputs saved by calls to stash_data.
  def self.stashed_outputs
    Dir.glob File.join(gamesave_path, '*.txt')
  end
  
  # Path where game data (output, replay binlog) is saved.
  def self.gamesave_path
    Bcpm::Config[:gamesave_path] ||= default_gamesave_path
  end

  # Path where game data (output, replay binlog) is saved.
  def self.default_gamesave_path
    File.join Dir.tmpdir, 'bcpm'
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
