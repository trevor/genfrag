# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'genfrag'

#task :default => 'spec:specdoc'
task :default => 'spec:run'

PROJ.name = 'genfrag'
PROJ.authors = 'Pjotr Prins and Trevor Wennblom'
PROJ.email = 'trevor@corevx.com'
PROJ.url = 'http://genfrag.rubyforge.org'
PROJ.version = Genfrag::VERSION
PROJ.release_name = ''
PROJ.ruby_opts = %w[-W0]
PROJ.readme_file = 'README.rdoc'
PROJ.ignore_file = '.gitignore'
PROJ.exclude << 'genfrag.gemspec'
PROJ.exclude << '.git'
PROJ.dependencies = ['bio']

PROJ.rubyforge.name = 'genfrag'

PROJ.spec.opts << '--color'

PROJ.gem.extras[:post_install_message] = <<-MSG
--------------------------------------------
 Genfrag installed
   Type 'genfrag -h' for a list of commands
--------------------------------------------
MSG

task 'ann:prereqs' do
  PROJ.name = 'Genfrag'
end

depend_on 'bio'
depend_on 'rake'


# EOF
