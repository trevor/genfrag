
module Genfrag
class App

class SearchCommand < Command

  def cli_run( args )
    parse args

    @input_filenames = ARGV
    input_filenames = [@input_filenames].flatten
    processed_adapters=nil
    
    validate_options(options)
    
    if options[:sqlite]
      processed_fasta_file  = SearchCommand::ProcessFile.process_db_fasta_file( SQLite3::Database.new( name_normalized_fasta(input_filenames,options[:filefasta]) + '.db' ) )
      processed_freq_lookup = SearchCommand::ProcessFile.process_db_freq_lookup( SQLite3::Database.new( name_freq_lookup(input_filenames,options[:filefasta],options[:filelookup],options[:re5],options[:re3]) + '.db' ) )
    else
      processed_fasta_file  = SearchCommand::ProcessFile.process_tdf_fasta_file(  IO.readlines( name_normalized_fasta(input_filenames,options[:filefasta]) + '.tdf' ) )
      processed_freq_lookup = SearchCommand::ProcessFile.process_tdf_freq_lookup( IO.readlines( name_freq_lookup(input_filenames,options[:filefasta],options[:filelookup],options[:re5],options[:re3]) + '.tdf' ) )
    end
    
      if options[:fileadapters]
      processed_adapters = SearchCommand::ProcessFile.process_tdf_adapters( IO.readlines( name_adapters(options[:fileadapters]) + '.tdf' ), options[:named_adapter5], options[:named_adapter3] )
    end
    
    run(options, processed_fasta_file, processed_freq_lookup, processed_adapters, true)
  end

  def opt_parser
    std_opts = standard_options

    opts = OptionParser.new
    opts.banner = 'Usage: genfrag search [options]'

    opts.separator ''
    opts.separator "  Search a database of sequence fragments that match the last 5'"
    opts.separator "  fragment cut by two restricting enzymes RE3 and RE5, as created by the"
    opts.separator "  index function. Next, adapters are applied to search a subset of"
    opts.separator "  fragments, as is used in some protocols."

    opts.separator ''
    ary = [:verbose, :quiet, :tracktime, :indir, :outdir, :sqlite, :re5, :re3,
      :filelookup, :filefasta, :fileadapters, :adapter5_sequence, :adapter3_sequence,
      :adapter5_size, :adapter3_size, :named_adapter5, :named_adapter3,
      :adapter5, :adapter3
    ]
    ary.each { |a| opts.on(*std_opts[a]) }
        
    opts.separator ''
    opts.separator '  Common Options:'
    opts.on( '-h', '--help', 'show this message' ) { @out.puts opts; exit }
    
    opts.separator '  Examples:'
    opts.separator '    genfrag search -f example.fasta --re5 BstYI --re3 MseI --add 26 --adapter5 ct --adapter3 aa --size 190,215'
    opts.separator '    genfrag search -f example.fasta --re5 BstYI --re3 MseI --adapter5-size 11 --adapter5 tt --adapter3-size 15 --size 168'
    opts.separator '    genfrag search -f example.fasta --re5 BstYI --re3 MseI --adapter5-sequence GACTGCGTAGTGATC --adapter5 tt --adapter3-size 15 --size 168'
    opts.separator '    genfrag search -f example.fasta --re5 BstYI --re3 MseI --adapter5-size 11 --adapter5 ct --adapter3-size 15 --adapter3 aa --size 190,215'
    opts.separator '    genfrag search -f example.fasta --re5 BstYI --re3 MseI --add 26 --named-adapter5 BstYI-T4 --named-adapter3 MseI-21 --size 190,215'
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
    
  end
  
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
  
  def run(ops=OpenStruct.new, processed_fasta_file=nil, processed_freq_lookup=nil, processed_adapters=nil, cli=false)
    if ops.kind_of? OpenStruct
      @ops = ops.dup
    elsif ops.kind_of? Hash
      @ops = OpenStruct.new(ops)
    else
      raise ArgumentError
    end
    
    puts @ops.inspect
    
  # Set defaults
    @ops.verbose        ||= false
    @ops.quiet          ||= false
    @ops.sqlite         ||= false
    @ops.re5            ||= nil
    @ops.re3            ||= nil
    @ops.size           ||= [0]
    @ops.adapter5_size  ||= nil
    @ops.adapter3_size  ||= nil
    @ops.adapter5       ||= nil
    @ops.adapter3       ||= nil
    
    @sizes = processed_freq_lookup
    @sequences = processed_fasta_file
    @adapters = {}
    @re5_ds, @re3_ds = [@ops.re5, @ops.re3].map {|x| Bio::RestrictionEnzyme::DoubleStranded.new(x)}
    if @ops.verbose
      cli_p(cli, <<-END
    RE5: @ops.re5

    @re5_ds.aligned_strands_with_cuts.primary

    @re5_ds.aligned_strands_with_cuts.complement

    RE3: @ops.re3

    @re3_ds.aligned_strands_with_cuts.primary
    
    @re3_ds.aligned_strands_with_cuts.complement

  Adapter5: #{@ops.adapter5}
  Adapter3: #{@ops.adapter3}
END
)
    end

    if @ops.named_adapter5 and @ops.adapter5
      raise ArgumentError, "Cannot have both 'adapter5' and 'named_adapter5'"
    elsif @ops.named_adapter3 and @ops.adapter3
      raise ArgumentError, "Cannot have both 'adapter3' and 'named_adapter3'"
    end
    
    if !processed_adapters and (@ops.named_adapter5 or @ops.named_adapter3)
      raise ArgumentError, "Must specify --fileadapters when using a named_adapter"
    end
    
    if processed_adapters
      adapter_setup_1(processed_adapters)
    else
      adapter_setup_2
    end
  # ---- translated adapter 3' if given in reverse orientation - e.g. _tt is 
  #      translated to aa (reversed) and _tct returns the primary strand
  #      ending in specific 'tct'
    if @adapters[:adapter3_specificity] =~ /^_/
      seq3 = Bio::Sequence::NA.new(@adapters[:adapter3_specificity][1..-1]).downcase
      @adapters[:adapter3_specificity] = seq3.complement.to_s
    end
    
    if @ops.adapter5_size and @ops.adapter5_sequence and (@ops.adapter5_size != @adapters[:adapter5_size])
      raise ArgumentError, "--adapter5-sequence and --adapter5-size both supplied"
    end
    if @ops.adapter3_size and @ops.adapter3_sequence and (@ops.adapter3_size != @adapters[:adapter3_size])
      raise ArgumentError, "--adapter3-sequence and --adapter3-size both supplied"
    end

    @trim = calculate_trim_for_nucleotides(@re5_ds, @re3_ds)
    
  # ------
  # Start calculations
  #
    left_trim, right_trim = calculate_left_and_right_trims(@trim)
  
    matching_fragments = find_matching_fragments(@sizes, left_trim, right_trim)
    results = []
   
    matching_fragments.each do |hit|
      hit.each do |entry|
        seq = @sequences[entry[:fasta_id]][:sequence]
        raw_frag = seq[entry[:offset]..(entry[:offset]+entry[:raw_size]-1)]

        primary_frag, complement_frag = trim_sequences(raw_frag, Bio::Sequence::NA.new(raw_frag).forward_complement, left_trim, right_trim, @trim)
        
        p = primary_frag.dup
        c = complement_frag.dup
        
      # note the next two if-statements at this lever chain together with 'p' and 'c'
        if @adapters[:adapter5_specificity]
          p, c = matches_adapter(5, p, c, raw_frag, @trim)
          next if !p  # next if returned false -- no match
        end
        
        if @adapters[:adapter3_specificity]
          p, c = matches_adapter(3, p, c, raw_frag, @trim)
          next if !p  # next if returned false -- no match
        end
        
        primary_frag_with_adapters = p
        complement_frag_with_adapters = c
        
        results << {:raw_frag => raw_frag, :primary_frag => primary_frag, :primary_frag_with_adapters => primary_frag_with_adapters, :complement_frag => complement_frag, :complement_frag_with_adapters => complement_frag_with_adapters, :entry => entry, :seq => seq} # FIXME
      end
    end
  
    if results.size == 0
      cli_p(cli,"Nothing found") if @ops.verbose
    end

    results.each do |r|
      @r = r
      if @ops.verbose
        cli_p(cli, <<-END
---
#{@sequences[@r[:entry][:fasta_id]][:definitions].join("\n")}

Original sequence (#{@r[:seq].size}bp):

#{@r[:seq]}


Fragment (#{@r[:primary_frag].size}bp):
  5' - #{@r[:primary_frag]} - 3'
  3' - #{@r[:complement_frag]} - 5'

Fragment - after adapters (#{@r[:primary_frag_with_adapters].size}bp):
  5' - #{@r[:primary_frag_with_adapters]} - 3'
  3' - #{@r[:complement_frag_with_adapters]} - 5'
END
)
      else
        cli_p(cli, <<-END
---
@sequences[@r[:entry][:fasta_id]][:definitions].join("\n")

  5' - @r[:primary_frag_with_adapters] - 3'
  3' - @r[:complement_frag_with_adapters] - 5'
END
)
      end
    end

    return results
  end
  
  def adapter_setup_1(hsh)
    l = lambda do |i|
      if @ops.send("adapter#{i}")
        @adapters["adapter#{i}_specificity".to_sym] = @ops.send("adapter#{i}")
        if @ops.send("adapter#{i}_sequence")
          @adapters["adapter#{i}_sequence".to_sym] = @ops.send("adapter#{i}_sequence").gsub(/\|N*$/i,'')
          @adapters["adapter#{i}_size".to_sym] = @adapters["adapter#{i}_sequence".to_sym].size + @adapters["adapter#{i}_specificity".to_sym].size
        else
          @adapters["adapter#{i}_size".to_sym] = @ops.send("adapter#{i}_size")
        end
      elsif hsh["adapter#{i}_specificity".to_sym]
        @adapters["adapter#{i}_specificity".to_sym] = hsh["adapter#{i}_specificity".to_sym]
        @adapters["adapter#{i}_sequence".to_sym] = hsh["adapter#{i}_sequence".to_sym]
        @adapters["adapter#{i}_size".to_sym] = hsh["adapter#{i}_sequence".to_sym].size + hsh["adapter#{i}_specificity".to_sym].size
      end
    end
  # set adapter 5' and 3' respectively using above procs
    l.call(5)
    l.call(3)
  end
  
  def adapter_setup_2
    l = lambda do |i|
      @adapters["adapter#{i}_specificity".to_sym] = @ops.send("adapter#{i}")
      if @ops.send("adapter#{i}_sequence")
        @adapters["adapter#{i}_sequence".to_sym] = @ops.send("adapter#{i}_sequence").gsub(/\|N*$/i,'')
        @adapters["adapter#{i}_size".to_sym] = @adapters["adapter#{i}_sequence".to_sym].size + @adapters["adapter#{i}_specificity".to_sym].size
      else
        @adapters["adapter#{i}_size".to_sym] = @ops.send("adapter#{i}_size")
      end
    end
    l.call(5)
    l.call(3)
  end

end  # class SearchCommand
end  # class App
end  # module Genfrag

# EOF
