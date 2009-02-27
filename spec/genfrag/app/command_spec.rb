
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
  
  
end

# EOF
