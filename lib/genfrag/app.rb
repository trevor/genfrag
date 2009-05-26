if ENV['BIORUBY_HOME']
  $: << File.join(ENV['BIORUBY_HOME'],'lib')
else
  require 'rubygems'
end

require 'fileutils'
require 'optparse'
require 'ostruct'
require 'csv'

require 'bio'
#autoload :SQLite3, 'sqlite3' # => no such file to load -- sqlite3 (LoadError)
require 'sqlite3'

module Genfrag
class App


  # Create a new instance of App, and run the +genfrag+ application given
  # the command line _args_.
  #
  def self.cli_run( args )
    self.new.cli_run args
  end

  # Create a new main instance using _io_ for standard output and _err_ for
  # error messages.
  #
  def initialize( out = STDOUT, err = STDERR )
    @out = out
    @err = err
  end

  # Parse the desired user command and run that command object.
  #
  def cli_run( args )
    cmd_str = args.shift
    cmd = case cmd_str
      when 'index';     IndexCommand.new(@out, @err)
      when 'search';    SearchCommand.new(@out, @err)
      when 'info';      InfoCommand.new(@out, @err)
      when nil, '-h', '--help'
        help
      when '-V', '--version'
        @out.puts "Genfrag #{::Genfrag::VERSION}"
        nil
      else
        @err.puts "Unknown command #{cmd_str.inspect}"
        help
        nil
      end

    cmd.cli_run args if cmd

  rescue StandardError => err
    @err.puts "ERROR:  While executing genfrag ... (#{err.class})"
    @err.puts "    #{err.to_s}"
    @err.puts %Q(    #{err.backtrace.join("\n\t")})
    exit 1
  end

  # Show the toplevel help message.
  #
  def help
    @out.puts <<-MSG

  GenFrag allows for rapid in-silico searching of fragments cut by
  different restriction enzymes in large nucleotide acid databases,
  followed by matching specificity adapters which allow a further data
  reduction when looking for differential expression of genes and
  markers.
    
  Usage:
    genfrag -h/--help
    genfrag -V/--version
    genfrag command [options] [arguments]

  Examples:
    genfrag index -f example.fasta --RE5 BstYI --RE3 MseI
    genfrag search -f example.fasta --RE5 BstYI --RE3 MseI --adapter5 ct

  Commands:
    genfrag index           initialize the index
    genfrag search          search FIXME
    genfrag info            show information about FIXME

  Further Help:
    Each command has a '--help' option that will provide detailed
    information for that command.

    http://genfrag.rubyforge.org/

    MSG
    nil
  end

end  # class App
end  # module Genfrag

Genfrag.require_all_libs_relative_to(__FILE__)

# EOF
