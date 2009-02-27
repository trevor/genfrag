
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper]))
    
# --------------------------------------------------------------------------
describe Genfrag::App::SearchCommand do

  before :all do
    @out = StringIO.new
    @err = StringIO.new
    @input_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'index_command', 'out')
    @frozen_output_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'search_command', 'out')
    @working_output_dir = File.join(GENFRAG_SPEC_TMP_DIR, %w[search_command])
    FileUtils.mkdir_p(@working_output_dir) unless File.directory? @working_output_dir
  end
  
  before :each do
    @app = Genfrag::App::SearchCommand.new(@out, @err)
  end
  
  after :each do
    @out.clear
    @err.clear
  end
  
  describe 'test calculate_trim_for_nucleotides' do
    it 'should work for BstYI' do
      re5_ds = Bio::RestrictionEnzyme::DoubleStranded.new('BstYI')
      re3_ds = Bio::RestrictionEnzyme::DoubleStranded.new('BstYI')
      
      @app.calculate_trim_for_nucleotides(re5_ds, re3_ds).should == {:from_left_primary=>1, :from_right_primary=>5, :from_right_complement=>1, :from_left_complement=>5}
    end
    
    it 'should work for PpiI' do
      re5_ds = Bio::RestrictionEnzyme::DoubleStranded.new('PpiI')
      re3_ds = Bio::RestrictionEnzyme::DoubleStranded.new('PpiI')
      
      @app.calculate_trim_for_nucleotides(re5_ds, re3_ds).should == {:from_right_primary=>33, :from_left_primary=>38, :from_right_complement=>38, :from_left_complement=>33}
    end
  end
  
  describe 'test calculate_left_and_right_trims' do
    it 'should work for BstYI / PpiI' do
      re5_ds = Bio::RestrictionEnzyme::DoubleStranded.new('BstYI')
      re3_ds = Bio::RestrictionEnzyme::DoubleStranded.new('PpiI')
      
      trim = @app.calculate_trim_for_nucleotides(re5_ds, re3_ds)
      @app.calculate_left_and_right_trims(trim).should == [{:trim_from_both=>1, :dot_out_from_primary=>false}, {:trim_from_both=>33, :dot_out_from_primary=>false}]
    end
    
    it 'should work for PpiI / BstYI' do
      re5_ds = Bio::RestrictionEnzyme::DoubleStranded.new('PpiI')
      re3_ds = Bio::RestrictionEnzyme::DoubleStranded.new('BstYI')
      
      trim = @app.calculate_trim_for_nucleotides(re5_ds, re3_ds)
      @app.calculate_left_and_right_trims(trim).should == [{:trim_from_both=>33, :dot_out_from_primary=>true}, {:trim_from_both=>1, :dot_out_from_primary=>true}]
    end
  end
  
  describe 'test trim_sequences' do
    it 'test' do
      p = "agatccttattgagaacggtgagtcttcttcatctttacctcttcctattgttgcgaatgcagctgcaccagtcggatttgatggtcctatgtttcaatatcataatcaaaatcagcaaaagccggttcaattccaatatcaggctctttatgatttttatgatcagattccaaagaaaattcatggttttaa"
      c = "tctaggaataactcttgccactcagaagaagtagaaatggagaaggataacaacgcttacgtcgacgtggtcagcctaaactaccaggatacaaagttatagtattagttttagtcgttttcggccaagttaaggttatagtccgagaaatactaaaaatactagtctaaggtttcttttaagtaccaaaatt"
      l = {:trim_from_both=>1, :dot_out_from_primary=>false}
      r = {:trim_from_both=>1, :dot_out_from_primary=>true}
      t = {:from_right_primary=>3, :from_left_primary=>1, :from_right_complement=>1, :from_left_complement=>5}
      @app.trim_sequences(p,c,l,r,t).should == 
        ["gatccttattgagaacggtgagtcttcttcatctttacctcttcctattgttgcgaatgcagctgcaccagtcggatttgatggtcctatgtttcaatatcataatcaaaatcagcaaaagccggttcaattccaatatcaggctctttatgatttttatgatcagattccaaagaaaattcatggttt..", 
          "....gaataactcttgccactcagaagaagtagaaatggagaaggataacaacgcttacgtcgacgtggtcagcctaaactaccaggatacaaagttatagtattagttttagtcgttttcggccaagttaaggttatagtccgagaaatactaaaaatactagtctaaggtttcttttaagtaccaaaat"]
    end
  end
  
end

# EOF
