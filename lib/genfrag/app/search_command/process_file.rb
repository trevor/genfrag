
module Genfrag
class App

class SearchCommand < Command

  class ProcessFile
    class << self
    # Process the standardized Fasta file (tdf format)
    #
      def process_tdf_fasta_file(f_normalized_fasta)
        sequences = {}
        f_normalized_fasta[1..-1].each do |line|
          line = line.chomp.split("\t")
          id = line[0].to_i
          sequences[id] = {:definitions => line[1].split('!!-genfrag-!!'), :sequence => line[2]}
        end
        return sequences
      end

    # Process the standardized Fasta file (sqlite3 format)
      def process_db_fasta_file(db_normalized_fasta)
        sequences = {}
        db_normalized_fasta.execute( "select * from db_normalized_fasta" ) do |row|
          id = row[0].to_i
          sequences[id] = {:definitions => row[1].split('!!-genfrag-!!'), :sequence => row[2]}
        end
        return sequences
      end

    # Process the fragment frequency file (tdf format)
    #
      def process_tdf_freq_lookup(f_freq_lookup)
        sizes = {}
        f_freq_lookup[1..-1].each do |line|
          line = line.chomp.split("\t")
          id = line[0]
          size = line[1].to_i
          multiple = []
          line[2].split(', ').each do |a|
            pos = {}
            pos[:offset], pos[:fasta_id] = a.split(' ')
            pos[:offset] = pos[:offset].to_i
            pos[:raw_size] = size.to_i
            pos[:fasta_id] = pos[:fasta_id].to_i
            multiple << pos
          end
          sizes[size] = multiple
        end
        return sizes
      end

    # Process the fragment frequency file (sqlite3 format)
    #
      def process_db_freq_lookup(db_freq_lookup)
        sizes = {}
        db_freq_lookup.execute( "select * from db_freq_lookup" ) do |row|
          id = row[0]
          size = row[1].to_i
          multiple = []
          row[2].split(', ').each do |a|
            pos = {}
            pos[:offset], pos[:fasta_id] = a.split(' ')
            pos[:offset] = pos[:offset].to_i
            pos[:raw_size] = size.to_i
            pos[:fasta_id] = pos[:fasta_id].to_i
            multiple << pos
          end
          sizes[size] = multiple
        end
        return sizes
      end

    # Process the adapter file (tdf format)
    #
      def process_tdf_adapters(f_adapters, adapter5_name=nil, adapter3_name=nil)
        adapter5_sequence = nil
        adapter3_sequence = nil
        adapter5_specificity = nil
        adapter3_specificity = nil
        adapter5_needs_to_be_found = !adapter5_name.nil?
        adapter3_needs_to_be_found = !adapter3_name.nil?
        f_adapters[1..-1].each do |line|
          break if !(adapter5_needs_to_be_found or adapter3_needs_to_be_found)
          line = line.chomp.split("\t")
          next if line.empty?
          name = line[0]
          worksense = line[1][0].chr.to_i
          sequence = line[2].gsub(/\|N*$/i,'')
          specificity = line[3] # what it's supposed to match
          if (worksense != 3 and worksense != 5)
            raise "Unknown worksense value \"#{line[1]}\". First character of column must be a '5' or a '3'."
          end
          
          if adapter5_name and (worksense == 5) and ( name =~ /#{adapter5_name}/i )
            adapter5_sequence = sequence
            adapter5_specificity = specificity
            adapter5_needs_to_be_found = false
          elsif adapter3_name and (worksense == 3) and ( name =~ /#{adapter3_name}/i )
            adapter3_sequence = sequence
            adapter3_specificity = specificity
            adapter3_needs_to_be_found = false
          end
        end
        if ( adapter5_name and adapter5_needs_to_be_found )
          raise "named-adapter5 ('#{adapter5_name}') with the worksense '5' not found."
        elsif ( adapter3_name and adapter3_needs_to_be_found )
          raise "named-adapter3 ('#{adapter3_name}') with the worksense '3' not found."
        end
        return {
          :adapter5_sequence    => adapter5_sequence,
          :adapter5_specificity => adapter5_specificity,
          :adapter3_sequence    => adapter3_sequence,
          :adapter3_specificity => adapter3_specificity
        }
      end

    end
  end # class ProcessFile

end  # class SearchCommand
end  # class App
end  # module Genfrag

# EOF
