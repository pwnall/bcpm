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
  # Path to the suite's local repository.
  attr_reader :local_path
  
  # Blank suite.
  def initialize(local_path)
    @local_path = local_path
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
        trace = short_backtrace e.backtrace
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
  def run(live = false)
    environments.each { |e| e.setup local_path }

    wins, fails, errors, skipped, totals = 0, 0, 0, 0, 0
    failures = []
    tests.each_with_index do |test, i|
      unless test.match.environment.available?
        skipped += 1
        next
      end
      
      unless test.match.ran?
        test.match.run live
        # Only one match can run live, otherwise all hell will break loose.
        live = false
      end
      failure_string = nil
      begin
        if failure = test.check_output
          trace = short_backtrace failure.backtrace
          failure_string = "#{failure.to_s}\n#{trace.join("\n")}"
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

    environments.each { |e| e.teardown }
    self
  end
  
  # Trims backtrace to the confines of the test suite.
  def short_backtrace(backtrace)
    trace = backtrace
    first_line = trace.find_index { |line| line.index local_path }
    last_line = trace.length - 1 - trace.reverse.find_index { |line| line.index local_path }
    # Leave the trace untouched if it doesn't go through the test suite.
    if first_line && last_line
      trace = trace[first_line..last_line]
      trace[-1] = trace[-1].sub /in `.*'/, 'in (test case)'
    end
    trace
  end   
end  # class Bcpm::Tests::Suite

end  # namespace Bcpm::Tests

end  # namespace Bcpm
