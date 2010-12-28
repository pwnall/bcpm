# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests

# Raised when a test assertion fails.
class AssertionError < RuntimeError
  # Backtrace trimmed to the confines of the test suite.
  def short_backtrace
    path = Bcpm::Tests.suite_path
    trace = self.backtrace
    first_line = trace.find_index { |line| line.index path }
    last_line = trace.length - 1 - trace.reverse.find_index { |line| line.index path }
    trace = trace[first_line..last_line]
    trace[-1] = trace[-1].sub /in `.*'/, 'in (test case)'
    trace
  end
end  # class Bcpm::Tests::AssertionError

end  # namespace Bcpm::Tests

end  # namespace Bcpm
