require 'fileutils'
require 'shellwords'

# :nodoc: namespace
module Bcpm

# Battle-code distribution management.
module Dist
  # Hooks a player's code into the installed battlecode distribution.
  def self.add_player(player_path)
    team_path = File.join dist_path, 'teams', File.basename(player_path)    
    if /mingw/ =~ RUBY_PLATFORM || (/win/ =~ RUBY_PLATFORM && /darwin/ !~ RUBY_PLATFORM)
      Dir.rmdir team_path if File.exist? team_path
      command = Shellwords.shelljoin(['cmd', '/C', 'mklink', '/D', team_path.gsub('/', '\\'),
                                      player_path.gsub('/', '\\')])
      Kernel.`(command)
    else
      File.unlink team_path if File.exist? team_path
      FileUtils.ln_s player_path, team_path
    end
  end
  
  # Unhooks a player's code from the installed battlecode distribution.
  def self.remove_player(player_path)
    return unless contains_player?(player_path)
    team_path = File.join dist_path, 'teams', File.basename(player_path)
    if /mingw/ =~ RUBY_PLATFORM || (/win/ =~ RUBY_PLATFORM && /darwin/ !~ RUBY_PLATFORM)
      Dir.rmdir team_path
    else
      File.unlink team_path
    end
    bin_path = File.join dist_path, 'bin', File.basename(player_path)
    FileUtils.rm_rf bin_path if File.exist?(bin_path)
  end

  # True if the given path is a player that is hooked into the distribution.
  def self.contains_player?(player_path)
    team_path = File.join dist_path, 'teams', File.basename(player_path)
    if /mingw/ =~ RUBY_PLATFORM || (/win/ =~ RUBY_PLATFORM && /darwin/ !~ RUBY_PLATFORM)
      File.exist? team_path
    else
      File.exist?(team_path) && File.symlink?(team_path) && File.readlink(team_path) == player_path
    end
  end
  
  # Upgrades the installed battlecode distribution to the latest version.
  #
  # Does a fresh install if no distribution is configured.
  def self.upgrade
    return install unless installed?
    Bcpm::Git.update_repo dist_path
  end
  
  # Installs the latest battlecode distribution.
  def self.install
    Bcpm::Git.clone_repo repo_uri, 'master', dist_path
    Bcpm::Config[:dist_repo_uri] = repo_uri
    Bcpm::Config[:dist_path] = dist_path
  end  

  # True if a battlecode distribution is installed on the local machine.
  def self.installed?
    Bcpm::Config.config.has_key? :dist_path
  end
  
  # Removes the battlecode distribution installed on the location machine.
  def self.uninstall
    return unless installed?
    FileUtils.rm_rf dist_path
    Bcpm::Config[:dist_path] = nil
  end
  
  # Path to the battlecode ant file.
  def self.ant_file
    File.join dist_path, 'build.xml'
  end
  
  # Path to the battlecode maps directory.
  def self.maps_path
    File.join dist_path, 'maps'
  end
  
  # Path to the battlecode simulator configuration file.
  def self.conf_file
    File.join dist_path, 'bc.conf'
  end
    
  # Path to the locally installed battlecode distribution.
  def self.dist_path
    Bcpm::Config[:dist_path] || default_dist_path
  end

  # Path to the locally installed battlecode distribution.
  def self.default_dist_path
    if File.exist?('.metadata') && File.directory?('.metadata')
      File.expand_path './battlecode'
    else
      File.expand_path '~/battlecode'
    end
  end

  # Git URI to the distribution repository.
  def self.repo_uri
    Bcpm::Config[:dist_repo_uri] || default_repo_uri
  end
  
  # Git URI to the distribution repository.  
  def self.default_repo_uri
    'git@git.pwnb.us:six370/battlecode2011.git'
  end

  # Maps installed in the battlecode distribution.
  def self.maps
    Dir.glob(File.join(maps_path, '*.xml')).map do |f|
      File.basename(f).sub(/\.xml$/, '')
    end
  end

  # Copies a battlecode distribution map.
  def self.copy_map(map_name, destination)
    map_file = File.join maps_path, map_name + '.xml'
    unless File.exist?(map_file)
      puts "No map found at#{map_file}"
      return
    end
    if File.exist?(destination) && File.directory?(destination)
      destionation = File.join destination, map_name + '.xml'
    end
    FileUtils.cp map_file, destination
  end
end

end  # namespace Bcpm
