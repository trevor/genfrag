
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))
    
# --------------------------------------------------------------------------
describe Genfrag::App::IndexCommand do
  
  before :all do
    @out = StringIO.new
    @err = StringIO.new
    @input_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'index_command', 'in')
    @frozen_output_dir = File.join(GENFRAG_SPEC_DATA_DIR, 'index_command', 'out')
    @working_output_dir = File.join(GENFRAG_SPEC_TMP_DIR, %w[index_command])
    FileUtils.mkdir_p(@working_output_dir) unless File.directory? @working_output_dir
  end
  
  before :each do
    @app = Genfrag::App::IndexCommand.new(@out, @err)
  end
  
  after :each do
    @out.clear
    @err.clear
  end
  
  describe 'when used from the command-line' do
    it 'should provide a help command and exit' do
      lambda {@app.cli_run %w[--help]}.should raise_error(SystemExit)
      @out.readline.should match(%r/Usage: genfrag index \[options\]/)
      @out.clear

      lambda {@app.cli_run %w[--help]}.should raise_error(SystemExit)
      @out.readline.should match(%r/Usage: genfrag index \[options\]/)
    end
    
    it 'should default to the help message and exit if no command is given' do
      lambda {@app.cli_run %w[]}.should raise_error(SystemExit)
      @out.readline.should match(%r/Usage: genfrag index \[options\]/)
    end
    
    it 'should stop on unrecognized options' do
      lambda {@app.cli_run %w[--bad]}.should raise_error(OptionParser::InvalidOption)
    end

    it 'should recognize a fasta file passed as an argument' do
      pending 'feature'
    end
        
    it 'should recognize multiple fasta files passed as arguments' do
      pending 'feature'
    end
    
    it 'should stop on missing --fasta' do
      lambda {@app.cli_run %w[-v --re5 BstYI --re3 BstYI]}.should raise_error(SystemExit)
    end
    
    it 'should stop on missing --re5' do
      lambda {@app.cli_run %w[-v --fasta a --re3 BstYI]}.should raise_error(SystemExit)
    end
    
    it 'should stop on missing --re3' do
      lambda {@app.cli_run %w[-v --fasta a --re5 BstYI]}.should raise_error(SystemExit)
    end
    
    it "should stop when --re3 is passed something it can't recognize" do
      lambda {@app.cli_run %w[-v --fasta a --re5 BstYI --re3 notanenzyme]}.should raise_error
    end
    
    it "should stop when --re5 is passed something it can't recognize" do
      lambda {@app.cli_run %w[-v --fasta a --re3 BstYI --re5 notanenzyme]}.should raise_error
    end
  end
  
  describe 'command-line option parser' do
    it 'should stop on unrecognized options' do
      lambda {@app.parse %w[--bad]}.should raise_error(OptionParser::InvalidOption)
    end
    
    it 'should recognize verbose' do
      @app.parse(%w[--verbose])
      @app.parse(%w[-v])
    end

    it 'should recognize tracktime' do
      @app.parse(%w[--tracktime])
      @app.parse(%w[-m])
    end
    
    it 'should recognize quiet' do
      @app.parse(%w[--quiet])
      @app.parse(%w[-q])
    end
    
    it 'should recognize re5 with string' do
      @app.parse(%w[--re5 a])
      @app.parse(%w[-5 a])
    end
    
    it 'should recognize re3 with string' do
      @app.parse(%w[--re3 a])
      @app.parse(%w[-3 a])
    end
    
    it 'should recognize sqlite' do
      @app.parse(%w[--sqlite])
      @app.parse(%w[-t])
    end
    
    it 'should recognize lookup with string' do
      @app.parse(%w[--lookup a])
      @app.parse(%w[-l a])
    end
    
    it 'should recognize fasta with string' do
      @app.parse(%w[--fasta a])
      @app.parse(%w[-f a])
    end
    
    it 'should recognize a combination of arguments' do
      @app.parse(%w[-v --re5 a --re3 a])
      @app.parse(%w[--verbose -5 a -3 a])
    end
  end
  
  describe 'with working example,' do
    
    after :all do
      #FileUtils.rm Dir.glob(File.join(@working_output_dir,'*'))
    end
    
    describe 'a.fasta' do
      
      before :each do
        @fasta = 'a.fasta'        
        @app = Genfrag::App::IndexCommand.new(@out, @err)
        @app.ops.indir = @input_dir
        @app.ops.outdir = @working_output_dir
        @app.ops.filefasta = @fasta
      end
      
    ############################################################
      describe 'using re5 = BstYI and re3 = MseI' do
        
        before :each do
          @app.ops.re5 = 'BstYI'
          @app.ops.re3 = 'MseI'
        end

        describe 'without sqlite' do
          it 'should execute' do
            @app.ops.filelookup = '1-a_lookup'
            @app.ops.sqlite = false
            @app.run
          end
          it 'lookup should be the same' do
            compare('1-a_lookup', '.tdf')
          end
          it 'fasta should be the same' do
            compare(@fasta, '.tdf')
          end
        end

        describe 'with sqlite' do
          it 'should execute' do
            @app.ops.filelookup = '2-a_lookup'
            @app.ops.sqlite = true
            @app.run
          end
          it 'lookup should be the same' do
            compare('2-a_lookup', '.db')
          end
          it 'fasta should be the same' do
            compare(@fasta, '.tdf')
          end
        end
      end

    ############################################################
      describe 'using re5 = MseI and re3 = BstYI' do
        
        before :each do
          @app.ops.re5 = 'MseI'
          @app.ops.re3 = 'BstYI'
        end

        describe 'without sqlite' do
          it 'should execute' do
            @app.ops.filelookup = '3-a_lookup'
            @app.ops.sqlite = false
            @app.run
          end
          it 'lookup should be the same' do
            compare('3-a_lookup', '.tdf')
          end
          it 'fasta should be the same' do
            compare(@fasta, '.tdf')
          end
        end

        describe 'with sqlite' do
          it 'should execute' do
            @app.ops.filelookup = '4-a_lookup'
            @app.ops.sqlite = true
            @app.run
          end
          it 'lookup should be the same' do
            compare('4-a_lookup', '.db')
          end
          it 'fasta should be the same' do
            compare(@fasta, '.tdf')
          end
        end
      end

    ############################################################
      describe 'using re5 = TaqI and re3 = AluI' do

        before :each do
          @app.ops.re5 = 'TaqI'
          @app.ops.re3 = 'AluI'
        end

        describe 'without sqlite' do
          it 'should execute' do
            @app.ops.filelookup = '5-a_lookup'
            @app.ops.sqlite = false
            @app.run
          end
          it 'lookup should be the same' do
            compare('5-a_lookup', '.tdf')
          end
          it 'fasta should be the same' do
            compare(@fasta, '.tdf')
          end
        end

        describe 'with sqlite' do
          it 'should execute' do
            @app.ops.filelookup = '6-a_lookup'
            @app.ops.sqlite = true
            @app.run
          end
          it 'lookup should be the same' do
            compare('6-a_lookup', '.db')
          end
          it 'fasta should be the same' do
            compare(@fasta, '.tdf')
          end
        end
      end
      
    end # a.fasta
    
  end # with working example
  
end

# EOF
