require 'fileutils'

# :nodoc: namespace
module Bcpm

# Battle-code distribution management.
module Dist 
  # Upgrades the installed battlecode distribution to the latest version.
  #
  # Does a fresh install if no distribution is configured.
  def self.upgrade
    return install unless Bcpm::Config[:dist_path]
    
    Dir.chdir dist_path do
      Kernel.system 'git', 'pull', 'origin', 'master'
    end
  end
  
  # Installs the latest battlecode distribution.
  def self.install
    clone_repo
    Bcpm::Config[:dist_repo_uri] = repo_uri
    Bcpm::Config[:dist_path] = dist_path
  end  
  
  # Clones the repository holding the battlecode distribution.
  def self.clone_repo
    FileUtils.mkdir_p dist_path
    Dir.chdir File.dirname(dist_path) do
      Kernel.system 'git', 'clone', repo_uri, File.basename(dist_path)
    end
  end
  
  # Path to the locally installed battlecode distribution.
  def self.dist_path
    return Bcpm::Config[:dist_path] if Bcpm::Config[:dist_path]
    default_dist_path
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
    return Bcpm::Config[:dist_repo_uri] if Bcpm::Config[:dist_repo_uri]
    default_repo_uri
  end
  
  # Git URI to the distribution repository.  
  def self.default_repo_uri
    'git@git.pwnb.us:six370/battlecode2010.git'
  end
end

end  # namespace Bcpm
