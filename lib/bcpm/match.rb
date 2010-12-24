require 'English'

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
  def self.match_data(player1_name, player2_name, map_name)
    tempdir = tempfile
    Dir.mkdir tempdir
    textlog = nil
    antlog = nil
    Dir.chdir tempdir do
      filebase = Dir.pwd
      binfile = File.join filebase, 'match.rms'
      txtfile = File.join filebase, 'match.txt'
      match_log = File.join filebase, 'match.log'
      scribe_log = File.join filebase, 'scribe.log' 

      bc_config = simulator_config(player1_name, player2_name, map_name, binfile, txtfile)
      conf_file = File.join filebase, 'bc.conf'      
      write_config conf_file, bc_config
      build_file = File.join filebase, 'build.xml'
      write_build build_file, conf_file
      
      run_build_script build_file, conf_file, match_log, 'file'
      run_build_script build_file, conf_file, scribe_log, 'transcribe'
      
      textlog = File.read txtfile
      antlog = File.read match_log
    end
    FileUtils.rm_rf tempdir
    
    { :ant => extract_ant_log(antlog), :script => textlog }
  end
  
  # Options to be overridden for the battlecode simulator.
  def self.simulator_config(player1_name, player2_name, map_name, binfile, txtfile)
    {
      'bc.engine.silence-a' => false,
      'bc.engine.silence-b' => true,
      'bc.dialog.skip' => true,
      'bc.game.maps' => map_name,
      'bc.game.team-a' => player1_name,
      'bc.game.team-b' => player2_name,
      'bc.server.save-file' => binfile,
      'bc.server.transcribe-input' => binfile,
      'bc.server.transcribe-output' => txtfile
    }    
  end
  
  # Writes a patched buildfile that references the given configuration file.
  def self.write_build(buildfile, conffile)
    contents = File.read Bcpm::Dist.ant_file
    # Point to the distribution instead of current root.
    contents.gsub! 'basedir="."', 'basedir="' + Bcpm::Dist.dist_path + '"'
    contents.gsub! '<property name="path.base" location="."',
        '<property name="path.base" location="' + Bcpm::Dist.dist_path + '"'
    # Replace hardcoded bc.conf reference.
    contents.gsub! 'bc.conf', conffile

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
  
  # Runs the battlecode Ant script.
  def self.run_build_script(build_file, conf_file, log_file, target)
    Kernel.system 'ant', '-noinput', '-buildfile', build_file, '-Dbcconf=' + conf_file,
                  '-logfile', log_file, target
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
