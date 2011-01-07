# :nodoc: namespace
module Bcpm
  
# :nodoc: namespace
module Tests
  
# Assertions for match tests.
module Assertions  
  # Fails unless the match was won.
  def should_win
    return if match.outcome.index(' (A) wins')
    raise Bcpm::Tests::AssertionError, "Player was expected to win, but didn't! " + match.outcome
  end

  # Fails unless the match was won, and the Reason: line includes the argument text. 
  def should_win_by(reason)
    should_win
    
    return if match.reason.index(reason)
    raise Bcpm::Tests::AssertionError, "Player was expected to win by #{reason} and didn't. " +
                                       match.reason
  end  

  # Fails if the player code threw any exception.
  def should_not_throw
    if match.output.index(/\n(\S*)Exception(.*?)\n\S/m)
      raise Bcpm::Tests::AssertionError, "Player should not have thrown exceptions! " +
          "It threw #{$1}Exception#{$2}"
    end
    puts match.chatter
    if match.chatter.index(/\n(\S*)Exception(.*?)\n\S/m)
      raise Bcpm::Tests::AssertionError, "Player should not have thrown exceptions! " +
          "It threw #{$1}Exception#{$2}"
    end
  end
  
  # Always fails. Useful for obtaining the game log.
  def fail(reason = 'Test case called fail!')
    raise Bcpm::Tests::AssertionError, reason
  end
  
  # Fails unless a unit's output matches the given regular expression.
  #
  # If a block is given, yields to the block for every match.
  def should_match_unit_output(pattern)
    matched = false
    
    match.output_lines.each do |line|
      next unless unit_output = _parse_unit_output(line)
      if match = pattern.match(unit_output[:output])
        matched = true
        if Kernel.block_given?
          yield unit_output, match
        else
          break
        end
      end
    end
        
    raise Bcpm::Tests::AssertionError, "No unit output matched #{pattern.inspect}!" unless matched
  end
  
  # Parses a unit's console output (usually via System.out.print*).
  #
  # If the given line looks like a unit's console output, returns a hash with the following keys:
  #   :team:: 'A' or 'B' (should always be 'A', unless the case enables team B's console output)
  #   :unit_type:: e.g., 'ARCHON'
  #   :unit_id:: the robot ID of the unit who wrote the line, parsed as an Integer
  #   :round:: the round when the line was output, parsed as an Integer
  #   :output:: the (first line of the) string that the unit produced
  #
  # If the line doesn't parse out, returns nil.
  def _parse_unit_output(line)
    line_match = /^\[([AB])\:([A-Z]+)\#(\d+)\@(\d+)\](.*)$/.match line
    return nil unless line_match
    {
      :team => line_match[1],
      :unit_type => line_match[2],
      :unit_id => line_match[3].to_i,
      :round => line_match[4].to_i,
      :output => line_match[5]
    }
  end
end

end  # namespace Bcpm::Tests
  
end  # namespace Bcpm
