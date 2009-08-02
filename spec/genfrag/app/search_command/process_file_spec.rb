
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. .. spec_helper]))
    
# --------------------------------------------------------------------------
describe Genfrag::App::SearchCommand::ProcessFile do

  before :all do
    @out = StringIO.new
    @err = StringIO.new
    @input_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'index_command', 'out')
    @frozen_output_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'search_command', 'out')
    @working_output_dir = File.join(GENFRAG_SPEC_TMP_DIR, %w[search_command])
    FileUtils.mkdir_p(@working_output_dir) unless File.directory? @working_output_dir
  end
  
  before :each do
    @app = Genfrag::App::IndexCommand.new(@out, @err)
  end
  
  after :each do
    @out.clear
    @err.clear
  end
  
  describe 'test process_tdf_fasta_file' do
    
    describe 'with a.fasta.tdf' do
      before :all do
        d = IO.readlines File.join(@input_dir, 'a.fasta.tdf')
        @res = Genfrag::App::SearchCommand::ProcessFile.process_tdf_fasta_file d
      end
    
      it 'should have five elements' do
        @res.size.should == 5
      end
    
      it 'element 5 definitions' do
        @res[5][:definitions].should == ["At1g02580 - shortened for test - inserted cutpoint"]
      end
    
      it 'element 4 definitions' do
        @res[4][:definitions].sort.should == ["At1g02580 mRNA (2291 bp) UTR's and CDS", "At1g02580 mRNA (2291 bp) UTR's and CDS (duplicate)"].sort
      end
    
      it 'element 5 sequence' do
        @res[5][:sequence].should == 'gattgcaacaatcgctttggaggatgtaattgtgcaattggccaatgcacaaatcgacaatgtccttgttttgctgctaatcgtgaatgcgatccagatctttgtcggagttgtcctcttagctgtggagatggcactcttggtgagacaccagtgcaaatccaatgcaagaacatgcaataataaaaagattctcattggaaagtctgatgttcatggattcatggttttaattggggtgcatttacatgggactctcttaaaaagaatgagtatctcggagaatatactggagaactgatcactcatgatgaagctaatgagcgtgggagaatagaagatcggattggttcttcctacctctttaccttgaatgatca'
      end
    end
    
    describe 'with an array of data' do
      before :all do
        ary = [ %w(id Definitions Sequence),
                [1,'DescA!!-genfrag-!!DescB','seq-abc'],
                [2,'DescC','seq-def'],
                [3,'DescD,DescE,DescF','seq-ghi'] ]
        d = ary.map {|x| x.join("\t")}
        @res = Genfrag::App::SearchCommand::ProcessFile.process_tdf_fasta_file d
      end
    
      it 'should have three elements' do
        @res.size.should == 3
      end
    
      it 'element 1 definitions' do
        @res[1][:definitions].sort.should == ['DescA', 'DescB'].sort
      end
    
      it 'element 2 definitions' do
        @res[2][:definitions].sort.should == ['DescC'].sort
      end
    
      it 'element 3 sequence' do
        @res[3][:sequence].should == 'seq-ghi'
      end
    end
  end
  
  
  describe 'test process_db_fasta_file' do
  
    describe 'with a.fasta.db' do
      before :all do
        d = SQLite3::Database.new( File.join(@input_dir, 'a.fasta.db') )
        @res = Genfrag::App::SearchCommand::ProcessFile.process_db_fasta_file d
      end
    
      it 'should have five elements' do
        @res.size.should == 5
      end
    
      it 'element 5 definitions' do
        @res[5][:definitions].should == ["At1g02580 - shortened for test - inserted cutpoint"]
      end
    
      it 'element 4 definitions' do
        @res[4][:definitions].sort.should == ["At1g02580 mRNA (2291 bp) UTR's and CDS", "At1g02580 mRNA (2291 bp) UTR's and CDS (duplicate)"].sort
      end
    
      it 'element 5 sequence' do
        @res[5][:sequence].should == 'gattgcaacaatcgctttggaggatgtaattgtgcaattggccaatgcacaaatcgacaatgtccttgttttgctgctaatcgtgaatgcgatccagatctttgtcggagttgtcctcttagctgtggagatggcactcttggtgagacaccagtgcaaatccaatgcaagaacatgcaataataaaaagattctcattggaaagtctgatgttcatggattcatggttttaattggggtgcatttacatgggactctcttaaaaagaatgagtatctcggagaatatactggagaactgatcactcatgatgaagctaatgagcgtgggagaatagaagatcggattggttcttcctacctctttaccttgaatgatca'
      end
    end
    
  end
  
  
  describe 'test process_tdf_freq_lookup' do
    describe 'with 1-a_lookup.tdf' do
      before :all do
        d = IO.readlines File.join(@input_dir, '1-a_lookup.tdf')
        @res = Genfrag::App::SearchCommand::ProcessFile.process_tdf_freq_lookup d
      end
    
    # { 193=>[{:offset=>457, :raw_size=>193, :fasta_id=>1}], 
    #   138=>[{:offset=>95, :raw_size=>138, :fasta_id=>5}], 
    #   168=>[{:offset=>1539, :raw_size=>168, :fasta_id=>4}]}
    
      it 'should have three elements' do
        @res.size.should == 3        
      end
      
      it 'elements should have an array of hashes with three keys' do
        @res.each do |k,ary|
          ary.each do |hsh|
            hsh.keys.size.should == 3
          end
        end
      end
      
      it 'elements key should match :raw_size' do
        @res.each do |k,ary|
          ary.each do |hsh|
            k.should == hsh[:raw_size]
          end
        end
      end

    end
  end
  
  describe 'test process_db_freq_lookup' do
    describe 'with 2-a_lookup.db' do
      before :all do
        d = SQLite3::Database.new( File.join(@input_dir, '2-a_lookup.db') )
        @res = Genfrag::App::SearchCommand::ProcessFile.process_db_freq_lookup d
      end
    
    # { 193=>[{:offset=>457, :raw_size=>193, :fasta_id=>1}], 
    #   138=>[{:offset=>95, :raw_size=>138, :fasta_id=>5}], 
    #   168=>[{:offset=>1539, :raw_size=>168, :fasta_id=>4}]}
    
      it 'should have three elements' do
        @res.size.should == 3        
      end
      
      it 'elements should have an array of hashes with three keys' do
        @res.each do |k,ary|
          ary.each do |hsh|
            hsh.keys.size.should == 3
          end
        end
      end
      
      it 'elements key should match :raw_size' do
        @res.each do |k,ary|
          ary.each do |hsh|
            k.should == hsh[:raw_size]
          end
        end
      end

    end
  end
  
  describe 'test process_tdf_adapters' do
    it 'test' do
      pending 'tbd'
    end
  end
  
  
end

# EOF
