# :nodoc: namespace
module Bcpm

# Command-line interface.
module CLI
  # Entry point for commands.
  def self.run(args)
    if args.length < 1
      help
      exit 1
    end
    
    case args.first
    when 'self', 'gem'  # Upgrade bcpm.
      Bcpm::Update.upgrade
    when 'dist'  # Install or upgrade the battlecode distribution.
      Bcpm::Dist.upgrade
    when 'reset'  # Uninstalls the distribution and players, and removes the config file.
      Bcpm::Cleanup.run
      Bcpm::Player.uninstall_all
      Bcpm::Dist.uninstall
      Bcpm::Config.reset
    when 'install'  # Add a player project to the workspace, from a git repository.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      
      if args.length < 2
        puts "Please supply the path to the player repository!"
        exit 1
      end 
      exit 1 unless Bcpm::Player.install(args[1], args[2] || 'master')
    when 'copy', 'copyplayer'  # Create a new player project using an existing project as a template.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end

      if args.length < 3
        puts "Please supply the new player name, and the path to the template player repository!"
        exit 1
      end 
      exit 1 unless Bcpm::Player.checkpoint(args[2], args[3] || 'master', args[1])
    when 'new', 'newplayer'  # Create a new player project from the built-in template.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end

      if args.length < 2
        puts "Please supply the new player name!"
        exit 1
      end
      exit 1 unless Bcpm::Player.create(args[1])
    when 'uninstall', 'remove'  # Remove a player project from the workspace.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end

      if args.length < 2
        puts "Please supply the player name!"
        exit 1
      end 
      Bcpm::Player.uninstall args[1]
    when 'rewire', 'config'  # Re-write a player project's configuration files.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      
      if args.length == 1
        # Try using the current dir as the player name.
        args[1, 0] = [File.basename(Dir.pwd)]
      end

      if args.length < 2
        puts "Please supply the player name!"
        exit 1
      end 
      Bcpm::Player.reconfigure args[1]      
    when 'match', 'livematch'  # Run a match in live or headless mode.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      
      if args.length == 3
        # Try using the current dir as a player name.
        args[1, 0] = [File.basename(Dir.pwd)]
      end
      
      if args.length < 4
        puts "Please supply the player names and the map name!"
        exit 1
      end
      puts Bcpm::Match.run(args[1], args[2], args[3], args[0][0, 4] == 'live')
    when 'replay'  # Replay a match using its binlog (.rms file).
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      
      if args.length == 1
        # Replay the last game.
        replays = Bcpm::Tests::TestMatch.stashed_replays
        args[1, 0] = [replays.max] unless replays.empty?
      end
      
      if args.length < 2
        puts "Please supply the path to the match binlog (.rms file)!"
        exit 1
      end
      Bcpm::Match.replay args[1]
    when 'test'  # Run the entire test suite against a player.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end

      if args.length == 1
        # Try using the current dir as the player name.
        args[1, 0] = [File.basename(Dir.pwd)]
      end

      if args.length < 2
        puts "Please supply the player name!"
        exit 1
      end
      Bcpm::Player.run_suite args[1]
    when 'case', 'testcase', 'livecase', 'live'  # Run a single testcase against a player.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      
      if args.length == 2
        # Try using the current dir as the player name.
        args[1, 0] = [File.basename(Dir.pwd)]
      end

      if args.length < 3
        puts "Please supply the player name and the testcase name!"
        exit 1
      end
      Bcpm::Player.run_case args[2], args[0][0, 4] == 'live', args[1]
    
    when 'clean', 'cleanup'  # Removes all temporaries left behind by crashes.
      Bcpm::Cleanup.run
      
    else
      help
      exit 1
    end
  end
  
  # Prints the CLI help.
  def self.help
    print <<END_HELP
Battlecode (MIT 6.470) package manager.

See the README file for usage instructions.

END_HELP
  end
end  # module Bcpm::CLI
  
end  # namespace Bcpm
