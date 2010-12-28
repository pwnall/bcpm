require 'English'

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
  def initialize
    @player_name = self.class.new_player_name
    @file_ops = [] 
    @patch_ops = []
  end
  
  # Puts together an environment according to the blueprint.
  #
  # Args:
  #   player_source_path_or_uri:: name or git uri for the player source code
  #   branch:: branch in git repository to be checked out
  def setup(player_source_path_or_uri, branch)
    @player_path = Bcpm::Player.checkpoint player_source_path_or_uri, branch, player_name
    @player_src = Bcpm::Player.package_path @player_path
    
    @test_player = Bcpm::Tests.target_player
    @test_src = Bcpm::Tests.package_path
    
    file_ops
    patch_ops
  end
  
  # Undoes the effects of setup.
  def teardown
    Bcpm::Player.uninstall player_name
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
  def file_ops
    @file_ops.each do |op|
      op_type, target, source = *op
      
      target.sub! /^#{@test_player}./, "#{@player_name}."
      eff_source = source.sub /^#{@test_player}./, "#{@player_name}."

      file_path = java_path(@test_src, eff_source)
      next unless File.exist?(file_path)
      contents = File.read file_path
      
      source_pkg = java_package(source)
      eff_source_pkg = java_package(eff_source)
      target_pkg = java_package(target)
      unless source_pkg == target_pkg
        contents.gsub! /(^|[^A-Za-z0-9_.])#{source_pkg}([^A-Za-z0-9_]|$)/, "\\1#{target_pkg}\\2"
      end
      unless eff_source_pkg == target_pkg
        contents.gsub! /(^|[^A-Za-z0-9_.])#{source_pkg}([^A-Za-z0-9_]|$)/, "\\1#{target_pkg}\\2"
      end

      source_class = java_class(eff_source)
      target_class = java_class(target)
      unless source_class == target_class
        contents.gsub! /(^|[^A-Za-z0-9_])#{source_class}([^A-Za-z0-9_]|$)/, "\\1#{target_class}\\2"
      end
      
      file_path = java_path(@player_src, target)
      next unless File.exist?(File.dirname(file_path))
      File.open(file_path, 'w') { |f| f.write contents }
    end
  end
  
  # Applies the patch operations to the source code in the environment.
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
      File.open(file, 'w') { |f| f.write contents } unless contents == old_contents
    end
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
