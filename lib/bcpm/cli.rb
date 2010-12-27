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
    when 'install'   
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      if args.length < 2
        puts "Please supply the path to the player repository!"
        exit 1
      end 
      Bcpm::Player.install args[1], args[2]
    when 'new'
      unless Bcpm::Dist.installed?
        puts "Please install a battlecode distribution first!"
        exit 1
      end
      if args.length < 3
        puts "Please supply the new player name, and the path to the template player repository!"
        exit 1
      end 
      Bcpm::Player.checkpoint args[2], 'master', args[1]
    when 'uninstall', 'remove'
      if args.length < 2
        puts "Please supply the player name!"
        exit 1
      end 
      Bcpm::Player.uninstall args[1]
    when 'match'
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
