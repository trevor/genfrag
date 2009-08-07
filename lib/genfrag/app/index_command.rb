
module Genfrag
class App

class IndexCommand < Command

  attr_reader :sizes

# Run from command-line
#
  def cli_run( args )
    parse args

    @input_filenames = ARGV

    validate_options(options)

    if options[:tracktime]
      Genfrag.tracktime {
        run(options, @input_filenames, true)
      }
    else
      run(options, @input_filenames, true)
    end

  end

# Main class for creating the index - accepts multiple input files. Either an SQLite database or
# a flat file index is created (extension .tdf) which is unique for the input file combination. 
# This file is used by the Search routine later.
#
  def run(ops=@ops, input_filenames=[], cli=false)
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
    @ops.indir      ||= '.'
    @ops.outdir     ||= '.'

    @input_filenames = input_filenames.empty? ? [@ops.filefasta] : input_filenames
    @sizes = {}    
    db = IndexCommand::DB.new(@ops, @input_filenames)
    @re5_ds, @re3_ds = [@ops.re5, @ops.re3].map {|x| Bio::RestrictionEnzyme::DoubleStranded.new(x)}
    db.write_headers    

    if @ops.verbose
      cli_p(cli, <<-END
RE5: #{@ops.re5}
#{@re5_ds.aligned_strands_with_cuts.primary}
#{@re5_ds.aligned_strands_with_cuts.complement}

RE3: #{@ops.re3}
#{@re3_ds.aligned_strands_with_cuts.primary}
#{@re3_ds.aligned_strands_with_cuts.complement}
END
)
    end

  # unit test with aasi, aari, and ppii
    re5_regexp, re3_regexp = [@ops.re5, @ops.re3].map {|x| Bio::Sequence::NA.new( Bio::RestrictionEnzyme::DoubleStranded.new(x).aligned_strands.primary ).to_re }

    entries = {}
  # Account for exact duplicate sequences
    @input_filenames.each do |input_filename|
      Bio::FlatFile.auto(File.join(@ops.indir, input_filename)).each_entry do |e|
        e.definition.tr!("\t",'')
        s = e.seq.to_s.downcase
        if entries[s]
          entries[s] << e.definition
        else
          entries[s] = [e.definition]
        end
      end
    end
    
    a_re = /(.*)(#{re5_regexp})/
    b_re = /(.*?)(#{re3_regexp})/
    
    normalized_fasta_id=0
    entries.each do |seq, definitions|
      normalized_fasta_id+=1
      db.write_entry_to_fasta(normalized_fasta_id, seq, definitions)
      
    # NOTE the index command is slow because of the match functions, compare with ruby 1.9
      m1 = a_re.match(seq)
      if m1
      # Find the fragment 'frag1' cut most right in seq with re5_regexp
        frag1 = $2 + m1.post_match          
  
        position = $1.size
  
        m2 = b_re.match( frag1 )
  
      # Now cut frag1 with re3_regexp resulting in frag2
        if m2
          @frag2 = $1 + $2
          if @ops.verbose
            cli_p(cli, <<-END
---
#{definitions.join("\n")}
#{@frag2}
END
)
          end
          @sizes[@frag2.size] ||= []
          @sizes[@frag2.size] << [position, normalized_fasta_id]
        end
      end

    end

    i=0
    @sizes.each do |size,info|
      i+=1
      db.write_entry_to_freq(i, size, info.map {|x| x.join(' ')}.join(', ') )
    end
    
    if @ops.verbose
      @sizes.each { |entry| cli_p(cli, entry.inspect) }
    else
      cli_p(cli, "Cut sites found: #{@sizes.values.flatten.size / 2}")
    end
    
    db.close
  end


############
# Command-line
############


# Option parser for command-line
#
  def opt_parser
    std_opts = standard_options

    opts = OptionParser.new
    opts.banner = 'Usage: genfrag index [options]'

    opts.separator ''
    opts.separator "  Create a database of sequence fragments that match the last 5' fragment"
    opts.separator "  cut by two restricting enzymes RE3 and RE5."
    opts.separator "  The Fasta file defined by the --fasta option is taken as input."
    opts.separator "  Two files are created for the search function - a lookup file, and"
    opts.separator "  the contents of the Fasta file rewritten in a special format. You can"
    opts.separator "  specify the name of the lookup file with the --lookup option."

    opts.separator ''

    ary = [:verbose, :quiet, :tracktime, :indir, :outdir, :sqlite, :re5, :re3,
      :filelookup, :filefasta
    ]
    ary.each { |a| opts.on(*std_opts[a]) }

    opts.separator ''
    opts.separator '  Common Options:'
    opts.on( '-h', '--help', 'show this message' ) { @out.puts opts; exit 1 }
    opts.separator '  Examples:'
    opts.separator '    genfrag index -f example.fasta --re5 BstYI --re3 MseI'
    opts.separator '    genfrag index --out /tmp --in . -f example.fasta --re5 BstYI --re3 MseI'
    opts
  end

# Parse options passed from command-line
#
  def parse( args )
    opts = opt_parser

    if args.empty?
      @out.puts opts
      exit 1
    end

  # parse the command line arguments
    opts.parse! args
  end

# Validate options passed from the command-line
  def validate_options(o)
    if o[:filefasta] == nil
      clierr_p "missing option: must supply fasta filename"
      exit 1
    end

    if o[:re5] == nil
      clierr_p "missing option: re5"
      exit 1
    end

    if o[:re3] == nil
      clierr_p "missing option: re3"
      exit 1
    end

    begin
      Bio::RestrictionEnzyme::DoubleStranded.new(o[:re3])
    rescue
      clierr_p "re3 is not an enzyme name"
      exit 1
    end

    begin
      Bio::RestrictionEnzyme::DoubleStranded.new(o[:re5])
    rescue
      clierr_p "re5 is not an enzyme name"
      exit 1
    end
  end

end  # class IndexCommand
end  # class App
end  # module Genfrag

# EOF
