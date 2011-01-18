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
    
    # Schedule matches.
    in_queue = Queue.new
    match_count = 0
    maps.each do |map|
      [:a, :b].each do |side|
        match = Bcpm::Tests::TestMatch.new side, player2_name, map, env
        in_queue.push match
        match_count += 1
      end
    end
    duel_threads.times { in_queue.push nil }

    # Execute matches.
    out_queue = Queue.new
    old_abort = Thread.abort_on_exception
    Thread.abort_on_exception = true
    duel_threads.times do
      Thread.new do
        loop do
          break unless match = in_queue.pop
          match.run false
          out_queue.push match
        end
      end
    end
    Thread.abort_on_exception = old_abort
    
    # Compute stats.
    score, wins, losses, ties = 0, 0, 0, 0
    match_count.times do
      match = out_queue.pop
      score_delta = case match.winner
      when :a, :b
        (match.winner == match.side) ? 1 : -1
      else
        score_delta = 0
      end
      if show_progress
        print "#{player1_name} #{match.description}: #{outcome_string(score_delta)}\n"
        STDOUT.flush
      end
      score += score_delta
      case score_delta
      when 1
        wins += 1
      when -1
        losses += 1
      else
        ties += 1
      end
    end
    { :score => score, :wins => wins, :losses => losses, :ties => ties }
  end
  
  # The string to be shown for a match outcome.
  def self.outcome_string(score_delta)
    # TODO(pwnall): ANSI color codes
    {0 => "tie", 1 => "won", -1 => "lost"}[score_delta]
  end
  
  # Number of threads to use for computing duel matches.
  def self.duel_threads
    (Bcpm::Config[:duel_threads] ||= default_duel_threads).to_i
  end

  # Number of threads to use for computing duel matches.
  def self.default_duel_threads
    1
  end
end  # module Bcpm::Duel

end  # namespace Bcpm
