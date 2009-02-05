
module Genfrag

  # :stopdoc:
  VERSION = '0.0.0.1'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Utility method used to require all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
        ::File.join(::File.dirname(fname), dir, '**', '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end

  def self.tracktime verbose=true, f=nil
  # Info:: Pjotr's shared Ruby modules
  # Author:: Pjotr Prins
  # mail:: pjotr.public05@thebird.nl
  # Copyright:: July 2007
  # License:: Ruby License
    begin
      t1 = Time.now
      yield

      ensure

        t2 = Time.now
        dt = t2 - t1
        if verbose
          if f == nil
            f = $stdout
          end
          f.print "\nElapsed time "
          hours = dt.to_i/3600
          dt -= hours*3600
          mins  = dt.to_i/60
          dt -= mins*60
          secs  = dt
          secs = secs.to_i if secs > 25
          if hours > 0
            f.print hours.to_i," hours "
          end
          if mins > 0
            f.print mins.to_i," minutes "
          end
          f.print secs," seconds\n" 
        end
    end
  end
  
end  # module Genfrag

Genfrag.require_all_libs_relative_to(__FILE__)

# EOF
