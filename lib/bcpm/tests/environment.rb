require 'English'
require 'fileutils'

# :nodoc: namespace
module Bcpm

# :nodoc: namespace
module Tests
  
# A match run for simulation purposes.
#
# Each test case is its own anonymous class.
class Environment
  # Name of the player container for the enviornment.
  attr_reader :player_name

  # Creates a new environment blueprint.
  #
  # Args:
  #   prebuilt_name:: if given, the created blueprint points to an already-built environment
  def initialize(prebuilt_name = nil)
    @file_ops = [] 
    @patch_ops = []
    @build_log = nil

    if prebuilt_name
      @player_name = prebuilt_name
      @available = true
    else
      @player_name = self.class.new_player_name
      @available = false
    end
  end
  
  # Puts together an environment according to the blueprint.
  #
  # Args:
  #   player_source_path_or_uri:: name or git uri for the player source code
  #   branch:: branch in git repository to be checked out
  def setup(player_source_path_or_uri, branch)
    return true if @available
    begin
      @player_path = Bcpm::Player.checkpoint player_source_path_or_uri, branch, player_name      
      raise "Failed to checkout player #{player_source_path_or_uri}" unless @player_path
      @player_src = Bcpm::Player.package_path(@player_path)
      
      @test_player = Bcpm::Tests.target_player
      @test_src = Bcpm::Tests.package_path
      
      file_ops
      patch_ops
      
      unless build
        print "Test environment build failed! Some tests will not run!\n"
        print "#{@build_log}\n"
        return false
      end
    rescue Exception => e
      print "Failed setting up test environment! Some tests will not run!\n"
      print "#{e.class.name}: #{e.to_s}\n#{e.backtrace.join("\n")}\n\n"
      return false
    end
    @available = true    
  end
  
  # True if the environment has been setup and can be used to run tests.
  def available? 
    @available
  end
  
  # Undoes the effects of setup.
  def teardown
    Bcpm::Player.uninstall player_name
    @available = false
  end
  
  # Queue an operation that adds a file.
  def file_op(op)
    @file_ops << op
  end
  
  # Queue an operation that patches all source files.
  def patch_op(op)
    @patch_ops << op
  end
  
  # Copies files from the test suite to the environment.
  #  
  # Called by setup, uses its environment.
  def file_ops
    @file_ops.each do |op|
      op_type, target, source = *op
      
      if op_type == :fragment
        target, target_fragment = *target
        source, source_fragment = *source
      end
      
      target.sub! /^#{@test_player}./, "#{@player_name}."
      source.sub! /^#{@test_player}./, "#{@player_name}."
      file_path = java_path(@test_src, source)
      
      next unless File.exist?(file_path)
      source_contents = File.read file_path

      case op_type        
      when :file
        contents = source_contents
      when :fragment
        next unless fragment_match = fragment_regexp(source_fragment).match(source_contents)
        contents = fragment_match[0]
      end
  
      contents.gsub! /(^|[^A-Za-z0-9_.])#{@test_player}([^A-Za-z0-9_]|$)/, "\\1#{@player_name}\\2"

      source_pkg = java_package(source)
      target_pkg = java_package(target)
      unless source_pkg == target_pkg
        contents.gsub! /(^|[^A-Za-z0-9_.])#{source_pkg}([^A-Za-z0-9_]|$)/, "\\1#{target_pkg}\\2"
      end
  
      source_class = java_class(source)
      target_class = java_class(target)
      unless source_class == target_class
        contents.gsub! /(^|[^A-Za-z0-9_])#{source_class}([^A-Za-z0-9_]|$)/, "\\1#{target_class}\\2"
      end
        
      file_path = java_path(@player_src, target)
      
      case op_type
      when :file
        next unless File.exist?(File.dirname(file_path))
      when :fragment
        next unless File.exist?(file_path)
        source_contents = File.read file_path
        # Not using a string because source code might contain \1 which would confuse gsub.
        source_contents.gsub! fragment_regexp(target_fragment) do |match|
          "#{$1}\n#{contents}\n#{$3}"
        end
        contents = source_contents
      end
      
      File.open(file_path, 'wb') { |f| f.write contents }  
    end
  end
  
  # Applies the patch operations to the source code in the environment.
  #
  # Called by setup, uses its environment.
  def patch_ops
    return if @patch_ops.empty?
    
    old_ops, @patch_ops = @patch_ops, []
    old_ops.each do |op|
      @patch_ops << [op[0], op[1].sub(/^#{@test_player}./, "#{@player_name}."),
                            op[2].sub(/^#{@test_player}./, "#{@player_name}.")]
    end
    
    Dir.glob(File.join(@player_src, '**', '*.java')).each do |file|
      old_contents = File.read file
      lines = old_contents.split("\n")

      stubs_enabled = true

      0.upto(lines.count - 1) do |i|
        line = lines[i]
        if directive_match = /^\s*\/\/\$(.*)$/.match(line)
          directive = directive_match[1]
          case directive.strip.downcase
          when '+stubs', '-stubs'
            stubs_enabled = directive[0] == ?+
          end
        else
          @patch_ops.each do |op|
            op_type, target, source = *op
      
            case op_type
            when :stub
              if stubs_enabled
                line.gsub! /(^|[^A-Za-z0-9_.])([A-Za-z0-9_.]*)\.#{source}\(/, "\\1#{target}(\\2,"
              end
            end
          end
        end
      end
      contents = lines.join("\n")
      File.open(file, 'wb') { |f| f.write contents } unless contents == old_contents
    end
  end
  
  # Builds the binaries for the player in this environment.
  #
  # Called by setup, uses its environment.
  #
  # Returns true for success, false for failure.
  def build
    uid = 'build_' + player_name
    tempdir = File.join Dir.tmpdir, uid
    FileUtils.mkdir_p tempdir
    Dir.chdir tempdir do
      filebase = Dir.pwd
      build_log = File.join filebase, 'build.log'
      build_file = File.join filebase, 'build.xml'
      build_output = Bcpm::Match.write_build build_file, 'bc.conf'
      
      Bcpm::Match.run_build_script build_file, build_log, 'build'
      @build_log = File.exist?(build_log) ? File.open(build_log, 'rb') { |f| f.read } : build_output      
    end
    FileUtils.rm_rf tempdir
    
    @build_log.index("\nBUILD SUCCESSFUL\n") ? true : false
  end
  
  # Regular expression matching a code fragment.
  #
  # The expression captures three groups: the fragment start marker, the fragment, and the fragment
  # end marker.
  def fragment_regexp(label)
    /^([ \t]*\/\/\$[ \t]*\+mark\:[ \t]*#{label}\s)(.*)(\n[ \t]*\/\/\$[ \t]*\-mark\:[ \t]*#{label}\s)/m
  end
  
  # Path to .java source for a class.
  def java_path(package_path, class_name)
    File.join(File.dirname(package_path), class_name.gsub('.', '/') + '.java')
  end
  
  # Package for a Java class given its fully qualified name.
  def java_package(class_name)
    index = class_name.rindex '.'
    index ? class_name[0, index] : ''
  end

  # Short class name for a Java class given its fully qualified name.
  def java_class(class_name)
    index = class_name.rindex '.'
    index ? class_name[index + 1, class_name.length - index - 1] : class_name
  end

  # A player name guaranteed to be unique across the systme.
  def self.new_player_name
    @prefix ||= "test_#{(Time.now.to_f * 1000).to_i}_#{$PID}"
    @counter ||= 0
    @counter += 1
    "#{@prefix}_#{@counter}"
  end
end  # class Bcpm::Tests::TestMatch

end  # namespace Bcpm::Tests

end  # namespace Bcpm
