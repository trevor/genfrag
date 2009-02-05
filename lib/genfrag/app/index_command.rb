
module Genfrag
class App

class IndexCommand < Command

  attr_reader :sizes

  def cli_run( args )
    parse args

    @input_filenames = ARGV

    validate_options(options)

    go = begin
      run(options, @input_filenames, true)
    end
    
    options[:tracktime] ? TimeTracker.tracktime {go} : go

  end

  def opt_parser
    std_opts = standard_options

    opts = OptionParser.new
    opts.banner = 'Usage: genfrag index [options]'

    opts.separator ''
    opts.separator "  Create a database of sequence fragments that match the last 5' fragment"
    opts.separator "  cut by two restricting enzymes RE3 and RE5. FIXME"

    opts.separator ''
    opts.on(*std_opts[:verbose])
    opts.on(*std_opts[:quiet])
    opts.on(*std_opts[:tracktime])
    opts.on(*std_opts[:re5])
    opts.on(*std_opts[:re3])
    opts.on(*std_opts[:sqlite])
    opts.on(*std_opts[:filelookup])
    opts.on(*std_opts[:filefasta])

    opts.separator ''
    opts.separator '  Common Options:'
    opts.on( '-h', '--help', 'show this message' ) { @out.puts opts; exit 1 }
    opts.separator '  Examples:'
    opts.separator '    genfrag index -f example.fasta --re5 BstYI --re3 MseI'
    opts
  end
  
  def parse( args )
    opts = opt_parser
    
    if args.empty?
      @out.puts opts
      exit 1
    end

  # parse the command line arguments
    opts.parse! args
    

=begin    

    if options[:filefasta] == nil
      @out.puts "must supply fasta filename"
      @out.puts opts
      exit 1
    end

    if options[:re5] == nil
      @out.puts "re5 not supplied"
      @out.puts opts
      exit 1
    end
    
    if options[:re3] == nil
      @out.puts "re3 not supplied"
      @out.puts opts
      exit 1
    end
    
    begin
      Bio::RestrictionEnzyme::DoubleStranded.new(options[:re3])
    rescue
      @out.puts "re3 is not an enzyme name"
      @out.puts opts
      exit 1
    end
    
    begin
      Bio::RestrictionEnzyme::DoubleStranded.new(options[:re5])
    rescue
      @out.puts "re5 is not an enzyme name"
      @out.puts opts
      exit 1
    end
=end

  end

  def validate_options(o)
    if o[:filefasta] == nil
      @out.puts
      @err.puts "missing option: must supply fasta filename"
      @out.puts
      @out.puts opt_parser
      exit 1
    end
    
    if o[:re5] == nil
      @out.puts
      @err.puts "missing option: re5"
      @out.puts
      @out.puts opt_parser
      exit 1
    end
    
    if o[:re3] == nil
      @out.puts
      @err.puts "missing option: re3"
      @out.puts
      @out.puts opt_parser
      exit 1
    end
    
    begin
      Bio::RestrictionEnzyme::DoubleStranded.new(o[:re3])
    rescue
      @err.puts "re3 is not an enzyme name"
      @out.puts opt_parser
      exit 1
    end
    
    begin
      Bio::RestrictionEnzyme::DoubleStranded.new(o[:re5])
    rescue
      @err.puts "re5 is not an enzyme name"
      @out.puts opt_parser
      exit 1
    end
  end

# Main class for creating the index - accepts multiple input files. Either an SQLite database or
# a flat file index is created (extension .tdf) which is unique for the input file combination. 
# This file is used by the Search routine later.
#
  def run(ops=OpenStruct.new, input_filenames=[], cli=false)
    if ops.kind_of? OpenStruct
      @ops = ops.dup
    elsif ops.kind_of? Hash
      @ops = OpenStruct.new(ops)
    else
      raise ArgumentError
    end
  # Set defaults
    @ops.verbose    ||= false
    @ops.quiet      ||= false
    @ops.sqlite     ||= false
    @ops.filelookup ||= nil
    @ops.filefasta  ||= nil
    @ops.re5        ||= nil
    @ops.re3        ||= nil
    
    input_filenames = input_filenames.empty? ? [@ops.filefasta] : input_filenames
    @sizes = {}
    db_normalized_fasta = nil
    db_freq_lookup = nil
    f_normalized_fasta = nil
    f_freq_lookup = nil
    @re5_ds, @re3_ds = [@ops.re5, @ops.re3].map {|x| Bio::RestrictionEnzyme::DoubleStranded.new(x)}

    if @ops.sqlite
      db_normalized_fasta = SQLite3::Database.new( name_normalized_fasta(input_filenames) + '.db' )
      sql = <<-SQL
        drop table if exists db_normalized_fasta;
        create table db_normalized_fasta (
          id integer,
          definitions text,
          sequence text
        );
        create unique index db_normalized_fasta_idx on db_normalized_fasta(id);
      SQL
      db_normalized_fasta.execute_batch( sql )
      db_freq_lookup = SQLite3::Database.new( name_freq_lookup(input_filenames) + '.db' )
      sql = <<-SQL
        drop table if exists db_freq_lookup;
        create table db_freq_lookup (
        id integer,
        size integer,
        positions text
        );
        create unique index db_freq_lookup_idx on db_freq_lookup(id);
      SQL
      db_freq_lookup.execute_batch( sql )
    else
      f_normalized_fasta = File.new(name_normalized_fasta(input_filenames) + '.tdf', 'w')
      f_normalized_fasta.puts %w(id Definitions Sequence).join("\t")
      f_freq_lookup = File.new( name_freq_lookup(input_filenames) + '.tdf', 'w')
      f_freq_lookup.puts %w(id Size Positions).join("\t")
    end

    cli_p(p, template('out'))

  # unit test with aasi, aari, and ppii
    re5_regexp, re3_regexp = [@ops.re5, @ops.re3].map {|x| Bio::Sequence::NA.new( Bio::RestrictionEnzyme::DoubleStranded.new(x).aligned_strands.primary ).to_re }

    entries = {}
  # Account for exact duplicate sequences
    input_filenames.each do |input_filename|
      Bio::FlatFile.auto(input_filename).each_entry do |e|
        e.definition.tr!("\t",'')
        if entries[e.seq]
          entries[e.seq] << e.definition
        else
          entries[e.seq] = [e.definition]
        end
      end
    end
    
    normalized_fasta_id=0
    entries.each do |seq, @definitions|
      normalized_fasta_id+=1
      if @ops.sqlite
        db_normalized_fasta.execute( "insert into db_normalized_fasta values ( ?, ?, ? )", normalized_fasta_id, CSV.generate_line(@definitions), seq )
      else
        f_normalized_fasta.puts [normalized_fasta_id,CSV.generate_line(@definitions),seq].join("\t")
      end
      
      m1 = /(.*)(#{re5_regexp})/.match( seq.to_s.downcase )
      if m1
      # Find the fragment 'frag1' cut most right in seq with re5_regexp
        frag1 = $2 + m1.post_match          
  
        position = $1.size
  
        m2 = /(.*?)(#{re3_regexp})/.match( frag1 )
  
      # Now cut frag1 with re3_regexp resulting in frag2
        if m2
          @frag2 = $1 + $2
          p template('verbose_frag') if @ops.verbose
          @sizes[@frag2.size] ||= []
          @sizes[@frag2.size] << [position, normalized_fasta_id]
        end
      end
    end

    i=0
    @sizes.each do |size,info|
      i+=1
      if @ops.sqlite
        db_freq_lookup.execute( "insert into db_freq_lookup values ( ?, ?, ? )", i, size, info.map {|x| x.join(' ')}.join(', ') )
      else
        f_freq_lookup.puts [i,size,info.map {|x| x.join(' ')}.join(', ')].join("\t")
      end
    end
    
    if @ops.verbose
      @sizes.each { |@entry| cli_p(cli, template('end_verbose_entry')) }
    else
      cli_p(cli, template('end_simple'))
    end
    f_normalized_fasta.close
    f_freq_lookup.close
  end
  
#
#
  def template(x)
    ERB.new( IO.read(File.join([File.dirname(__FILE__)] + %w(index_command template) + ["#{x}.erb"])) ).result(binding)
  end
end  # class IndexCommand
end  # class App
end  # module Genfrag

# EOF
