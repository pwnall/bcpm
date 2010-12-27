require 'English'

# :nodoc: namespace
module Bcpm

# Automated testing code.
module Tests
  # Upgrades the installed test suite to the latest version.
  #
  # Does a fresh install if no test suite is configured.
  def self.upgrade
    return install unless installed?
    Bcpm::Git.update_repo suite_path
    configure suite_path
  end
  
  # Installs the latest test suite.
  def self.install
    Bcpm::Git.clone_repo repo_uri, 'master', suite_path

    unless configure(suite_path) && File.exist?(File.join(suite_path, 'suite'))
      puts "Repository does not contain a test suite!"
      exit 1
    end    
    Bcpm::Config[:tests_repo_uri] = repo_uri
    Bcpm::Config[:tests_path] = suite_path
  end
  
  # Runs the test suite against a player codebase.
  def self.run(player_name_or_uri, branch = 'master')
    suite = new_suite
    env_base = "test_#{(Time.now.to_f * 1000).to_i}_#{$PID}_"
    
    env_names = (1..(suite.tests.count)).map { |i| env_base + i.to_s }
    env_names.each_with_index do |env_name, i|
      Bcpm::Player.checkpoint player_name_or_uri, branch, env_name
      # TODO(pwnall): patch environment according to testcase
    end
    
    suite.run env_names    

    env_names.each_with_index do |env_name, i|
      Bcpm::Player.uninstall env_name
    end
  end
  
  # Creates a Suite instance for running all the tests.
  def self.new_suite
    files = Dir.glob File.join(suite_path, 'suite', '**', '*.rb')
    Bcpm::Tests::Suite.new files
  end

  # True if a battlecode distribution is installed on the local machine.
  def self.installed?
    Bcpm::Config.config.has_key? :tests_path
  end
  
  # The directory containing the test suite.
  def self.suite_path
    Bcpm::Config[:tests_path] ||= default_suite_path
  end

  # The directory containing the test suite.
  def self.default_suite_path
    path = Dir.pwd
    unless File.exist?(File.join(path, '.metadata'))
      puts "Please chdir into your Eclipse workspace!"
      exit 1
    end
    File.join path, 'tests'
  end

  # Git URI to the test suite.
  def self.repo_uri
    Bcpm::Config[:tests_repo_uri] || default_repo_uri
  end
  
  # Git URI to the test suite.
  def self.default_repo_uri
    'git@git.pwnb.us:six370/tests.git'
  end
  
  # The name of the player package that the tests are written against.
  def self.target_player
    Bcpm::Config[:test_target_player] || 'team000'
  end
  
  # Configuration from bcpm.yml.
  def self.configuration(local_path)
    config_file = File.join local_path, 'bcpm.yml'
    unless File.exist?(config_file)
      puts "Suite doesn't have bcpm.yml in root"
      return nil
    end
    config = nil
    begin
      config = File.open(config_file, 'r') { |f| YAML.load f }
    rescue
      puts "Could not read suite configuration from bcpm.yml"
      return nil
    end
    config    
  end
  
  # Configures a test suite project.
  def self.configure(local_path)
    return nil unless config = configuration(local_path)
    Bcpm::Config[:test_target_player] = config[:target_player]
    
    File.open File.join(local_path, '.project'), 'w' do |f|
      f.write eclipse_project(local_path)
    end
    
    File.open File.join(local_path, '.classpath'), 'w' do |f|
      f.write eclipse_classpath(local_path)
    end
    config
  end  
  
  # The contents of an Eclipse .classpath for a test suite.
  def self.eclipse_classpath(local_path)
    <<END_CONFIG
<?xml version="1.0" encoding="UTF-8"?>
<classpath>
  <classpathentry kind="src" path="src"/>
  <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
  <classpathentry combineaccessrules="false" kind="src" path="/#{target_player}"/>
  <classpathentry kind="output" path="bin"/>
</classpath>
END_CONFIG
  end
  
  # The contents of an Eclipse .project file for a test suite.
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

end  # module Bcpm::Tests

end  # namespace Bcpm
