
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
  
  describe 'test calculate_trim_for_nucleotides' do
    it 'test' do
      pending 'tbd'
    end
  end
  
  describe 'test calculate_left_and_right_trims' do
    it 'test' do
      pending 'tbd'
    end
  end
  
  describe 'test trim_sequences' do
    it 'test' do
      pending 'tbd'
    end
  end
  
end

# EOF
