# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests

# Raised when a test assertion fails.
class AssertionError < RuntimeError
  # Backtrace trimmed to the confines of the test suite.
  def short_backtrace
    self.class.short_backtrace self.backtrace
  end
  
  # Trims backtrace to the confines of the test suite.
  def self.short_backtrace(backtrace)
    path = Bcpm::Tests.suite_path
    trace = backtrace
    first_line = trace.find_index { |line| line.index path }
    last_line = trace.length - 1 - trace.reverse.find_index { |line| line.index path }
    # Leave the trace untouched if it doesn't go through the test suite.
    if first_line && last_line
      trace = trace[first_line..last_line]
      trace[-1] = trace[-1].sub /in `.*'/, 'in (test case)'
    end
    trace
  end
end  # class Bcpm::Tests::AssertionError

end  # namespace Bcpm::Tests

end  # namespace Bcpm
