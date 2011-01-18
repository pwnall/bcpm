require 'fileutils'
require 'socket'

# :nodoc: namespace
module Bcpm

# Git repository operations.
module Git
  # Clones a repository.
  #
  # Returns true for success, false if something went wrong.
  def self.clone_repo(repo_uri, repo_branch, local_path)
    FileUtils.mkdir_p File.dirname(local_path)
    success = nil
    Dir.chdir File.dirname(local_path) do
      FileUtils.rm_rf File.basename(local_path) if File.exists?(local_path)
      if repo_branch == 'master'
        success = Kernel.system 'git', 'clone', repo_uri,
                                File.basename(local_path)
      else
        success = Kernel.system 'git', 'clone', '--branch', repo_branch,
                                repo_uri, File.basename(local_path)
        unless success
          success = Kernel.system 'git', 'clone', repo_uri,
                                  File.basename(local_path)
          if success
            success = Kernel.system 'git', 'checkout', repo_branch
          end
        end
      end
    end
    FileUtils.rm_rf local_path unless success
    success
  end
  
  # Downloads a snapshot of a repository.
  #
  # Returns true for success, false if something went wrong.
  def self.checkpoint_repo(repo_uri, repo_branch, local_path)
    FileUtils.mkdir_p local_path
    success = nil
    Dir.chdir File.dirname(local_path) do
      zip_file = File.basename(local_path) + '.zip'
      success = Kernel.system('git', 'archive', '--format=zip',
          '--remote', repo_uri, '--output', zip_file, '-9', repo_branch)
      if success
        Dir.chdir File.basename(File.basename(local_path)) do
          success = Kernel.system 'unzip', '-qq', File.join('..', zip_file)
        end
      end
      File.unlink zip_file if File.exist?(zip_file)
    end
    unless success
      puts "Trying workaround for old git"
      success = clone_repo repo_uri, repo_branch, local_path
      FileUtils.rm_rf File.join(local_path, '.git') if success
    end
    
    FileUtils.rm_rf local_path unless success
    success
  end
  
  # Checks out the working copy of the repository.
  #
  # Returns true for success, false if something went wrong.
  def self.checkpoint_local_repo(repo_path, local_path)
    return false unless File.exist?(repo_path)
    FileUtils.mkdir_p local_path
    Dir.entries(repo_path).each do |entry|
      next if ['.', '..', '.git'].include? entry
      FileUtils.cp_r File.join(repo_path, entry), local_path
    end
    true
  end
  
  # Pulls the latest changes into the repository.
  def self.update_repo(local_path)
    Dir.chdir local_path do
      Kernel.system 'git', 'pull'
    end
  end

  # Temporary directory name.
  def self.tempdir
    File.join Dir.tmpdir, 'bcpm',
        "update_#{Socket.hostname}_#{(Time.now.to_f * 1000).to_i}_#{$PID}"
  end
end  # module Bcpm::Git

end  # namespace Bcpm
