
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
    FileUtils.mkdir(@working_output_dir) unless File.directory? @working_output_dir
  end
  
  before :each do
    @app = Genfrag::App::SearchCommand.new(@out, @err)
  end
  
  after :each do
    @out.clear
    @err.clear
  end
  
  describe 'test matches_adapter' do
    it 'test' do
      pending 'tbd'
    end
  end
  
  describe 'test find_matching_fragments' do
    it 'test' do
      pending 'tbd'
    end
  end
  
  describe 'test right_tail_of' do
    it 'finds this right-most fragment preceding cut' do
    # PpiI
      p = 'n n n n n n^n n n n n n n g a a c n n n n n c t c n n n n n n n n n n n n n^n'
      @app.right_tail_of(p).should == 'n'
    end
    
    it 'finds this right-most fragment preceding cut' do
    # BstYI
      p = 'r^g a t c y'
      @app.right_tail_of(p).should == 'gatcy'
    end
    
    it "raises an error when there isn't a cut symbol" do
      p = 'r g a t c y'
      lambda {@app.right_tail_of(p)}.should raise_error
    end
  end
  
  describe 'test left_tail_of' do
    it 'finds this left-most fragment preceding cut' do
    # PpiI
      p = 'n n n n n n^n n n n n n n g a a c n n n n n c t c n n n n n n n n n n n n n^n'
      @app.left_tail_of(p).should == 'nnnnnn'
    end
    
    it 'finds this left-most fragment preceding cut' do
    # BstYI
      p = 'r^g a t c y'
      @app.left_tail_of(p).should == 'r'
    end
    
    it "raises an error when there isn't a cut symbol" do
      p = 'r g a t c y'
      lambda {@app.left_tail_of(p)}.should raise_error
    end
  end
end

# EOF
