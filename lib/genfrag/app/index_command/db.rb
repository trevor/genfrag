module Genfrag
class App

class IndexCommand < Command

  class DB    
    attr_accessor :ops      # an OpenStruct of the options
    attr_accessor :input_filenames
    attr_accessor :normalized_fasta
    attr_accessor :freq_lookup

    def initialize( ops, input_filenames )
      @normalized_fasta = nil
      @freq_lookup = nil
      @ops = ops
      @input_filenames = input_filenames
      
    end
    
    def sc
      @ops.sqlite ? 'sqlite' : 'csv'
    end
    
    
    def write_headers
      self.send("write_headers_#{sc}")
    end
    
    def write_headers_sqlite
      @normalized_fasta = SQLite3::Database.new( File.join(@ops.outdir, Genfrag.name_normalized_fasta(@input_filenames,@ops.filefasta) + '.db') )
      sql = <<-SQL
        drop table if exists db_normalized_fasta;
        create table db_normalized_fasta (
          id integer,
          definitions text,
          sequence text
        );
        create unique index db_normalized_fasta_idx on db_normalized_fasta(id);
      SQL
      @normalized_fasta.execute_batch( sql )
      @freq_lookup = SQLite3::Database.new( File.join(@ops.outdir, Genfrag.name_freq_lookup(@input_filenames,@ops.filefasta,@ops.filelookup,@ops.re5,@ops.re3) + '.db') )
      sql = <<-SQL
        drop table if exists db_freq_lookup;
        create table db_freq_lookup (
        id integer,
        size integer,
        positions text
        );
        create unique index db_freq_lookup_idx on db_freq_lookup(id);
      SQL
      @freq_lookup.execute_batch( sql )
    end
    
    def write_headers_csv
      @normalized_fasta = File.new(File.join(@ops.outdir,Genfrag.name_normalized_fasta(@input_filenames,@ops.filefasta) + '.tdf'), 'w')
      @normalized_fasta.puts %w(id Definitions Sequence).join("\t")
      @freq_lookup = File.new( File.join(@ops.outdir,Genfrag.name_freq_lookup(@input_filenames,@ops.filefasta,@ops.filelookup,@ops.re5,@ops.re3) + '.tdf'), 'w')
      @freq_lookup.puts %w(id Size Positions).join("\t")
    end
    
    
    def write_entry_to_fasta(normalized_fasta_id, seq, definitions)
      self.send("write_entry_to_fasta_#{sc}", normalized_fasta_id, seq, definitions)
    end

    def write_entry_to_fasta_sqlite(normalized_fasta_id, seq, definitions)
      @normalized_fasta.execute( "insert into db_normalized_fasta values ( ?, ?, ? )", normalized_fasta_id, definitions.join('!!-genfrag-!!'), seq )
    end
    
    def write_entry_to_fasta_csv(normalized_fasta_id, seq, definitions)
      @normalized_fasta.puts [normalized_fasta_id,definitions.join('!!-genfrag-!!'),seq].join("\t")
    end
    
    
    def write_entry_to_freq(i, size, str)
      self.send("write_entry_to_freq_#{sc}", i, size, str)
    end
      
    def write_entry_to_freq_sqlite(i, size, str)
      @freq_lookup.execute( "insert into db_freq_lookup values ( ?, ?, ? )", i, size, str )
    end
    
    def write_entry_to_freq_csv(i, size, str)
      @freq_lookup.puts [i,size,str].join("\t")
    end
    
    
    def close
      self.send("close_#{sc}")
    end
    
    def close_sqlite
    end
    
    def close_csv
      @normalized_fasta.close
      @freq_lookup.close
    end
  end

end  # class IndexCommand
end  # class App
end  # module Genfrag

# EOF
