require 'fileutils'

# :nodoc: namespace
module Bcpm

# Battle-code distribution management.
module Dist
  # Hooks a player's code into the installed battlecode distribution.
  def self.add_player(player_path)
    team_path = File.join dist_path, 'teams', File.basename(player_path)
    FileUtils.ln_s player_path, team_path
  end

  # Unhooks a player's code from the installed battlecode distribution.
  def self.remove_player(player_path)
    team_path = File.join dist_path, 'teams', File.basename(player_path)
    unless File.exist?(team_path) && File.symlink?(team_path) &&
           File.readlink(team_path) == player_path   
      return
    end
    File.unlink team_path
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
    
  # Path to the battlecode ant file.
  def self.ant_file
    File.join dist_path, 'build.xml'
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
    if /workspace/ =~ Dir.pwd
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
    'git@git.pwnb.us:six370/battlecode2010.git'
  end
end

end  # namespace Bcpm
