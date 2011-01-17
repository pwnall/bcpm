require 'fileutils'

# :nodoc: namespace
module Bcpm

# Pits players against other players.
module Duel
  # Has two players fight on all maps in both positions.
  def self.duel_pair(player1_name, player2_name, show_progress = false,
                     maps = nil)
    maps ||= Bcpm::Dist.maps.sort
    
    env = Bcpm::Tests::Environment.new player1_name
    score, wins, losses, ties = 0, 0, 0, 0
    maps.each do |map|
      [:a, :b].each do |side|
        match = Bcpm::Tests::TestMatch.new side, player2_name, map, env
        if show_progress
          print "#{player1_name} #{match.description}... "
          STDOUT.flush
        end
        match.run false
        score_delta = case match.winner
        when :a, :b
          (match.winner == side) ? 1 : -1
        else
          score_delta = 0
        end
        if show_progress          
          print outcome_string(score_delta) + "\n"
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
    end
    { :score => score, :wins => wins, :losses => losses, :ties => ties }
  end
  
  # The string to be shown for a match outcome.
  def self.outcome_string(score_delta)
    # TODO(pwnall): ANSI color codes
    {0 => "tie", 1 => "won", -1 => "lost"}[score_delta]
  end  
end  # module Bcpm::Duel

end  # namespace Bcpm
