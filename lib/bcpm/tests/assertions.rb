# :nodoc: namespace
module Bcpm
  
# :nodoc: namespace
module Tests
  
# Assertions for match tests.
module Assertions
  # The match output, split into lines.
  def _output_lines
    @_output_lines ||= output.split("\n")
  end
  
  # Fails unless the match was won.
  def should_win
    return if _output_lines[-3].index(' (A) wins')
    raise Bcpm::Tests::AssertionError, 'Player was expected to win, but lost'
  end

  # Fails unless the match was won, and the Reason: line includes the argument text. 
  def should_win_by(reason)
    should_win
    
    return if output_lines[-2].index(reason)
    raise Bcpm::Tests::AssertionError, "Player was expected to win by #{reason} and didn't. " +
        _output_lines[-2]
  end  

  # Fails if the player code threw any exception.
  def should_not_throw
    if output.index(/^(\S*)Exception:/)
      raise Bcpm::Tests::AssertionError, "Player should not have thrown exceptions. " +
          "It threw #{$1}Exception"
    end
  end
end

end  # namespace Bcpm::Tests
  
end  # namespace Bcpm
