require 'fileutils'
require 'thread'

# :nodoc: namespace
module Bcpm

# Pits players against other players.
module Duel
  # Has two players fight on all maps in both positions.
  def self.duel_pair(player1_name, player2_name, show_progress = false,
                     maps = nil)
    maps ||= Bcpm::Dist.maps.sort
    
    # Abort in case of typos.
    [player1_name, player2_name].each do |player|
      unless Bcpm::Player.wired? player
        puts "Player #{player} is not installed\n"
        exit 1
      end
    end

    # Abort in case of compile errors.
    env = Bcpm::Tests::Environment.new player1_name
    unless env.build
      print env.build_log
      exit 1
    end

    # Compute the matches.
    matches = maps.map { |map_name|
      [:a, :b].map do |side|
        Bcpm::Tests::TestMatch.new side, player2_name, map_name, env
      end
    }.flatten
    
    # Compute stats.
    score, wins, losses, errors = 0, [], [], []
    multiplex_matches(matches) do |match|
      score_delta = case match.winner
      when :a, :b
        (match.winner == match.side) ? 1 : -1
      else
        0
      end
      if show_progress
        print "#{player1_name} #{match.description}: #{outcome_string(score_delta)}\n"
        STDOUT.flush
      end
      score += score_delta if score_delta
      case score_delta
      when 1
        wins << match
      when -1
        losses << match
      when 0
        errors << match
      end
    end
    { :score => score, :wins => wins, :losses => losses, :errors => errors }
  end
  
  # Runs may matches in parallel.
  #
  # Returns the given matches. If given a block, also yields each match as it
  # becomes available.
  def self.multiplex_matches(matches)
     # Schedule matches.
    in_queue = Queue.new
    matches.each do |match|
      in_queue.push match
    end
    match_threads.times { in_queue.push nil }

    # Execute matches.
    out_queue = Queue.new
    old_abort = Thread.abort_on_exception
    Thread.abort_on_exception = true
    match_threads.times do
      Thread.new do
        loop do
          break unless match = in_queue.pop
          match.run false
          out_queue.push match
        end
      end
    end
    Thread.abort_on_exception = old_abort
   
    matches.length.times do
      match = out_queue.pop
      if Kernel.block_given?
        yield match
      end
    end
    matches
  end
  
  # The string to be shown for a match outcome.
  def self.outcome_string(score_delta)
    # TODO(pwnall): ANSI color codes
    if /mingw/ =~ RUBY_PLATFORM ||
        (/win/ =~ RUBY_PLATFORM && /darwin/ !~ RUBY_PLATFORM)
      {0 => "error", 1 => "won", -1 => "lost"}[score_delta]
    else
      {
        0 => "\33[33merror\33[0m",
        1 => "\33[32mwon\33[0m",
        -1 => "\33[31mlost\33[0m"
      }[score_delta]
    end
  end
  
  # Number of threads to use for simulating matches.
  def self.match_threads
    (Bcpm::Config[:match_threads] ||= default_match_threads).to_i
  end

  # Number of threads to use for simulating matches.
  def self.default_match_threads
    1
  end
  
  # Has all players compete against each other.
  def self.rank_players(player_list, show_progress = false, maps = nil)
    scores = {}
    0.upto(player_list.length - 1) do |i|
      0.upto(i - 1) do |j|
        outcome = duel_pair player_list[i], player_list[j], show_progress, maps
        scores[i] ||= 0
        scores[i] += outcome[:score]
        scores[j] ||= 0
        scores[j] -= outcome[:score]
      end
    end
    scores.map { |k, v| [v, player_list[k]] }.
           sort_by { |score, player| [-score, player] }
  end

  # Scores one player against the other players.
  def self.score_player(player, player_list, show_progress = false, maps = nil)
    player_list = player_list - [player]
    scores = player_list.map do |opponent|
       [
         duel_pair(player, opponent, show_progress, maps)[:score],
         opponent
       ]
    end
    { :points => scores.map(&:first).inject(0) { |a, b| a + b},
      :scores => scores.sort_by { |score, player| [score, player] } }    
  end
end  # module Bcpm::Duel

end  # namespace Bcpm
