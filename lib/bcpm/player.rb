require 'fileutils'

# :nodoc: namespace
module Bcpm

# Manages player packages.
module Player
  # Clones a player code from a repository, and sets it up for development on the local machine.
  #
  # Returns the player's name.
  def self.install(repo_uri, repo_branch)
    repo_branch ||= 'master'

    name = player_name repo_uri
    local_path = File.join local_root, name    
    if File.exist?(local_path)
      puts "Player already installed at #{local_path}!"
      exit 1
    end    
    Bcpm::Git.clone_repo repo_uri, repo_branch, local_path
    
    unless source_path = package_path(local_path)
      puts "Repository doesn't seem to contain a player!"
      FileUtils.rm_rf local_path      
      exit 1
    end
        
    Bcpm::Dist.add_player source_path
    configure local_path
    name
  end
  
  # Downloads player code from a repository for one-time use, without linking it to the repository.
  #
  # Returns the path to the player on the local system.
  def self.checkpoint(repo_uri, repo_branch, local_name)
    old_name = player_name repo_uri
    local_path = File.join local_root, local_name
    if File.exist?(local_path)
      puts "Player already installed at #{local_path}!"
      exit 1
    end
    if old_name == repo_uri
      Bcpm::Git.checkpoint_local_repo File.join(local_root, old_name), local_path
    else
      Bcpm::Git.checkpoint_repo repo_uri, repo_branch, local_path
    end
    unless source_path = rename(local_path, old_name)
      puts "Repository doesn't seem to contain a player!"
      FileUtils.rm_rf local_path      
      exit 1
    end

    Bcpm::Dist.add_player source_path
    configure local_path
    local_path
  end

  # Undoes the effects of an install or checkpoint call.
  def self.uninstall(local_name)
    local_path = File.join local_root, local_name
    source_path = package_path local_path
    Bcpm::Dist.remove_player source_path
    FileUtils.rm_rf local_path
  end
  
  # Re-configures a player's source code project.
  def self.reconfigure(local_name)
    local_path = File.join local_root, local_name
    configure local_path
  end

  # Configures a player's source code project.
  def self.configure(local_path)
    File.open File.join(local_path, '.project'), 'w' do |f|
      f.write eclipse_project(local_path)
    end
    
    File.open File.join(local_path, '.classpath'), 'w' do |f|
      f.write eclipse_classpath(local_path)
    end
    
    File.open File.join(local_path, 'build.xml'), 'w' do |f|
      f.write ant_config('bc.conf')
    end
  end
  
  # The directory containing all players code.
  def self.local_root
    Bcpm::Config[:player_root] ||= default_local_root    
  end
  
  # The directory containing all players code.
  def self.default_local_root
    path = Dir.pwd
    unless File.exist?(File.join(path, '.metadata'))
      puts "Please chdir into your Eclipse workspace!"
      exit 1
    end
    path
  end
  
  # Extracts the player name out of the git repository URI for the player's code.
  def self.player_name(repo_uri)
    name = File.basename(repo_uri)
    name = name[0...-4] if name[-4, 4] == '.git'
    name
  end
  
  # Renames a player to match its path on the local system.
  #
  # Returns the path to the player's source package.
  def self.rename(local_path, old_name)
    new_name = File.basename local_path    
    return nil unless old_source_dir = package_path(local_path, old_name)
    new_source_dir = File.join File.dirname(old_source_dir), new_name
    FileUtils.mv old_source_dir, new_source_dir
    
    Dir.glob(File.join(new_source_dir, '**', '*.java')).each do |file|
      contents = File.read file
      contents.gsub! /(^|[^A-Za-z0-9_.])#{old_name}([^A-Za-z0-9_]|$)/, "\\1#{new_name}\\2"
      File.open(file, 'w') { |f| f.write contents }
    end
    new_source_dir
  end
  
  # Extracts the path to a player's source package given their repository.
  #
  # Args:
  #   local_path:: path to the player's git repository on the local machine
  #   name_override:: (optional) supplies the player name; if not set, the name is extracted from
  #                   the path, by convention 
  def self.package_path(local_path, name_override = nil)
    # All the packages should be in the 'src' directory.
    source_dir = File.join local_path, 'src'
    unless File.exist? source_dir
      puts "Missing src directory"
      return nil
    end
    
    # Ignore maintainance files/folder such as .gitignore / .svn.
    package_dirs = Dir.glob(File.join(source_dir, '*')).
                       reject { |path| File.basename(path)[0, 1] == '.' }
    unless package_dirs.length == 1
      puts "src directory doesn't contain exactly one package directory!"
      return nil
    end

    path = package_dirs.first
    unless (name_override || File.basename(local_path)) == File.basename(path)
      puts "The package in the src directory doesn't match the player name!"
      return nil
    end
    path
  end
  
  # The contents of an Ant configuration file (build.xml) pointing to a simulator config file.
  def self.ant_config(simulator_config)
    contents = File.read Bcpm::Dist.ant_file
    # Point to the distribution instead of current root.
    contents.gsub! 'basedir="."', 'basedir="' + Bcpm::Dist.dist_path + '"'
    contents.gsub! '<property name="path.base" location="."',
        '<property name="path.base" location="' + Bcpm::Dist.dist_path + '"'
    # Replace hardcoded bc.conf reference.
    contents.gsub! 'bc.conf', simulator_config
    contents
  end

  # The contents of an Eclipse .classpath for a player project.  
  def self.eclipse_classpath(local_path)
    jar_path = File.join Bcpm::Dist.dist_path, 'lib', 'battlecode.jar'
    
    <<END_CONFIG
<?xml version="1.0" encoding="UTF-8"?>
<classpath>
  <classpathentry kind="src" path="src"/>
  <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
  <classpathentry exported="true" kind="lib" path="#{jar_path}"/>
  <classpathentry kind="output" path="bin"/>
</classpath>
END_CONFIG
  end
  
  # The contents of an Eclipse .project file for a player project.
  def self.eclipse_project(local_path)
    project_name = File.basename local_path
    
    <<END_CONFIG
<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
  <name>#{project_name}</name>
  <comment></comment>
  <projects>
  </projects>
  <buildSpec>
    <buildCommand>
      <name>org.eclipse.jdt.core.javabuilder</name>
      <arguments>
      </arguments>
    </buildCommand>
  </buildSpec>
  <natures>
    <nature>org.eclipse.jdt.core.javanature</nature>
  </natures>
</projectDescription>
END_CONFIG
  end
end  # module Bcpm::Player

end  # namespace Bcpm
