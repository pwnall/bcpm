require 'rubygems'
require 'echoe'

Echoe.new('bcpm') do |p|
  p.project = 'bcpm'  # rubyforge project
  
  p.author = 'Victor Costan'
  p.email = 'victor@costan.us'
  p.summary = 'Battlecode (MIT 6.370) package manager.'
  p.url = 'http://git.pwnb.us/six370'
  p.dependencies = []
  p.development_dependencies = ['echoe >=3.2']
  
  p.need_tar_gz = !Gem.win_platform?
  p.need_zip = !Gem.win_platform?
  p.rdoc_pattern =
      /^(lib|bin|tasks|ext)|^BUILD|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/  
end

if $0 == __FILE__
  Rake.application = Rake::Application.new
  Rake.application.run
end
