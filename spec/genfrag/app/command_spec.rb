
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# --------------------------------------------------------------------------
describe Genfrag::App::Command do

  before :all do
    @out = StringIO.new
    @err = StringIO.new
    #@input_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'index_command')
    #@output_dir = File.join(GENFRAG_SPEC_TMP_DIR, %w[index_command])
    #FileUtils.mkdir(@output_dir) unless File.directory? @output_dir
  end
  
  before :each do
    @app = Genfrag::App::Command.new(@out, @err)
    @app.ops = OpenStruct.new({:quiet => true})
  end
  
  after :each do
    @out.clear
    @err.clear
  end
  
  describe 'output' do
    it 'should print in command-line mode and respect quiet' do
      cli = true
      @app.ops.quiet = false
      @app.cli_p(cli, 'hello')
      @out.readline.should match(%r/hello/)
      @out.clear
    
      @app.ops.quiet = true
      @app.cli_p(cli, 'hello')
      @out.readline.should be_nil
    end
  
    it "shouldn't print in library mode" do
      cli = false
      @app.ops.quiet = false
      @app.cli_p(cli, 'hello')
      @out.readline.should be_nil
      @out.clear
    
      @app.ops.quiet = true
      @app.cli_p(cli, 'hello')
      @out.readline.should be_nil
    end
  end
  
  describe 'filename function' do
    describe 'name_adapters' do
      it 'should format correctly' do
        @app.name_adapters('abc.db').should == 'abc'
        @app.name_adapters('abc.tdf').should == 'abc'
        @app.name_adapters('abc.x').should == 'abc.x'
        @app.name_adapters.should be_nil
      end
    end
    
    describe 'name_normalized_fasta' do
      it 'should format correctly using filefasta option' do
        @app.name_normalized_fasta(nil,'abc.db').should == 'abc'
        @app.name_normalized_fasta(nil,'abc.tdf').should == 'abc'
        @app.name_normalized_fasta(nil,'abc.x').should == 'abc.x'
      end
      
      it 'should format correctly using multiple input files' do
        @app.ops.filefasta = nil
        files = ['zxy', 'abc', 'def']
        @app.name_normalized_fasta(files).should == 'abc_def_zxy_normalized'

        files = ['zxy', 'foo/abc', 'foo/def']
        @app.name_normalized_fasta(files).should == 'fooxabc_fooxdef_zxy_normalized'
      end
      
      it 'should raise an error without any filename source' do
        @app.ops.filefasta = nil
        lambda {@app.name_normalized_fasta}.should raise_error
      end
    end
    
    describe 'name_freq_lookup' do
#      def name_freq_lookup(input_filenames=[],filefasta=nil,filelookup=nil,re5=nil,re3=nil)
      
      it 'should format correctly using filelookup option' do
        @app.name_freq_lookup(nil,nil,'abc.db').should == 'abc'
        @app.name_freq_lookup(nil,nil,'abc.tdf').should == 'abc'
        @app.name_freq_lookup(nil,nil,'abc.x').should == 'abc.x'
      end

      it 'should format correctly without filelookup option and with filefasta and enzymes' do
        re5 = 'MyRe5'
        re3 = 'MyRe3'
        @app.name_freq_lookup(nil,'abc.db',nil,re5,re3).should == 'abc_myre5_myre3_index'
        @app.name_freq_lookup(nil,'abc.tdf',nil,re5,re3).should == 'abc_myre5_myre3_index'
        @app.name_freq_lookup(nil,'abc.x',nil,re5,re3).should == 'abc.x_myre5_myre3_index'
      end
      
      it 'should format correctly using multiple input files and enzymes' do
        re5 = 'MyRe5'
        re3 = 'MyRe3'
        
        @app.ops.filelookup = nil
        files = ['zxy', 'abc', 'def']
        @app.name_freq_lookup(files,nil,nil,re5,re3).should == 'abc_def_zxy_myre5_myre3_index'

        files = ['zxy', 'foo/abc', 'foo/def']
        @app.name_freq_lookup(files,nil,nil,re5,re3).should == 'fooxabc_fooxdef_zxy_myre5_myre3_index'
      end
      
      it 'should raise an error using multiple input files without enzymes' do
        files = ['zxy', 'abc', 'def']
        lambda {@app.name_freq_lookup(files)}.should raise_error
      end
      
      it 'should raise an error without any filename source' do
        lambda {@app.name_freq_lookup}.should raise_error
      end
    end
  end
  
end

# EOF
