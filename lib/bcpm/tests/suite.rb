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
  
  # New suite.
  #
  # Args:
  #   case_files:: paths to the files containing test cases
  def initialize(case_files)
    @tests = []
    @matches = []
    @environments = []
    
    case_files.each do |file|
      code = File.read file
      klass = Class.new Bcpm::Tests::CaseBase
      klass.setup
      klass.class_eval code, file
      @tests += klass.tests
      @matches += klass.matches
      @environments += klass.environments
    end
  end
  
  # Runs all the tests in the suite.
  def run
    wins, fails, errors, totals = 0, 0, 0, 0
    failures = []
    tests.each_with_index do |test, i|
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
      
      txt_path = File.join '/tmp', test.match.data[:uid] + '.txt'
      File.open(txt_path, 'w') { |f| f.write test.match.output }
      rms_path = File.join '/tmp', test.match.data[:uid] + '.rms'
      File.open(rms_path, 'w') { |f| f.write test.match.data[:rms] }
      
      print "Output: open #{txt_path}\nReplay: bcpm replay #{rms_path}\n"
      print "#{string}\n\n"
    end
  end
end  # class Bcpm::Tests::Suite

end  # namespace Bcpm::Tests

end  # namespace Bcpm
