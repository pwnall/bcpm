require 'tmpdir'

# :nodoc: namespace
module Bcpm

# Cleans up all the messes left behind by bcpm crashes.
module Cleanup
  # Cleans up all the messes left behind by bcpm crashes.
  def self.run
    Bcpm::Player.list.each do |player|
      Bcpm::Player.uninstall player if /^bcpmtest/ =~ player
    end
        
    temp_path = File.join(Dir.tmpdir, 'bcpm')
    return unless File.exist?(temp_path)
    Dir.entries(temp_path).each do |entry|
      next if ['.', '..'].include? entry
      path = File.join temp_path, entry
      FileUtils.rm_rf path if File.directory? path
    end
  end
end  # module Bcpm::Cleanup

end  # namespace Bcpm
