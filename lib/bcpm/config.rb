require 'yaml'

# :nodoc: namespace
module Bcpm

# Persistent, per-user bcpm configuration information.
module Config
  # Hash-style access to the configuration dictionary.
  def self.[](key)
    config[key.to_sym]
  end
  
  # Hash-style access to configuration dictionary.
  def self.[]=(key, new_value)
    if new_value.nil?
      config.delete key.to_sym
    else
      config[key.to_sym] = new_value      
    end
    write_config
  end
  
  # The configuration dictionary.
  def self.config
    @config ||= read_config
  end
  
  # Reads the YAML configuration file.
  def self.read_config
    if File.exists? config_file
      @config = File.open(config_file) { |f| YAML.load f }
    else
      @config = {}
    end
  end
  
  # Writes the configuration to the YAML file.
  def self.write_config
    File.open(config_file, 'wb') { |f| YAML.dump config, f }
  end

  # Path to the configuration YAML file.
  def self.config_file
    File.expand_path '~/.bcpm_config'
  end
  
  # Removes the configuration YAML file and resets the configuration hash.
  def self.reset
    File.unlink config_file if File.exist?(config_file)
    @config = nil
  end
  
  # Outputs the configuration.
  def self.print_config
    config.keys.sort.each do |key|
      print "#{key}: #{config[key]}\n"
    end
  end
  
  # Executes a config command from the UI.
  def self.ui_set(key, value)    
    # Normalize values.
    case value && value.downcase
    when 'on', 'true'
      value = true
    when 'off', 'false'
      value = false
    end
    
    # Process keys that include values.
    prefix = key[0]
    
    toggle = false
    if [?+, ?-, ?^].include? prefix
      key = key[1..-1]
      case prefix
      when ?+
        value = true
      when ?-
        value = false
      when ?^
        toggle = true
      end
      self[key]
    end
    
    # Normalize keys.
    key = key.downcase
    
    # Execute the configuration change.
    if toggle
      self[key] = !self[key]
    else
      self[key] = value
    end
    print "#{key} set to #{value}\n"
  end
end  # module Bcpm::Config

end  # namespace Bcpm
