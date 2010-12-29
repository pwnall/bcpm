require 'tmpdir'

# :nodoc: namespace
module Bcpm

# Bcpm updating code.
module Update
  # Updates bcpm to the latest version.
  def self.upgrade(branch = 'master')
    source_path = tempdir
    return false unless Bcpm::Git.clone_repo(repo_uri, 'master', source_path)    
    success = nil
    Dir.chdir source_path do
      success = Kernel.system 'rake', 'install'
    end
    FileUtils.rm_r source_path
    success
  end
    
  # Temporary directory name.
  def self.tempdir
    File.join Dir.tmpdir, "bcpm_#{(Time.now.to_f * 1000).to_i}_#{$PID}"
  end  

  # Git URI to the bcpm repository.
  def self.repo_uri
    Bcpm::Config[:bcpm_repo_uri] ||= default_repo_uri
  end
  
  # Git URI to the bcpm repository.  
  def self.default_repo_uri
    'git@git.pwnb.us:six370/bcpm.git'
  end
end  # module Bcpm::Update

end  # module Bcpm
