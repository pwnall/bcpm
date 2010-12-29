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
    when 'dist'  # Install or upgrade the battlecode distribution.
      Bcpm::Dist.upgrade
    when 'suite'  # Install or upgrade the test suite.
      Bcpm::Tests.upgrade
    when 'gem', 'self'  # Upgrade bcpm.
      Bcpm::Update.upgrade
    when 'install'  # Add a player project to the workspace, from a git repository.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      if args.length < 2
        puts "Please supply the path to the player repository!"
        exit 1
      end 
      exit 1 unless Bcpm::Player.install(args[1], args[2])
    when 'new'  # Create a new player project using an existing project as a template.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      if args.length < 3
        puts "Please supply the new player name, and the path to the template player repository!"
        exit 1
      end 
      exit 1 unless Bcpm::Player.checkpoint(args[2], 'master', args[1])
    when 'uninstall', 'remove'  # Remove a player project from the workspace.
      if args.length < 2
        puts "Please supply the player name!"
        exit 1
      end 
      Bcpm::Player.uninstall args[1]
    when 'rewire', 'config'  # Re-write a player project's configuration files.
      if args.length < 2
        puts "Please supply the player name!"
        exit 1
      end 
      Bcpm::Player.reconfigure args[1]      
    when 'match'  # Run a match in headless mode, dump the output to stdout.
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      if args.length < 4
        puts "Please supply the player names and the map name!"
        exit 1
      end
      output = Bcpm::Match.run args[1], args[2], args[3]
      puts output
    when 'replay'  # Replay a match using its binlog (.rms file).
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      if args.length < 2
        puts "Please supply the path to the match binlog (.rms file)!"
        exit 1
      end
      Bcpm::Match.replay args[1]
    when 'test'
      unless Bcpm::Tests.installed?
        puts "Please install a test suite first!"
        exit 1
      end
      if args.length < 2
        puts "Please supply the player name or repository!"
        exit 1
      end
      Bcpm::Tests.run args[1]
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
end
  
end  # namespace Bcpm
