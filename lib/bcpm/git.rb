require 'fileutils'

# :nodoc: namespace
module Bcpm

# Git repository operations.
module Git
  # Clones a repository.
  def self.clone_repo(repo_uri, repo_branch, local_path)
    FileUtils.mkdir_p local_path
    Dir.chdir File.dirname(local_path) do
      Kernel.system 'git', 'clone', '--branch', repo_branch, repo_uri, File.basename(local_path)
    end
  end
  
  # Downloads a snapshot of a repository.
  def self.checkpoint_repo(repo_uri, repo_branch, local_path)
    FileUtils.mkdir_p local_path
    Dir.chdir File.dirname(local_path) do
      zip_file = File.basename(local_path) + '.zip'
      Kernel.system 'git', 'archive', '--remote', repo_uri, '--format', 'zip', '--output', zip_file,
                    '-9', repo_branch
      Dir.chdir File.basename(File.basename(local_path)) do
        Kernel.system 'unzip', '-qq', File.join('..', zip_file)
      end
      File.unlink zip_file
    end
  end
  
  # Checks out the working copy of the repository.
  def self.checkpoint_local_repo(repo_path, local_path)
    FileUtils.mkdir_p local_path
    Dir.entries(repo_path).each do |entry|
      next if ['.', '..', '.git'].include? entry
      FileUtils.cp_r File.join(repo_path, entry), local_path
    end
  end
  
  # Pulls the latest changes into the repository.
  def self.update_repo(local_path)
    Dir.chdir local_path do
      Kernel.system 'git', 'pull'
    end
  end
end  # module Bcpm::Git

end  # namespace Bcpm
