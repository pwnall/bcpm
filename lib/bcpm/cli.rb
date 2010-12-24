# :nodoc: namespace
module Bcpm

# Command-line interface.
module CLI
  # Entry point for commands.
  def self.run(args)
    if args.length < 1
      help
      return
    end
    
    case args.first
    when 'dist'  # Install or upgrade the battlecode distribution.
      Bcpm::Dist.upgrade
    when 'install'   
      unless Bcpm::Dist.installed?
        puts "Install a battlecode distribution first."
        return
      end      
      Bcpm::Player.install args[1], args[2]
    else
      help
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
