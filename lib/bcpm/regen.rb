# :nodoc: namespace
module Bcpm

# Source code auto-generation capabilities.
module Regen
  # Re-generates automatically generated source code files.
  def self.run(file_names)
    source_lines = {}
    vars = {}

    # Read in source blocks.
    file_names.each do |file_name|
      lines = File.open(file_name, 'rb') { |f| f.read.split "\n" }
      
      current_block = nil
      lines.each do |line|
        if current_block
          if /^\s+\/\/\$\s+\-gen\:source(\s.*)?$/ =~ line
            current_block = nil
          else
            source_lines[current_block] << line
          end
        else
          block_match = /^\s+\/\/\$\s+\+gen\:source\s+(\S+)\s+(.*)$/.match line
          if block_match
            current_block = block_match[1]
            if source_lines[current_block]
              print "Duplicate source block #{current_block}\n"
              exit 1
            end
            source_lines[current_block] ||= []
            vars[current_block] = block_match[2].scan /\S+/
          end
        end
      end
      if current_block
        print "Un-closed source block #{current_block}\n"
        exit
      end
    end
    
    # Replace target blocks.
    file_names.each do |file_name|
      lines = File.open(file_name, 'rb') { |f| f.read.split "\n" }
      output_lines = []
      
      current_block = nil
      disabled = false
      lines.each do |line|
        if current_block
          if /^\s+\/\/\$\s+\-gen\:target(\s.*)?$/ =~ line
            output_lines << line
            current_block = nil
          end
        else
          block_match = /^\s+\/\/\$\s+\+gen\:target\s+(\S+)\s+(.*)$/.match line
          output_lines << line
      
          if block_match
            current_block = block_match[1]
            source_vars = vars[current_block]
            if !source_vars
              print "Missing source block #{current_block}\n"
              exit 1
            end
            target_vars = block_match[2].scan /\S+/
            if target_vars.length != source_vars.length
              print "Source/target variable mismatch.\n"
              print "Source: #{vars.join(' ')}\nTarget: #{vars.join(' ')}\n"
              exit 1
            end

            source_target = Hash[source_vars.zip(target_vars)]
            regexp = Regexp.new source_vars.map { |var| "(#{var})" }.join('|')
            new_lines = source_lines[current_block].map &:dup
            disabled = false
            new_lines.each do |line|
              if disabled
                disabled = false if /^\s+\/\/\$\s+\-gen\:off(\s.*)?$/ =~ line
              else
                if /^\s+\/\/\$\s+\+gen\:off(\s.*)?$/ =~ line
                  disabled = true
                else
                  line.gsub!(regexp) { |match| source_target[match] }
                end
              end
            end
            output_lines.concat new_lines
          end
        end
      end      
      if current_block
        print "Un-closed target block #{current_block}\n"
        exit
      end
      
      File.open(file_name, 'wb') { |f| f.write output_lines.join("\n") }
    end
  end
end  # module Bcpm::Regen

end  # namespace Bcpm
