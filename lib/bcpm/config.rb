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
    config[key.to_sym] = new_value
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
end  # module Bcpm::Config

end  # namespace Bcpm
