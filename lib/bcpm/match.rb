require 'English'
require 'shellwords'

# :nodoc: namespace
module Bcpm

# Runs matches between players.
module Match
  # Runs a match between two players.
  def self.run(player1_name, player2_name, map_name)
    data = match_data player1_name, player2_name, map_name
    data[:ant]
  end
  
  # Runs a match between two players and returns the log data.
  #
  # Args:
  #   player1_name:: name of locally installed player (A)
  #   player2_name:: name of locally installed player (B)
  #   map_name:: name of map .xml file
  #   bc_options:: hash of simulator settings to be added to bc.conf
  def self.match_data(player1_name, player2_name, map_name, bc_options = {})
    tempdir = tempfile
    Dir.mkdir tempdir
    textlog, binlog, antlog = nil, nil, nil
    Dir.chdir tempdir do
      filebase = Dir.pwd
      binfile = File.join filebase, 'match.rms'
      txtfile = File.join filebase, 'match.txt'
      match_log = File.join filebase, 'match.log'
      scribe_log = File.join filebase, 'scribe.log' 

      bc_config = simulator_config(player1_name, player2_name, map_name, binfile, txtfile)
      bc_config.merge! bc_options
      conf_file = File.join filebase, 'bc.conf'      
      write_config conf_file, bc_config
      write_ui_config conf_file, bc_config
      build_file = File.join filebase, 'build.xml'
      write_build build_file, conf_file
      
      run_build_script build_file, conf_file, match_log, 'file'
      run_build_script build_file, conf_file, scribe_log, 'transcribe'
      
      textlog = File.exist?(txtfile) ? File.read(txtfile) : ''
      binlog = File.exist?(binfile) ? File.read(binfile) : ''
      antlog = File.exist?(match_log) ? File.read(match_log) : ''
    end
    FileUtils.rm_rf tempdir
    
    { :ant => extract_ant_log(antlog), :rms => binlog, :script => textlog, :uid => tempdir }
  end
  
  # Replays a match using the binlog (.rms file).
  def self.replay(binfile)
    tempdir = tempfile
    Dir.mkdir tempdir
    Dir.chdir tempdir do
      filebase = Dir.pwd
      match_log = File.join filebase, 'match.log'

      bc_config = simulator_config(nil, nil, nil, binfile, nil)
      conf_file = File.join filebase, 'bc.conf'      
      write_config conf_file, bc_config      
      build_file = File.join filebase, 'build.xml'
      write_build build_file, conf_file
      
      run_build_script build_file, conf_file, match_log, 'run'
    end
    FileUtils.rm_rf tempdir
  end
  
  # Options to be overridden for the battlecode simulator.
  def self.simulator_config(player1_name, player2_name, map_name, binfile, txtfile)
    config = {
      'bc.engine.silence-a' => false,
      'bc.engine.silence-b' => true,
      'bc.dialog.skip' => true,
      'bc.server.throttle' => 'yield',
      'bc.server.throttle-count' => 100000,
      
      # Healthy production defaults.
      'bc.engine.breakpoints' => false,
      'bc.engine.debug-methods' => false,
      'bc.engine.upkeep' => true
    }
    config['bc.game.maps'] = map_name if map_name
    config['bc.game.team-a'] = player1_name if player1_name
    config['bc.game.team-b'] = player2_name if player2_name
    config['bc.server.save-file'] = binfile if binfile
    config['bc.server.transcribe-input'] = binfile if binfile
    config['bc.server.transcribe-output'] = txtfile if txtfile
    config
  end
    
  # Writes a patched buildfile that references the given configuration file.
  def self.write_build(buildfile, conffile)
    contents = Bcpm::Player.ant_config conffile
    File.open(buildfile, 'w') { |f| f.write contents }
  end
  
  # Writes a cleaned up battlecode simulator configuration file.
  def self.write_config(conffile, options = {})
    lines = File.read(Bcpm::Dist.conf_file).split("\n")
    lines = lines.reject do |line|
      key = line.split('=', 2).first
      options.has_key? key
    end
    lines += options.map { |key, value| "#{key}=#{value}" }
    File.open(conffile, 'w') { |f| f.write lines.join("\n") + "\n" }
  end
  
  # Writes the configuration for the battlecode UI.
  #
  # This is a singleton file, so only one client should run at a time.
  def self.write_ui_config(conffile, options = {})
    File.open(File.expand_path('~/.battlecode.ui'), 'w') do |f|
      f.write <<END_CONFIG
choice=FILE
save=false
save-file=
host=
file=#{options['bc.server.save-file']},
analyzeFile=false
glclient=#{options['bc.client.opengl'] || 'false'}
showMinimap=false
MAP=#{options['bc.game.maps']}
maps=#{options['bc.game.maps']}
TEAM_A=#{options['bc.game.team-a']}
TEAM_B=#{options['bc.game.team-b']}
lockstep=false
END_CONFIG
    end
  end
  
  # Runs the battlecode Ant script.
  def self.run_build_script(build_file, conf_file, log_file, target)
    command = Shellwords.shelljoin(['ant', '-noinput', '-buildfile', build_file,
        '-Dbcconf=' + conf_file, '-logfile', log_file, target])
    Kernel.`(command)
  end
  
  # Selects the battlecode simulator log out of an ant log.
  def self.extract_ant_log(contents)
    lines = []
    contents.split("\n").each do |line|
      start = line.index '[java] '
      next unless start
      lines << line[(start + 7)..-1]
    end
    lines.join("\n")
  end
  
  # Temporary file name.
  def self.tempfile
    "match_#{(Time.now.to_f * 1000).to_i}_#{$PID}"
  end
end  # module Bcpm::Match

end  # namespace Bcpm
