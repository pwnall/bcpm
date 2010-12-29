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
      return nil
    end    
    Bcpm::Config[:tests_repo_uri] = repo_uri
    Bcpm::Config[:tests_path] = suite_path
  end
  
  # Runs the test suite against a player codebase.
  def self.run(player_name_or_uri, branch = 'master')
    run_suite new_suite, player_name_or_uri, branch
  end
  
  # Runs a case in the test suite against a player codebase. 
  def self.run_case(case_name, player_name_or_uri, branch = 'master')
    case_file = case_name + '.rb'
    files = suite_files.select { |file| File.basename(file) == case_file }
    unless files.length == 1
      puts "Ambiguous case name! It matched #{files.count} cases.\n#{files.join("\n")}\n"
      return false
    end
    suite = Bcpm::Tests::Suite.new
    suite.add_cases files
    run_suite suite, player_name_or_uri, branch
  end
  
  # Runs a test suite against a player codebase.
  def self.run_suite(suite, player_name_or_uri, branch)
    suite.environments.each { |e| e.setup player_name_or_uri, branch }
    suite.run
    suite.environments.each { |e| e.teardown }
    suite    
  end
  
  # Creates a Suite instance for running all the tests.
  def self.new_suite
    suite = Bcpm::Tests::Suite.new
    suite.add_cases suite_files
    suite
  end
  
  # All the test cases in a suite.
  def self.suite_files
    Dir.glob File.join(suite_path, 'suite', '**', '*.rb')
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
    
    File.open File.join(local_path, '.project'), 'wb' do |f|
      f.write eclipse_project(local_path)
    end
    
    File.open File.join(local_path, '.classpath'), 'wb' do |f|
      f.write eclipse_classpath(local_path)
    end
    config
  end
  
  # Extracts the path to a suite's source package given its repository.
  #
  # Args:
  #   suite_path:: (optional) path to the suite's git repository on the local machine
  def self.package_path(suite_path = nil)
    suite_path ||= self.suite_path
    
    # All the packages should be in the 'src' directory.
    source_dir = File.join suite_path, 'src'
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

    package_dirs.first
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
