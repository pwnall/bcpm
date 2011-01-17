require 'English'
require 'fileutils'
require 'shellwords'
require 'socket'
require 'thread'
require 'tmpdir'

# :nodoc: namespace
module Bcpm

# Runs matches between players.
module Match
  # Runs a match between two players.
  def self.run(player1_name, player2_name, map_name, mode)
    env = Bcpm::Tests::Environment.new player1_name
    options = {}
    if mode == :debug
      Bcpm::Config[:breakpoints] ||= true
      Bcpm::Config[:debugcode] ||= true
      Bcpm::Config[:noupkeep] ||= false
      Bcpm::Config[:debuglimit] ||= 1_000_000
      options = Hash[engine_options.map { |k, v| [v, Bcpm::Config[k]] }]
    end
    match = Bcpm::Tests::TestMatch.new :a, player2_name, map_name, env, options
    match.run(mode != :file)
    match.stash_data
  end
  
  # Key-value pairs for friendly => canonical names of battlecode engine options.
  def self.engine_options
    {
      'breakpoints' => 'bc.engine.breakpoints',
      'debugcode' => 'bc.engine.debug-methods',
      'noupkeep' => 'bc.engine.upkeep',
      'debuglimit' => 'bc.engine.debug-max-bytecodes'
    }
  end
  
  # Runs a match between two players and returns the log data.
  #
  # Args:
  #   player1_name:: name of locally installed player (A)
  #   player2_name:: name of locally installed player (B)
  #   silence_b:: if true, B is silenced; otherwise, A is silenced
  #   map_name:: name of map .xml file (or full path for custom map)
  #   run_live:: if true, tries to run the match using the live UI
  #   bc_options:: hash of simulator settings to be added to bc.conf
  def self.match_data(player1_name, player2_name, silence_b, map_name, run_live, bc_options = {})
    uid = tempfile
    tempdir = File.join Dir.tmpdir, 'bcpm', 'match_' + uid
    FileUtils.mkdir_p tempdir
    textlog, binlog, antlog = nil, nil, nil, nil, nil
    Dir.chdir tempdir do
      filebase = Dir.pwd
      binfile = File.join filebase, 'match.rms'
      txtfile = File.join filebase, 'match.txt'
      build_log = File.join filebase, 'build.log'
      match_log = File.join filebase, 'match.log'
      scribe_log = File.join filebase, 'scribe.log' 

      bc_config = simulator_config player1_name, player2_name, silence_b, map_name, binfile, txtfile
      bc_config.merge! bc_options
      conf_file = File.join filebase, 'bc.conf'      
      write_config conf_file, bc_config
      write_ui_config conf_file, true, bc_config if run_live
      build_file = File.join filebase, 'build.xml'
      write_build build_file, conf_file
      
      if run_live
        match_output = run_build_script build_file, match_log, 'run', 'Stop buffering match'
      else
        match_output = run_build_script build_file, match_log, 'file'
      end        
      scribe_output = run_build_script build_file, scribe_log, 'transcribe'
      
      textlog = File.exist?(txtfile) ? File.open(txtfile, 'rb') { |f| f.read } : ''
      binlog = File.exist?(binfile) ? File.open(binfile, 'rb') { |f| f.read } : ''
      antlog = File.exist?(match_log) ? File.open(match_log, 'rb') { |f| f.read } : match_output
    end
    FileUtils.rm_rf tempdir
    
    { :ant => extract_ant_log(antlog), :rms => binlog, :script => textlog, :uid => uid }
  end
  
  # Replays a match using the binlog (.rms file).
  def self.replay(binfile)
    tempdir = File.join Dir.tmpdir, 'bcpm', 'match_' + tempfile
    FileUtils.mkdir_p tempdir
    Dir.chdir tempdir do
      filebase = Dir.pwd
      match_log = File.join filebase, 'match.log'

      bc_config = simulator_config nil, nil, true, nil, binfile, nil
      conf_file = File.join filebase, 'bc.conf'      
      write_config conf_file, bc_config
      write_ui_config conf_file, false, bc_config
      build_file = File.join filebase, 'build.xml'
      write_build build_file, conf_file
      
      run_build_script build_file, match_log, 'run'
    end
    FileUtils.rm_rf tempdir
  end
  
  # Options to be overridden for the battlecode simulator.
  def self.simulator_config(player1_name, player2_name, silence_b, map_name, binfile, txtfile)
    config = {
      'bc.engine.silence-a' => !silence_b,
      'bc.engine.silence-b' => !!silence_b,
      'bc.dialog.skip' => true,
      'bc.server.throttle' => 'yield',
      'bc.server.throttle-count' => 100000,
      'bc.client.opengl' => Bcpm::Config[:client3d],
      
      # Healthy production defaults.
      'bc.engine.breakpoints' => false,
      'bc.engine.debug-methods' => false,
      'bc.engine.upkeep' => true
    }
    map_path = nil
    if map_name
      if File.basename(map_name) != map_name
        map_path = File.dirname map_name
        map_name = File.basename(map_name).sub(/\.xml$/, '')
      end
    end
    config['bc.game.maps'] = map_name if map_name
    config['bc.game.map-path'] = map_path if map_path
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
    File.open(buildfile, 'wb') { |f| f.write contents }
  end
  
  # Writes a cleaned up battlecode simulator configuration file.
  def self.write_config(conffile, options = {})
    lines = File.read(Bcpm::Dist.conf_file).split("\n")
    lines = lines.reject do |line|
      key = line.split('=', 2).first
      options.has_key? key
    end
    lines += options.map { |key, value| "#{key}=#{value}" }
    File.open(conffile, 'wb') { |f| f.write lines.join("\n") + "\n" }
  end
  
  # Writes the configuration for the battlecode UI.
  #
  # This is a singleton file, so only one client should run at a time.
  def self.write_ui_config(conffile, run_live, options = {})
    save_path = options['bc.server.save-file'] || ''
    if /mingw/ =~ RUBY_PLATFORM || (/win/ =~ RUBY_PLATFORM && /darwin/ !~ RUBY_PLATFORM)
      save_path = save_path.dup
      save_path.gsub! '\\', '\\\\\\\\'
      save_path.gsub! '/', '\\\\\\\\'
      if save_path[1, 2] == ':\\'
        save_path[1, 2] = '\\:\\'
      end
    end
    
    choice = run_live ? 'LOCAL' : 'FILE'
    File.open(File.expand_path('~/.battlecode.ui'), 'wb') do |f|
      f.write <<END_CONFIG
choice=#{choice}
save=#{run_live}
save-file=#{save_path}
file=#{save_path}
host=
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
  #
  # Return the ant stdout (messages not written to the ant log).
  def self.run_build_script(build_file, log_file, target, run_live = false)
    if run_live
      command = Shellwords.shelljoin(['ant', '-noinput', '-buildfile', build_file, target])      

      # Start the build as a subprocess, dump its output to the queue as string fragments.
      # nil means the subprocess completed.
      queue = Queue.new
      thread = Thread.start do
        IO.popen command do |f|
          begin
            loop { queue << f.readpartial(1024) }
          rescue EOFError
            queue << nil
          end
        end
      end

      build_output = ''
      while fragment = queue.pop
        # Dump the build output to the screen as the simulation happens.
        print fragment
        STDOUT.flush
        build_output << fragment
      
        # Let bcpm carry on when the simulation completes.
        break if build_output.index(run_live)
      end
      build_output << "\n" if build_output[-1] != ?\n
      
      # Pretend everything was put in a log file.
      File.open(log_file, 'wb') { |f| f.write build_output }
      return thread
    else
      command = Shellwords.shelljoin(['ant', '-noinput', '-buildfile', build_file,
                                      '-logfile', log_file, target])
      Kernel.`(command)    
    end
  end
  
  # Selects the battlecode simulator log out of an ant log.
  def self.extract_ant_log(contents)
    lines = []
    contents.split("\n").each do |line|
      start = line.index '[java] '
      next unless start
      lines << line[(start + 7)..-1]
      break if line.index('- Match Finished -')
    end
    lines.join("\n")
  end
  
  # Temporary file name.
  def self.tempfile
    "#{Socket.hostname}_#{(Time.now.to_f * 1000).to_i}_#{$PID}"
  end
end  # module Bcpm::Match

end  # namespace Bcpm
