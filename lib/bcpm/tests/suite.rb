# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests

# Collection of test cases.
class Suite
  # All the environments used in the tests.
  attr_reader :environments
  # All the matches used in the tests.
  attr_reader :matches
  # All test cases.
  attr_reader :tests
  
  # Blank suite.
  def initialize
    @tests = []
    @matches = []
    @environments = []
  end
  
  # Adds the given test cases to the suite.
  def add_cases(case_files)    
    case_files.each do |file|
      code = File.read file
      klass = Class.new Bcpm::Tests::CaseBase
      klass._setup
      begin
        klass.class_eval code, file
      rescue Exception => e
        trace = Bcpm::Tests::AssertionError.short_backtrace e.backtrace
        print "Error in test case #{file}\n"
        print "#{e.class.name}: #{e.to_s}\n#{trace.join("\n")}\n\n"
        next
      end
      klass._post_eval
      @tests += klass.tests
      @matches += klass.matches
      @environments += klass.environments
    end
    self
  end
  
  # Runs all the tests in the suite.
  def run
    wins, fails, errors, skipped, totals = 0, 0, 0, 0, 0
    failures = []
    tests.each_with_index do |test, i|
      unless test.match.environment.available?
        skipped += 1
        next
      end
      
      test.match.run unless test.match.ran?
      failure_string = nil
      begin
        if failure = test.check_output
          failure_string = "#{failure.to_s}\n#{failure.short_backtrace.join("\n")}"
          fails += 1
          print 'F'
        else
          wins += 1
          print '.'
        end        
      rescue Exception => e
        errors += 1
        failure_string = "#{e.class.name}: #{e.to_s}\n#{e.backtrace.join("\n")}"
      end
      totals += 1
      if failure_string
        failures << [test, failure_string]
      end
    end
    print "\n#{totals} tests, #{wins} passed, #{fails} failures, #{errors} errors\n\n"
    failures.each_with_index do |failure, i|
      test, string = *failure
      print "#{'%3d' % (i + 1)}) Failed #{test.description}\n"

      print test.match.stash_data            
      print "#{string}\n\n"
    end
  end  
end  # class Bcpm::Tests::Suite

end  # namespace Bcpm::Tests

end  # namespace Bcpm
