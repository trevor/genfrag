
module Genfrag
class App

class SearchCommand < Command

  # Keep track of extraneous nucleotides that should be removed from the final fragment
  #
  # Example BstYI used as RE5
  # BstYI -
  #   5' - r^g a t c y - 3'
  #   3' - y c t a g^r - 5'
  #
  #   re5_ds.cut_locations.primary              # => [0]
  #   re5_ds.cut_locations.complement           # => [4]
  #   re5_ds.aligned_strands.primary.size       # => 6
  #
  #   # number of nucleotides to trim from the left side on the primary strand
  #   re5_ds.cut_locations.primary.max + 1      # => 1
  #
  #   # number of nucleotides to trim from the left side on the complement strand
  #   re5_ds.cut_locations.complement.max + 1   # => 5
  #
  #
  # Example BstYI used as RE3
  # BstYI -
  #   5' - r^g a t c y - 3'
  #   3' - y c t a g^r - 5'
  #
  #   re3_ds.cut_locations.primary              # => [0]
  #   re3_ds.cut_locations.complement           # => [4]
  #   re3_ds.aligned_strands.primary.size       # => 6
  #
  #   # number of nucleotides to trim from the right side on the primary strand
  #   re3_ds.aligned_strands.primary.size - (re3_ds.cut_locations.primary.min + 1)      # => 5
  #
  #   # number of nucleotides to trim from the right side on the complement strand
  #   re3_ds.aligned_strands.primary.size - (re3_ds.cut_locations.complement.min + 1)   # => 1
  #
  #
  # Example PpiI used as RE5
  # PpiI -
  #   5' - n n n n n n^n n n n n n n g a a c n n n n n c t c n n n n n n n n n n n n n^n - 3'
  #   3' - n^n n n n n n n n n n n n c t t g n n n n n g a g n n n n n n n n^n n n n n n - 5'
  #
  #   re5_ds.cut_locations.primary              # => [5, 37]
  #   re5_ds.cut_locations.complement           # => [0, 32]
  #   re5_ds.aligned_strands.primary.size       # => 39
  #
  #   # number of nucleotides to trim from the left side on the primary strand
  #   re5_ds.cut_locations.primary.max + 1      # => 38
  #
  #   # number of nucleotides to trim from the left side on the complement strand
  #   re5_ds.cut_locations.complement.max + 1   # => 33
  #
  #
  # Example PpiI used as RE3
  # PpiI -
  #   5' - n n n n n n^n n n n n n n g a a c n n n n n c t c n n n n n n n n n n n n n^n - 3'
  #   3' - n^n n n n n n n n n n n n c t t g n n n n n g a g n n n n n n n n^n n n n n n - 5'
  #
  #   re3_ds.cut_locations.primary              # => [5, 37]
  #   re3_ds.cut_locations.complement           # => [0, 32]
  #   re3_ds.aligned_strands.primary.size       # => 39
  #
  #   # number of nucleotides to trim from the right side on the primary strand
  #   re3_ds.aligned_strands.primary.size - (re3_ds.cut_locations.primary.min + 1)      # => 33
  #
  #   # number of nucleotides to trim from the right side on the complement strand
  #   re3_ds.aligned_strands.primary.size - (re3_ds.cut_locations.complement.min + 1)   # => 38
  def calculate_trim_for_nucleotides(re5_ds, re3_ds)
    trim = {}
    trim[:from_left_primary]     = re5_ds.cut_locations.primary.max + 1
    trim[:from_left_complement]  = re5_ds.cut_locations.complement.max + 1
    trim[:from_right_primary]    = re3_ds.aligned_strands.primary.size - (re3_ds.cut_locations.primary.min + 1)
    trim[:from_right_complement] = re3_ds.aligned_strands.primary.size - (re3_ds.cut_locations.complement.min + 1)
    return trim
  end

  # Calculate left and right trims
  def calculate_left_and_right_trims(trim)
    left = {}
    # Should we "dot out" (nucleotide padding) from the primary strand? If no, then we assume the complement needs padding.
    left[:dot_out_from_primary] = (trim[:from_left_primary] > trim[:from_left_complement])
    # How much gets cut off on both primary and complement strands
    left[:trim_from_both] = [trim[:from_left_primary], trim[:from_left_complement]].min

    right = {}
    right[:dot_out_from_primary] = (trim[:from_right_primary] > trim[:from_right_complement])
    right[:trim_from_both] = [trim[:from_right_primary], trim[:from_right_complement]].min
    return [left,right]
  end

  # Do the trimming
  def trim_sequences(primary_frag, complement_frag, left, right, trim)  
    if left[:dot_out_from_primary]
      primary_frag = "." * trim[:from_left_primary] + primary_frag[trim[:from_left_primary]..-1]
    else
      complement_frag = "." * trim[:from_left_complement] + complement_frag[trim[:from_left_complement]..-1]
    end

    if right[:dot_out_from_primary]
      primary_frag = primary_frag[0..(-1 - trim[:from_right_primary])] + "." * trim[:from_right_primary]
    else
      complement_frag = complement_frag[0..(-1 - trim[:from_right_primary])] + "." * trim[:from_right_primary]
    end

    primary_frag = primary_frag[left[:trim_from_both]..(-1-right[:trim_from_both])]
    complement_frag = complement_frag[left[:trim_from_both]..(-1-right[:trim_from_both])]
  
    return [primary_frag, complement_frag]
  end

end  # class SearchCommand
end  # class App
end  # module Genfrag

# EOF
