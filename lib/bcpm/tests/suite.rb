# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests

# Collection of test cases.
class Suite
  # All the tests in the suite.
  attr_reader :tests
  
  # New suite.
  #
  # Args:
  #   case_files:: paths to the files containing test cases
  def initialize(case_files)
    @tests = []
    
    case_files.each do |file|
      code = File.read file
      klass = Class.new Bcpm::Tests::CaseBase
      klass.setup
      klass.class_eval code, file
      @tests += klass.tests
    end
  end
  
  # Runs all the tests in the suite.
  #
  # Args:
  #   env_names:: the local player names used to host the test environments.
  def run(env_names)
    wins, fails, errors, totals = 0, 0, 0, 0
    failures = []
    tests.each_with_index do |test, i|
      env_name = env_names[i]  # TODO(pwnall): env based on test      
      output = Bcpm::Match.match_data env_names[i], test.vs, test.map
      failure_string = nil
      begin
        if failure_string = test.check_output(output[:ant])
          fails += 1
          print 'F'
        else
          wins += 1
          print '.'
        end        
      rescue Exception => e
        errors += 1
        failure_string = "#{e.class.name}: #{e.to_s}\n#{e.backtrace.join("\n")}\n"
      end
      totals += 1
      if failure_string
        failures << [test, failure_string]
      end
    end
    print "\n#{totals} tests, #{wins} passed, #{fails} failures, #{errors} errors\n\n"
    failures.each_with_index do |failure, i|
      test, string = *failure
      print "#{'%3d' % (i + 1)}) Failed #{test.description}\n#{string}\n\n"
    end
  end
end  # class Bcpm::Tests::Suite

end  # namespace Bcpm::Tests

end  # namespace Bcpm
