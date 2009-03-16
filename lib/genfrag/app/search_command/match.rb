
module Genfrag
class App

class SearchCommand < Command

# Does the sequence match the adapter
#
  def matches_adapter(five_or_three, primary_frag, complement_frag, raw_frag, trim)
    adapter_specificity = nil
    adapter_sequence    = nil
    adapter_size        = nil
    trim_primary        = nil
    trim_complement     = nil

    if five_or_three == 5
      tail = right_tail_of(Bio::RestrictionEnzyme::DoubleStranded.new(@ops.re5).aligned_strands_with_cuts.primary)

      adapter_specificity = @adapters[:adapter5_specificity].upcase
      adapter_sequence    = @adapters[:adapter5_sequence].upcase if @adapters[:adapter5_sequence]
      adapter_size        = @adapters[:adapter5_size]
      trim_primary        = trim[:from_left_primary]
      trim_complement     = trim[:from_left_complement]

      # TEMP Check for match
      primary_frag =~ /(\.*)/
      dots_on_primary = $1.size
      lead_in = tail.size + dots_on_primary

      return false if primary_frag[ lead_in .. -1 ].tr('.', '') !~ /^#{adapter_specificity}/i

    elsif five_or_three == 3
      tail = left_tail_of(Bio::RestrictionEnzyme::DoubleStranded.new(@ops.re3).aligned_strands_with_cuts.primary)

      if @adapters[:adapter3_specificity][0].chr == '_'
        adapter_specificity = @adapters[:adapter3_specificity][1..-1].reverse.upcase
      else
        adapter_specificity = Bio::Sequence::NA.new(@adapters[:adapter3_specificity]).forward_complement.to_s.upcase
      end
      adapter_sequence    = Bio::Sequence::NA.new(@adapters[:adapter3_sequence]).forward_complement.to_s.upcase if @adapters[:adapter3_sequence]
      adapter_size        = @adapters[:adapter3_size]
      trim_primary        = trim[:from_right_primary]
      trim_complement     = trim[:from_right_complement]
      primary_frag.reverse!
      complement_frag.reverse!
      raw_frag.reverse!

      # TEMP Check for match
      primary_frag =~ /(\.*)/
      dots_on_primary = $1.size
      lead_in = tail.size + dots_on_primary
      return false if primary_frag[ lead_in .. -1 ].tr('.', '') !~ /^#{adapter_specificity}/i

    else
      raise "First argument to matches_adapter must be a '5' or a '3'. Received: #{five_or_three.inspect}"
    end

    if adapter_sequence
    # adapter-sequence supplied
      new_primary_frag, new_complement_frag = preserve_or_add(adapter_sequence.size, lead_in, adapter_sequence, primary_frag, complement_frag)
    elsif adapter_size
    # adapter-size supplied
      new_primary_frag, new_complement_frag = preserve_or_add(adapter_size, lead_in, adapter_sequence, primary_frag, complement_frag)
    else
    # only the specificity has been provided
      new_primary_frag = ('.' * dots_on_primary) + ('+' * tail.size) + primary_frag[ lead_in .. -1 ]
      new_complement_frag = complement_frag
    end

    if five_or_three == 3
      return [new_primary_frag.reverse, new_complement_frag.reverse]
    else
      return [new_primary_frag, new_complement_frag]
    end
  end


# Find the fragments that match the search parameters
#
  def find_matching_fragments(sizes, left, right)
    hits=[]
    s = (@adapters[:adapter5_size] or 0) + (@adapters[:adapter3_size] or 0)

    if [@ops.size].flatten == [0] or [@ops.size].flatten == [nil] or [@ops.size].flatten == ["0"]
      sizes.each do |raw_size, info|
        hits << info
      end

    else
      [@ops.size].flatten.each do |seek_size|
        seek_size = seek_size.to_i
        sizes.each do |raw_size, info|
          frag_size = raw_size - left[:trim_from_both] - right[:trim_from_both]
          if (frag_size >= seek_size - s) and (frag_size <= seek_size + s)
            hits << info
          end
        end
      end
    end

    return hits
  end

  def right_tail_of(s)
  # 'PpiI' => "n n n n n n^n n n n n n n g a a c n n n n n c t c n n n n n n n n n n n n n^n"
  # => 'n'
  # 'BstYI' => "r^g a t c y"
  # => 'gatcy'

    if s =~ /.*\^(.*)/
      return $1.tr(' ', '')
    else
      raise "Sequence #{s} has no cuts (defined by symbol '^')"
    end
  end

  def left_tail_of(s)
  # 'PpiI' => "n n n n n n^n n n n n n n g a a c n n n n n c t c n n n n n n n n n n n n n^n"
  # => 'nnnnnn'
  # 'BstYI' => "r^g a t c y"
  # => 'r'

    if s =~ /([^\^]*)\^/
      return $1.tr(' ', '')
    else
      raise "Sequence #{s} has no cuts (defined by symbol '^')"
    end

  end
  
  def preserve_or_add(size, lead_in, adapter_sequence, primary_frag, complement_frag)
    if adapter_sequence.nil? or adapter_sequence.empty?
      adapter_sequence = '?' * size
    end
    
    if lead_in >= size
    # need to preserve dots on primary string
      p = ('=' * (lead_in - size)) + adapter_sequence + primary_frag[ lead_in .. -1 ]
      c = complement_frag
    else
    # need to add dots to beginning of complement string
      p = adapter_sequence + primary_frag[ lead_in .. -1 ]
      c = ('=' * (size - lead_in) ) + complement_frag
    end
    [p,c]
  end

end  # class SearchCommand
end  # class App
end  # module Genfrag

# EOF
