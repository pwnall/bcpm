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
    p match.output
    puts match.output
    if match.output.index(/\n(\S*)Exception(.*?)\n\S/m)
      raise Bcpm::Tests::AssertionError, "Player should not have thrown exceptions! " +
          "It threw #{$1}Exception#{$2}"
    end
  end
  
  # Always fails. Useful for obtaining the game log.
  def fail
    raise Bcpm::Tests::AssertionError, 'Test case called fail!'
  end
end

end  # namespace Bcpm::Tests
  
end  # namespace Bcpm
